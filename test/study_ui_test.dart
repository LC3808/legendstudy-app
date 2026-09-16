import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/study/study_providers.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/presentation/study_page.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';

import 'day5_shell_test.dart' show ShellContent;
import 'study_core_test.dart' show TestClock, TestStore, TestRepo;

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Home shared running total preserves compact action at $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final clock = TestClock(), store = TestStore(), repo = TestRepo('A');
        final study = StudyController(clock, store, () => repo, ticking: false);
        study.identity(null, resolved: true);
        await study.settled;
        await study.start();
        clock.advance(6120000);
        await study.tick();
        final container = ProviderContainer(
          overrides: [
            studyControllerProvider.overrideWith((ref) => study),
            contentRepositoryProvider.overrideWithValue(ShellContent()),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const LegendStudyApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('1시간 42분'), findsOneWidget);
        expect(find.text('오늘 공부'), findsOneWidget);
        expect(find.text('01:42:00'), findsNothing);
        await tester.ensureVisible(find.text('학습으로 이동'));
        expect(
          tester.getSize(find.widgetWithText(TextButton, '학습으로 이동')).height,
          greaterThanOrEqualTo(48),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('학습으로 이동'));
        await tester.pumpAndSettle();
        expect(find.text('01:42:00'), findsOneWidget);
        expect(find.text('오늘 1시간 42분 공부했어요.'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'Study controls, long timer, semantics and seven days 360x640 $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final clock = TestClock(), store = TestStore(), repo = TestRepo('A');
        final study = StudyController(clock, store, () => repo, ticking: false);
        study.identity(null, resolved: true);
        await study.settled;
        final container = ProviderContainer(
          overrides: [studyControllerProvider.overrideWith((ref) => study)],
        );
        addTearDown(container.dispose);
        final semantics = tester.ensureSemantics();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(body: StudyPage()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel('공부 타이머, 대기 상태, 0시간 0분 0초'),
          findsOneWidget,
        );
        expect(
          tester.getSize(find.widgetWithText(FilledButton, '공부 시작')).height,
          greaterThanOrEqualTo(48),
        );
        await tester.tap(find.text('공부 시작'));
        await tester.pumpAndSettle();
        clock.advance(23 * 3600000 + 59000);
        await study.tick();
        await tester.pumpAndSettle();
        expect(find.text('23:00:59'), findsOneWidget);
        expect(
          tester
              .widget<Text>(find.byKey(const Key('study-clock')))
              .style!
              .fontFeatures,
          isNotEmpty,
        );
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.text('일시정지'));
        await tester.tap(find.text('일시정지'));
        await tester.pumpAndSettle();
        expect(
          find.ancestor(
            of: find.text('계속하기'),
            matching: find.byWidgetPredicate((w) => w is FilledButton),
          ),
          findsOneWidget,
        );
        await tester.tap(find.text('계속하기'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('종료'));
        await tester.tap(find.text('종료'));
        await tester.pumpAndSettle();
        expect(find.text('이 기기에 저장됨'), findsOneWidget);
        expect(study.week.last, greaterThan(0));
        expect(tester.takeException(), isNull);
        semantics.dispose();
      },
    );
  }
}
