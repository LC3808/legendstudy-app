// Offline check of the exact production route/controller mounting used by D3.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'package:legendstudy_app/features/study/study_providers.dart';
import 'mock_scoring_test.dart' show FakeScoring, availability;
import 'study_core_test.dart' show TestClock, TestStore, TestRepo;

void main() {
  testWidgets('D3 runner real routes restore history and do not resubmit', (
    t,
  ) async {
    final clock = TestClock(),
        store = TestStore(),
        scoring = FakeScoring('A'),
        repository = TestRepo('A');
    StudyController? c;
    ProviderContainer? container;
    Future<void> mount() async {
      await t.pumpWidget(const SizedBox.shrink());
      container?.dispose();
      c = StudyController(
        clock,
        store,
        () => repository,
        ticking: false,
        scoringRepository: () => scoring,
      );
      c!.identity('A', resolved: true);
      await c!.settled;
      await t.pump();
      c!.selectMock(true);
      container = ProviderContainer(
        overrides: [
          studyControllerProvider.overrideWith((ref) {
            ref.keepAlive();
            return c!;
          }),
        ],
      );
      final router = container!.read(routerProvider);
      router.go('/study');
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: container!,
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: router,
          ),
        ),
      );
      await t.pumpAndSettle();
    }

    Future<void> tap(Finder f) async {
      await t.ensureVisible(f);
      await t.tap(f);
      await t.pumpAndSettle();
    }

    await mount();
    await c!.configureScoring(availability());
    c!.configureMock(const MockSetup('D3 route test', null, 600));
    await c!.startMock();
    await t.pumpAndSettle();
    await tap(find.text('답안 입력 · 0 / 3'));
    expect(find.textContaining('정답'), findsNothing);
    await tap(find.byKey(const ValueKey('answer-1-1')));
    clock.advance(2000);
    await tap(find.text('제출하고 채점하기'));
    await tap(find.text('제출하고 채점하기').last);
    await c!.settled;
    await t.pump();
    await t.pumpAndSettle();
    expect(find.text('2 / 6점'), findsOneWidget);
    expect(c!.draft, isNull);
    await tap(find.text('다시 학습으로'));
    final title = c!.attempts.single.title;
    expect(
      container!.read(routerProvider).routeInformationProvider.value.uri.path,
      '/study',
    );
    await mount();
    final count = scoring.calls.length;
    await tap(find.text('$title · 2 / 6점'));
    expect(find.text('2 / 6점'), findsOneWidget);
    await tap(find.text('홈으로'));
    expect(
      container!.read(routerProvider).routeInformationProvider.value.uri.path,
      '/home',
    );
    expect(c!.draft, isNull);
    expect(scoring.calls.length, count);
    await t.pumpWidget(const SizedBox.shrink());
    container!.dispose();
  });
}
