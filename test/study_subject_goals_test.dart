import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'package:legendstudy_app/features/study/trends/study_trends.dart';
import 'package:legendstudy_app/features/study/trends/study_goals.dart';

import 'study_core_test.dart' show TestClock, TestStore, TestRepo, flush;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'subject survives checkpoint, restart, pause and immutable completion',
    () async {
      final clock = TestClock(), store = TestStore(), repo = TestRepo('a');
      var c = StudyController(clock, store, () => repo, ticking: false);
      c.identity('a', resolved: true);
      await flush(c);
      c.selectStudySubject('수학');
      await c.start();
      clock.advance(60000);
      await c.pause();
      c.selectStudySubject('영어');
      expect(c.draft!.studySubject, '수학');
      c.dispose();
      c = StudyController(clock, store, () => repo, ticking: false);
      c.identity('a', resolved: true);
      await flush(c);
      expect(c.draft!.studySubject, '수학');
      clock.advance(60000);
      await c.resume();
      clock.advance(60000);
      await c.end();
      await flush(c);
      expect(c.records.single.subject, '수학');
      expect(c.records.single.activeMs, 120000);
      expect(repo.rows.single.subject, '수학');
      c.dispose();
    },
  );
  test(
    'legacy draft stays unclassified; freeze preserves selected subject',
    () {
      final d = StudyDraft.start(
        ClockReading(0, 0, 'boot'),
        studySubject: '국어',
      );
      expect(d.freeze(2000, 'clock').finish(2000)!.subject, '국어');
      final old = d.toJson()..remove('study_subject');
      expect(StudyDraft.fromJson(old).finish(2000)!.subject, isNull);
    },
  );
  test('KST boundary subject partition equals canonical union including overlapping devices', () {
    final midnight = dayStartMs(DateTime.utc(2026, 11, 13));
    StudyRecord row(String id, String? subject, int a, int b) => StudyRecord(
      id: id,
      startedMs: midnight + a,
      endedMs: midnight + b,
      mode: 'study',
      subject: subject,
      segments: [ActiveSegment(0, b - a)],
    );
    final records = [
      row('a', '수학', -60000, 60000),
      row('b', '영어', 0, 120000),
      row('c', null, 120000, 180000),
      row('d', '영어', 60000, 120000),
    ];
    final totals = studySubjectTotals(records, midnight, midnight + 86400000);
    expect(totals, {'과목 겹침': 60000, '영어': 60000, '미분류': 60000});
    expect(
      totals.values.reduce((a, b) => a + b),
      studyBuckets(records, [(midnight, midnight + 86400000)]).single,
    );
    expect(studySubjectTotals(records, midnight - 86400000, midnight), {
      '수학': 60000,
    });
    final d = StudyDraft.start(
      ClockReading(midnight + 180000, 0, 'boot'),
      studySubject: '탐구',
    );
    final withDraft = studySubjectTotals(
      records,
      midnight,
      midnight + 86400000,
      draft: d,
      offset: 60000,
    );
    expect(
      withDraft.values.reduce((a, b) => a + b),
      studyBuckets(
        records,
        [(midnight, midnight + 86400000)],
        draft: d,
        offset: 60000,
      ).single,
    );
  });
  test(
    'goals are durable revisions, isolated by owner and atomic on failure',
    () async {
      final clock = TestClock(), store = TestStore();
      var repo = TestRepo('a');
      var c = StudyController(clock, store, () => repo, ticking: false);
      c.identity('a', resolved: true);
      await flush(c);
      await c.setStudyGoals(60, 300);
      await c.setStudyGoals(90, 400);
      expect((store.value['owners']['a']['goal_revisions'] as List).length, 2);
      store.fail = true;
      await expectLater(c.setStudyGoals(1, 1), throwsStateError);
      expect(c.studyGoal!['daily_minutes'], 90);
      store.fail = false;
      c.dispose();
      c = StudyController(clock, store, () => repo, ticking: false);
      c.identity('a', resolved: true);
      await flush(c);
      expect(c.studyGoal!['weekly_minutes'], 400);
      repo = TestRepo('b');
      c.identity('b', resolved: true);
      await flush(c);
      expect(c.studyGoal, isNull);
      await c.setStudyGoals(20, 100);
      repo = TestRepo('a');
      c.identity('a', resolved: true);
      await flush(c);
      expect(c.studyGoal!['daily_minutes'], 90);
      await expectLater(c.setStudyGoals(1441, 20), throwsFormatException);
      c.dispose();
    },
  );
  testWidgets('goal form validates and renders progress', (tester) async {
    final c = StudyController(
      TestClock(),
      TestStore(),
      () => TestRepo('a'),
      ticking: false,
    );
    c.identity(null, resolved: true);
    await c.settled;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: c,
            builder: (_, _) =>
                StudyGoals(study: c, today: 1800000, week: 3600000),
          ),
        ),
      ),
    );
    await tester.tap(find.text('목표 설정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '1500');
    await tester.tap(find.text('저장'));
    await tester.pump();
    expect(find.text('0~1440 사이 정수를 입력해 주세요.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '60');
    await tester.enterText(find.byType(TextFormField).last, '120');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(find.textContaining('50%'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
