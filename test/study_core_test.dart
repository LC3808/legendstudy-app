import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'package:legendstudy_app/features/study/data/study_local.dart';
import 'package:legendstudy_app/features/study/data/study_repository.dart';

class TestClock implements StudyClock {
  int utc = DateTime.utc(2026, 9, 14).millisecondsSinceEpoch, mono = 100000;
  String boot = 'one';
  void advance(int ms) {
    utc += ms;
    mono += ms;
  }

  @override
  Future<ClockReading> read() async => ClockReading(utc, mono, boot);
}

class TestStore implements StudyLocalStore {
  Map<String, dynamic> value = {'version': 1, 'owners': <String, dynamic>{}};
  bool fail = false;
  Completer<void>? holdWrite;
  @override
  Future<Map<String, dynamic>> read() async =>
      jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
  @override
  Future<void> write(Map<String, dynamic> v) async {
    if (holdWrite != null) await holdWrite!.future;
    if (fail) throw StateError('disk');
    value = jsonDecode(jsonEncode(v)) as Map<String, dynamic>;
  }
}

class TestRepo implements StudyRepository {
  TestRepo(this.owner);
  @override
  final String owner;
  bool fail = false, limit = false;
  Completer<void>? hold;
  final rows = <StudyRecord>[];
  int inserts = 0;
  @override
  Future<void> insertCompleted(StudyRecord r) async {
    inserts++;
    if (hold != null) await hold!.future;
    if (fail) throw StateError('offline');
    rows.add(r.acknowledged());
  }

  @override
  Future<List<StudyRecord>> fetchWindow(int now) async {
    if (limit) throw const StudyHistoryLimit();
    if (fail) throw StateError('offline');
    return rows;
  }

  @override
  Future<void> deleteOwn(String id) async =>
      rows.removeWhere((r) => r.id == id);
}

