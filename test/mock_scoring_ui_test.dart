import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_pages.dart';
import 'mock_scoring_test.dart' show FakeScoring, availability;
import 'study_core_test.dart' show TestClock, TestStore, TestRepo;

void main() {
  for (final scale in [1.0, 2.0]) {
    for (final count in [45, 100]) {
      testWidgets('answer marking/semantics/results 360x640 $scale x $count', (
        t,
      ) async {
        t.view.physicalSize = const Size(360, 640);
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        final clock = TestClock(),
            c = StudyController(
              clock,
              TestStore(),
              () => TestRepo('A'),
              ticking: false,
              scoringRepository: () => FakeScoring(null),
            );
        addTearDown(c.dispose);
        c.identity(null, resolved: true);
        await c.settled;
        await c.configureScoring(availability(count));
        c.configureMock(MockSetup(('아주 긴 시험 제목 ' * 5).trim(), null, 60));
        await c.startMock();
        await t.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: AnswerEntryPage(study: c),
          ),
        );
        expect(t.takeException(), isNull);
        final semantics = t.ensureSemantics();

        expect(find.bySemanticsLabel('1번, 1번 선택지'), findsOneWidget);
        if (count == 100 && scale == 2) {
          await t.tap(find.text('문항 바로가기'));
          await t.pumpAndSettle();
          await t.ensureVisible(find.text('100 ·'));
          await t.tap(find.text('100 ·'));
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
        }
        final choice = find.byKey(const ValueKey('answer-1-1'));
        await t.ensureVisible(choice);
        expect(t.getSize(choice).height, greaterThanOrEqualTo(48));
        expect(t.getSize(choice).width, greaterThanOrEqualTo(48));
        await t.tap(choice);
        await t.pumpAndSettle();
        expect(c.draft!.answers!.answered, 1);
        await t.tap(find.text('일시정지'));
        await t.pumpAndSettle();
        await t.tap(choice);
        await t.pumpAndSettle();
        expect(c.draft!.answers!.answered, 1);
        await t.tap(find.text('계속하기'));
        await t.pumpAndSettle();
        clock.advance(61000);
        await c.tick();
        await t.pumpAndSettle();
        expect(find.text('시험 시간이 끝났어요.'), findsOneWidget);
        expect(find.textContaining('정답 '), findsNothing);
        await t.tap(find.text('제출하고 채점하기'));
        await t.pumpAndSettle();
        expect(find.text('아직 답하지 않은 문제가 ${count - 1}개 있어요.'), findsOneWidget);
        await t.tap(find.text('제출하고 채점하기').last);
        await t.pumpAndSettle();
        expect(c.attempts.single.result, isNotNull);
        expect(find.text('2 / ${count * 2}점'), findsOneWidget);
        expect(t.takeException(), isNull);
        semantics.dispose();
      });
    }
  }
}
