import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'package:legendstudy_app/features/study/notifications/mock_notification.dart';
import 'study_core_test.dart' show TestClock, TestStore, TestRepo, flush;

class TestAlerts implements MockNotificationService {
  bool allowed = true, fail = false;
  Completer<void>? hold;
  final calls = <(String?, int)>[];
  @override
  Future<bool> request() async => allowed;
  @override
  Future<void> replace(String? session, int remainingMs) async {
    if (hold != null) await hold!.future;
    if (fail) throw StateError('unavailable');
    calls.add((session, remainingMs));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestClock clock;
  late TestStore store;
  late TestRepo repo;
  late StudyController c;
  setUp(() {
    clock = TestClock();
    store = TestStore();
    repo = TestRepo('A');
    c = StudyController(clock, store, () => repo, ticking: false);
  });
  tearDown(() => c.dispose());
  Future<void> mount([String? owner]) async {
    c.identity(owner, resolved: true);
    await flush(c);
  }

  Future<void> start({int seconds = 60, bool notify = false}) async {
    c.selectMock(true);
    c.configureMock(MockSetup('영어 모의고사', '영어', seconds, notify: notify));
    expect(c.mockPhase, MockPhase.ready);
    await c.startMock();
  }

  test(
    'setup Unicode limits, optional subject, preset and custom boundaries',
    () {
      expect(MockSetup.presets.values, [80, 100, 70, 30]);
      for (final sec in [60, 43200]) {
        MockSetup('😀' * 80, '영' * 40, sec).validate();
      }
      MockSetup('시험', null, 60).validate();
      for (final setup in [
        const MockSetup('', null, 60),
        MockSetup('영' * 81, null, 60),
        MockSetup('시험', '영' * 41, 60),
        const MockSetup('시험', null, 59),
        const MockSetup('시험', null, 43201),
      ]) {
        expect(setup.validate, throwsFormatException);
      }
    },
  );
  test('single slot blocks both mode directions', () async {
    await mount();
    await c.start();
    final id = c.draft!.id;
    expect(c.selectMock(true), false);
    await c.startMock();
    expect(c.draft!.id, id);
    clock.advance(1000);
    await c.end();
    await start();
    expect(c.selectMock(false), false);
    await c.start();
    expect(c.draft!.mock, isNotNull);
  });
  test(
    'delayed background tick clips plan, timeUp waits without cloud submit',
    () async {
      await mount('A');
      await start();
      final started = c.draft!.startedMs;
      clock.advance(75000);
      await c.tick();
      await flush(c);
      expect(c.mockPhase, MockPhase.timeUp);
      expect(c.elapsedMs, 60000);
      expect(c.remainingMs, 0);
      expect(repo.inserts, 0);
      expect(c.week.last, 60000);
      expect(c.focusSession, isNull);
      clock.advance(studyMaxSpan * 2);
      await c.tick();
      await c.resume();
      expect(c.elapsedMs, 60000);
      await c.end();
      await flush(c);
      expect(c.records.single.endedMs, started + 60000);
      expect(c.records.single.mode, 'mock_exam');
      expect(c.records.single.plannedSeconds, 60);
      expect(c.week.last, 0); // old KST date
      expect(repo.inserts, 1);
    },
  );
  test(
    'pause gaps, early confirmation records actual time and immutable allowlist',
    () async {
      await mount();
      await start(seconds: 4200);
      clock.advance(10000);
      await c.pause();
      expect(c.mockPhase, MockPhase.paused);
      clock.advance(90000);
      await c.tick();
      expect(c.remainingMs, 4190000);
      await c.resume();
      clock.advance(10000);
      await c.end();
      final r = c.records.single;
      expect(r.activeMs, 20000);
      expect(r.segments.map((s) => s.toJson()), [
        [0, 10000],
        [100000, 110000],
      ]);
      expect(r.payload().keys.toSet(), {
        'id',
        'mode',
        'title',
        'subject',
        'planned_duration_seconds',
        'started_at',
        'ended_at',
        'active_segments',
      });
      expect(c.storageLabel, '이 기기에 저장됨');
      expect(repo.inserts, 0);
    },
  );
  test(
    'running paused and frozen restore preserve metadata without automatic submit',
    () async {
      await mount();
      await start();
      clock.advance(5000);
      c.dispose();
      c = StudyController(clock, store, () => repo, ticking: false);
      await mount();
      expect(c.remainingMs, 55000);
      expect(c.mockSelected, true);
      expect(c.draft!.mock!.subject, '영어');
      await c.pause();
      clock.advance(100000);
      c.dispose();
      c = StudyController(clock, store, () => repo, ticking: false);
      await mount();
      expect(c.mockPhase, MockPhase.paused);
      expect(c.remainingMs, 55000);
      await c.resume();
      clock.advance(60000);
      await c.tick();
      final ended = c.draft!.checkpoint;
      clock.boot = 'reboot';
      c.dispose();
      c = StudyController(clock, store, () => repo, ticking: false);
      await mount();
      expect(c.recovery, false);
      expect(c.mockPhase, MockPhase.timeUp);
      expect(c.draft!.checkpoint, ended);
      expect(c.records, isEmpty);
    },
  );
  test('uncertain restore retains checkpoint awaiting confirmation', () async {
    await mount();
    await start();
    clock.advance(30000);
    await c.tick();
    clock.boot = 'reboot';
    await c.tick();
    expect(c.recovery, true);
    await c.recover(keep: true);
    expect(c.recovery, false);
    expect(c.draft!.frozenReason, 'recovery');
    expect(c.records, isEmpty);
    await c.end();
    expect(c.records.single.activeMs, 30000);
  });
  test(
    'auth pending retry; guest never uploaded; profile payload absent',
    () async {
      await mount();
      await start();
      clock.advance(2000);
      await c.end();
      await mount('A');
      expect(c.records, isEmpty);
      repo.fail = true;
      await start();
      clock.advance(3000);
      await c.end();
      await flush(c);
      expect(c.storageLabel, '동기화 대기');
      expect(c.records.single.mode, 'mock_exam');
      repo.fail = false;
      await c.sync();
      await flush(c);
      expect(c.storageLabel, '저장됨');
      expect(repo.rows.single.title, '영어 모의고사');
    },
  );
  test(
    'account switch freezes A without upload and removes prior UI',
    () async {
      await mount('A');
      await start();
      clock.advance(3000);
      final id = c.draft!.id;
      repo = TestRepo('B');
      await mount('B');
      expect(c.draft, isNull);
      expect(c.records, isEmpty);
      expect(c.lastMock, isNull);
      expect(c.mockSetup, isNull);
      expect(c.focusSession, isNull);
      final saved = StudyDraft.fromJson(
        Map<String, dynamic>.from(
          (store.value['owners'] as Map)['A']['draft'] as Map,
        ),
      );
      expect(saved.id, id);
      expect(saved.frozen, true);
      expect(saved.activeMs(saved.checkpoint), 3000);
      repo = TestRepo('A');
      await mount('A');
      expect(c.mockPhase, MockPhase.timeUp);
      expect(repo.inserts, 0);
      await c.end();
      await flush(c);
      expect(repo.rows.single.id, id);
    },
  );
  test('late A upload cannot repopulate B state', () async {
    await mount('A');
    await start();
    clock.advance(2000);
    repo.hold = Completer<void>();
    final a = repo;
    await c.end();
    await flush(c);
    repo = TestRepo('B');
    await mount('B');
    a.hold!.complete();
    await flush(c);
    expect(c.records, isEmpty);
    expect(c.lastMock, isNull);
    expect(c.draft, isNull);
  });
  test(
    'local completion failure freezes time and retry cannot extend it',
    () async {
      await mount();
      await start();
      clock.advance(2000);
      store.fail = true;
      await c.end();
      expect(c.draft!.frozen, true);
      expect(c.records, isEmpty);
      expect(c.savePhase, SavePhase.error);
      clock.advance(20000);
      store.fail = false;
      await c.end();
      expect(c.records.single.activeMs, 2000);
      await c.end();
      expect(c.records.length, 1);
    },
  );
  test('under 1 second and discard have no completed record', () async {
    await mount('A');
    await start();
    clock.advance(999);
    await c.end();
    await flush(c);
    expect(c.records, isEmpty);
    expect(repo.inserts, 0);
    await start();
    clock.advance(2000);
    await c.discardMock();
    expect(c.records, isEmpty);
    expect(c.week.last, 0);
  });
  test('24 hour wall guard while paused preserves actual duration', () async {
    await mount();
    await start(seconds: 43200);
    clock.advance(1000);
    await c.pause();
    clock.advance(studyMaxSpan);
    await c.tick();
    expect(c.draft!.frozenReason, 'wallLimit');
    expect(c.elapsedMs, 1000);
    await c.end();
    expect(c.records.single.endedMs - c.records.single.startedMs, studyMaxSpan);
  });
  test('256 intervals prevents another resume', () async {
    await mount();
    await start(seconds: 43200);
    for (var n = 0; n < 256; n++) {
      clock.advance(1000);
      await c.pause();
      if (n < 255) await c.resume();
    }
    expect(c.canResume, false);
    await c.resume();
    expect(c.mockPhase, MockPhase.paused);
    await c.end();
    expect(c.records.single.segments.length, 256);
  });
  test(
    'v1 migration retains all owners and outbox UUIDs; unknown version rejected',
    () async {
      await mount();
      await c.start();
      clock.advance(2000);
      await c.end();
      final old = jsonDecode(jsonEncode(store.value)) as Map<String, dynamic>;
      old['version'] = 1;
      store.value = old;
      c.dispose();
      c = StudyController(clock, store, () => repo, ticking: false);
      await mount();
      expect(store.value['version'], 3);
      expect(jsonEncode(store.value['owners']), jsonEncode(old['owners']));
      c.dispose();
      store.value = {'version': 99, 'owners': <String, dynamic>{}};
      c = StudyController(clock, store, () => repo, ticking: false);
      await mount();
      expect(c.ready, false);
      expect(store.value['version'], 99);
    },
  );
  test(
    'KST midnight aggregate includes mock plus study and unions overlap',
    () {
      final start = DateTime.utc(2026, 9, 14, 14, 59).millisecondsSinceEpoch;
      final mock = StudyRecord(
        id: 'mock',
        mode: 'mock_exam',
        title: '시험',
        plannedSeconds: 180,
        startedMs: start,
        endedMs: start + 120000,
        segments: [const ActiveSegment(0, 120000)],
      );
      final general = StudyRecord(
        id: 'study',
        startedMs: start,
        endedMs: start + 60000,
        segments: [const ActiveSegment(0, 60000)],
      );
      final totals = studyWeek([mock, general], start + 120000);
      expect(totals[5], 60000);
      expect(totals[6], 60000);
    },
  );
  test(
    'notification permission denied is optional; schedules pause/resume/timeUp cancel',
    () async {
      await mount();
      final service = TestAlerts();
      service.allowed = false;
      expect(await service.request(), false);
      final alerts = MockNotificationController(c, service);
      addTearDown(alerts.dispose);
      await start(notify: true);
      await alerts.settled;
      expect(service.calls.last.$1, c.draft!.id);
      clock.advance(1000);
      await c.pause();
      await alerts.settled;
      expect(service.calls.last.$1, isNull);
      await c.resume();
      await alerts.settled;
      expect(service.calls.last.$1, c.draft!.id);
      clock.advance(60000);
      await c.tick();
      await alerts.settled;
      expect(service.calls.last.$1, isNull);
      expect(c.records, isEmpty);
    },
  );
  test(
    'late schedule serializes before cancel and exceptions never block mock',
    () async {
      await mount();
      final service = TestAlerts();
      final alerts = MockNotificationController(c, service);
      addTearDown(alerts.dispose);
      await alerts.settled;
      service.hold = Completer<void>();
      await start(notify: true);
      await Future<void>.delayed(Duration.zero);
      clock.advance(2000);
      await c.end();
      service.hold!.complete();
      await alerts.settled;
      expect(service.calls.last.$1, isNull);
      service.fail = true;
      await start(notify: true);
      await alerts.settled;
      expect(c.mockPhase, MockPhase.running);
    },
  );
}