Future<void> flush(StudyController c) async {
  await c.settled;
  await Future<void>.delayed(Duration.zero);
  await c.settled;
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
  Future<void> mount([String? user]) async {
    c.identity(user, resolved: true);
    await flush(c);
    expect(c.ready, isTrue);
  }

  test(
    'guest idle start pause resume end, delayed/background ticker excludes pause',
    () async {
      await mount();
      expect(c.phase, TimerPhase.idle);
      await c.start();
      clock.advance(60000);
      await c.pause();
      clock.advance(60000);
      await c.resume();
      clock.advance(60000);
      await c.end();
      expect(c.phase, TimerPhase.idle);
      expect(c.records.single.activeMs, 120000);
      expect(c.records.single.segments.map((s) => s.toJson()), [
        [0, 60000],
        [120000, 180000],
      ]);
      expect(c.storageLabel, '이 기기에 저장됨');
      expect(repo.inserts, 0);
      expect(c.week.last, 120000);
    },
  );
  test(
    'running contributes to today; under one second never enters cloud',
    () async {
      await mount('A');
      await c.start();
      clock.advance(999);
      await c.tick();
      expect(c.week.last, 999);
      await c.end();
      await flush(c);
      expect(repo.inserts, 0);
      expect(c.records, isEmpty);
      expect(c.message, contains('너무 짧아요'));
    },
  );
  test(
    'guest completed persists and running restarts with continuous boot clock',
    () async {
      await mount();
      await c.start();
      clock.advance(2000);
      await c.end();
      await c.start();
      clock.advance(3000);
      c.dispose();
      c = StudyController(clock, store, () => repo, ticking: false);
      await mount();
      expect(c.phase, TimerPhase.running);
      expect(c.elapsedMs, 3000);
      expect(c.week.last, 5000);
      await c.pause();
      c.dispose();
      clock.advance(5000);
      c = StudyController(clock, store, () => repo, ticking: false);
      await mount();
      expect(c.phase, TimerPhase.paused);
      expect(c.elapsedMs, 3000);
    },
  );
  test('uncertain reboot recovery never adds unverified gap', () async {
    await mount();
    await c.start();
    clock.advance(30000);
    await c.tick();
    clock.advance(99999);
    clock.boot = 'two';
    c.dispose();
    c = StudyController(clock, store, () => repo, ticking: false);
    await mount();
    expect(c.recovery, isTrue);
    expect(c.elapsedMs, 30000);
    await c.recover(keep: true);
    expect(c.records.single.activeMs, 30000);
    expect(c.draft, isNull);
  });
  test('24h span auto-finalizes with clipped open interval', () async {
    await mount();
    await c.start();
    clock.advance(studyMaxSpan + 9000);
    await c.tick();
    expect(c.draft, isNull);
    expect(c.records.single.activeMs, studyMaxSpan);
    expect(c.records.single.endedMs - c.records.single.startedMs, studyMaxSpan);
  });
  test('paused span limit finalizes without counting pause', () async {
    await mount();
    await c.start();
    clock.advance(2000);
    await c.pause();
    clock.advance(studyMaxSpan);
    await c.tick();
    expect(c.records.single.activeMs, 2000);
    expect(c.draft, isNull);
  });
  test('segment guard prevents 257th resume', () async {
    await mount();
    await c.start();
    for (var i = 0; i < 256; i++) {
      clock.advance(1000);
      await c.pause();
      if (i < 255) {
        clock.advance(1000);
        await c.resume();
      }
    }
    expect(c.canResume, isFalse);
    await c.resume();
    expect(c.phase, TimerPhase.paused);
    await c.end();
    expect(c.records.single.segments.length, 256);
  });
  test(
    'disk failure does not acknowledge start or lose finishing draft',
    () async {
      await mount();
      store.fail = true;
      await c.start();
      expect(c.draft, isNull);
      store.fail = false;
      await c.start();
      clock.advance(2000);
      store.fail = true;
      await c.end();
      expect(c.draft, isNotNull);
      expect(c.records, isEmpty);
      store.fail = false;
      await c.end();
      expect(c.records.single.activeMs, 2000);
    },
  );
  test(
    'auth save and restart restore without updating unrelated profile',
    () async {
      await mount('A');
      await c.start();
      clock.advance(2000);
      await c.end();
      await flush(c);
      expect(repo.inserts, 1);
      expect(c.storageLabel, '저장됨');
      expect(c.records.single.synced, isTrue);
      c.dispose();
      c = StudyController(clock, store, () => repo, ticking: false);
      await mount('A');
      expect(c.week.last, 2000);
    },
  );
  test(
    'cloud failure retains local completion and retry synchronizes',
    () async {
      await mount('A');
      repo.fail = true;
      await c.start();
      clock.advance(2000);
      await c.end();
      await flush(c);
      expect(c.records.single.activeMs, 2000);
      expect(c.storageLabel, '동기화 대기');
      repo.fail = false;
      await c.sync();
      expect(c.storageLabel, '저장됨');
      expect(c.records.single.synced, isTrue);
    },
  );
  test(
    'guest login never uploads; account switch and logout isolate records',
    () async {
      await mount();
      await c.start();
      clock.advance(2000);
      await c.end();
      await mount('A');
      expect(repo.inserts, 0);
      expect(c.records, isEmpty);
      await c.start();
      clock.advance(3000);
      await c.end();
      await flush(c);
      repo = TestRepo('B');
      c.identity('B', resolved: true);
      expect(c.records, isEmpty);
      await flush(c);
      expect(c.week.last, 0);
      c.identity(null, resolved: true);
      await flush(c);
      expect(c.week.last, 2000);
    },
  );
  test('stale A upload cannot appear in B state', () async {
    await mount('A');
    repo.hold = Completer<void>();
    final a = repo;
    await c.start();
    clock.advance(2000);
    await c.end();
    await Future<void>.delayed(Duration.zero);
    repo = TestRepo('B');
    await mount('B');
    a.hold!.complete();
    await flush(c);
    expect(c.records, isEmpty);
    expect(c.week.last, 0);
    expect(repo.inserts, 0);
  });
  test(
    'history overflow never reports a partial aggregate as complete',
    () async {
      repo.limit = true;
      await mount('A');
      expect(c.historyLimit, isTrue);
      expect(c.summaryComplete, isFalse);
    },
  );
  test(
    'account change while durable start waits closes only original owner',
    () async {
      await mount();
      store.holdWrite = Completer<void>();
      final starting = c.start();
      await Future<void>.delayed(Duration.zero);
      clock.advance(2000);
      c.identity('A', resolved: true);
      store.holdWrite!.complete();
      await starting;
      await flush(c);
      expect(c.draft, isNull);
      expect(c.records, isEmpty);
      expect(repo.inserts, 0);
      c.identity(null, resolved: true);
      await flush(c);
      expect(c.draft, isNull);
      expect(c.records.single.activeMs, 2000);
    },
  );
  test(
    'unresolved auth cannot start but existing draft can pause and end',
    () async {
      await mount('A');
      c.identity(null, resolved: false);
      await c.start();
      expect(c.draft, isNull);
      c.identity('A', resolved: true);
      await c.start();
      clock.advance(2000);
      c.identity(null, resolved: false);
      await c.pause();
      expect(c.phase, TimerPhase.paused);
      await c.end();
      expect(c.storageLabel, '동기화 대기');
      expect(repo.inserts, 0);
      c.identity('A', resolved: true);
      await c.sync();
      expect(c.storageLabel, '저장됨');
    },
  );
  test('idle KST rollover clears today without dropping yesterday', () async {
    clock.utc = DateTime.utc(2026, 9, 13, 14, 59, 57).millisecondsSinceEpoch;
    await mount();
    await c.start();
    clock.advance(2000);
    await c.end();
    expect(c.week.last, 2000);
    clock.advance(2000);
    await c.tick();
    expect(c.week.last, 0);
    expect(c.week[5], 2000);
  });
  test('KST midnight union, empty seven days and mock included', () {
    final start = DateTime.utc(2026, 9, 13, 14, 50).millisecondsSinceEpoch;
    final first = StudyRecord(
      id: 'a',
      startedMs: start,
      endedMs: start + 1800000,
      segments: [const ActiveSegment(0, 1800000)],
    );
    final mock = StudyRecord(
      id: 'b',
      mode: 'mock_exam',
      title: '시험',
      plannedSeconds: 1200,
      startedMs: start + 900000,
      endedMs: start + 1200000,
      segments: [const ActiveSegment(0, 300000)],
    );
    final totals = studyWeek([first, mock], start + 1800000);
    expect(totals, [0, 0, 0, 0, 0, 600000, 1200000]);
    expect(studyWeek([], start), List.filled(7, 0));
    expect(studyWeek([mock], start + 1800000).last, 300000);
  });
  test('running midnight portion and paused gaps split per day', () async {
    clock.utc = DateTime.utc(2026, 9, 13, 14, 50).millisecondsSinceEpoch;
    await mount();
    await c.start();
    clock.advance(300000);
    await c.pause();
    clock.advance(600000);
    await c.resume();
    clock.advance(900000);
    await c.tick();
    expect(c.week.sublist(5), [300000, 900000]);
    expect(c.elapsedMs, 1200000);
  });
}
