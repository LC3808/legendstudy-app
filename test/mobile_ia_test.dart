import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'package:legendstudy_app/features/study/study_providers.dart';
import 'package:legendstudy_app/features/study/presentation/study_page.dart';
import 'package:legendstudy_app/features/profile/presentation/profile_edit_page.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';

import 'study_core_test.dart' show TestClock, TestStore, TestRepo, flush;
import 'core_ux_test.dart' show ProfileFake;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('preference owner isolation, restart, failed write and per-attempt override', () async {
    final clock = TestClock(), store = TestStore();
    final a = TestRepo('A'), b = TestRepo('B');
    var repo = a;
    var c = StudyController(clock, store, () => repo, ticking: false);
    c.identity('A', resolved: true);
    await flush(c);
    expect(c.includeMockDefault, isTrue);
    await c.setIncludeMockDefault(false);
    c.configureMock(
      const MockSetup('국어', '국어', 4800, includeInStudyTotal: true),
    );
    await c.startMock();
    clock.advance(60000);
    await c.end();
    await flush(c);
    expect(c.includeMockDefault, isFalse);
    expect(c.records.single.includeInStudyTotal, isTrue);
    c.dispose();
    c = StudyController(clock, store, () => repo, ticking: false);
    c.identity('A', resolved: true);
    await flush(c);
    expect(c.includeMockDefault, isFalse);
    repo = b;
    c.identity('B', resolved: true);
    await flush(c);
    expect(c.includeMockDefault, isTrue);
    expect(c.records, isEmpty);
    store.fail = true;
    await c.setIncludeMockDefault(false);
    expect(c.includeMockDefault, isTrue);
    expect(c.preferenceError, contains('저장하지 못했어요'));
    c.dispose();
  });
  test(
    'excluded mock survives running restore, completion and cloud readback',
    () async {
      final clock = TestClock(), store = TestStore(), repo = TestRepo('A');
      var c = StudyController(clock, store, () => repo, ticking: false);
      c.identity('A', resolved: true);
      await flush(c);
      c.configureMock(
        const MockSetup('시험', '국어', 4800, includeInStudyTotal: false),
      );
      await c.startMock();
      clock.advance(60000);
      await c.tick();
      expect(c.week.last, 0);
      c.dispose();
      c = StudyController(clock, store, () => repo, ticking: false);
      c.identity('A', resolved: true);
      await flush(c);
      expect(c.draft!.mock!.includeInStudyTotal, isFalse);
      await c.end();
      await flush(c);
      expect(c.records.single.activeMs, 60000);
      expect(c.records.single.mode, 'mock_exam');
      expect(c.records.single.includeInStudyTotal, isFalse);
      expect(repo.rows.single.includeInStudyTotal, isFalse);
      expect(c.week.last, 0);
      c.dispose();
    },
  );
  test(
    'legacy defaults retain totals and include choices preserve KST union',
    () {
      final now = DateTime.utc(2026, 9, 23).millisecondsSinceEpoch;
      StudyRecord row(String id, int length, {bool include = true}) =>
          StudyRecord(
            id: id,
            startedMs: now,
            endedMs: now + length,
            segments: [ActiveSegment(0, length)],
            mode: 'mock_exam',
            title: '시험',
            plannedSeconds: 4800,
            includeInStudyTotal: include,
          );
      final excluded = row('b', 120000, include: false);
      expect(studyWeek([row('a', 60000), excluded], now).last, 60000);
      expect(
        StudyRecord.fromJson(excluded.toJson()).includeInStudyTotal,
        isFalse,
      );
      expect(
        StudyRecord.fromJson(row('a', 60000).toJson()).includeInStudyTotal,
        isTrue,
      );
      expect(
        MockSetup.fromJson({'title': '시험', 'subject': '국어', 'planned': 4800})
            .includeInStudyTotal,
        isTrue,
      );
    },
  );
  testWidgets(
    'Timer owns study summary; mock owns override without changing default',
    (t) async {
      final c = StudyController(
        TestClock(),
        TestStore(),
        () => TestRepo('A'),
        ticking: false,
      );
      c.identity(null, resolved: true);
      await c.settled;
      await t.pumpWidget(
        ProviderScope(
          overrides: [studyControllerProvider.overrideWith((ref) => c)],
          child: const MaterialApp(home: Scaffold(body: StudyPage())),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(find.text('최근 7일'), findsOneWidget);
      await t.tap(find.text('모의고사'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(find.text('최근 7일'), findsNothing);
      expect(find.text('오늘 공부 기록이 아직 없어요.'), findsNothing);
      final toggle = find.widgetWithText(SwitchListTile, '공부시간에 포함');
      await t.tap(toggle);
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(c.mockSetup!.includeInStudyTotal, isFalse);
      expect(c.includeMockDefault, isTrue);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'nickname editor uses only explicit profile, never auth email or metadata',
    (t) async {
      final repo = ProfileFake()
        ..value = const UserProfile(
          id: 'a',
          displayName: '내닉네임',
          gradeLevel: 2,
        );
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('a')),
            ),
            profileRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(home: Scaffold(body: ProfileEditPage())),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        '내닉네임',
      );
      await t.enterText(find.byType(TextField), '   ');
      await t.tap(find.text('저장'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(repo.writes, 0);
      expect(find.textContaining('1~80자'), findsOneWidget);
    },
  );
}
