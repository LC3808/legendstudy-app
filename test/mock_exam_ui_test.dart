import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'package:legendstudy_app/features/study/focus/focus_service.dart';
import 'package:legendstudy_app/features/study/focus/study_focus_controller.dart';
import 'package:legendstudy_app/features/study/presentation/study_page.dart';
import 'package:legendstudy_app/features/study/study_providers.dart';

import 'study_core_test.dart' show TestClock, TestStore, TestRepo;
import 'study_focus_test.dart' show TestFocusService;
import 'mock_exam_test.dart' show TestAlerts;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final fail in [false, true]) {
    test(
      'mock Focus reuse failure=$fail, pause holds and expiry releases',
      () async {
        final clock = TestClock(), repo = TestRepo('A');
        final c = StudyController(
          clock,
          TestStore(),
          () => repo,
          ticking: false,
        );
        final service = TestFocusService()..activationFail = fail;
        final focus = StudyFocusController(service);
        addTearDown(c.dispose);
        addTearDown(focus.dispose);
        c.addListener(
          () => focus.observe(session: c.focusSession, ready: c.ready),
        );
        c.identity(null, resolved: true);
        await c.settled;
        c.configureMock(const MockSetup('시험', null, 60));
        await focus.start(
          startTimer: c.startMock,
          currentSession: () => c.focusSession,
          choose: (_) async => FocusChoice.once,
        );
        expect(c.mockPhase, MockPhase.running);
        expect(service.activations.length, 1);
        clock.advance(1000);
        await c.pause();
        await focus.settled;
        expect(service.reconciled.last, c.draft!.id);
        await c.resume();
        await focus.settled;
        expect(service.activations.length, 1);
        clock.advance(60000);
        await c.tick();
        await focus.settled;
        expect(service.reconciled.last, isNull);
        expect(c.records, isEmpty);
        await c.end();
        await focus.settled;
        expect(service.reconciled.last, isNull);
      },
    );
  }
  for (final scale in [1.0, 2.0]) {
    testWidgets('mock setup/dialog/expiry/result 360x640 ${scale}x', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final clock = TestClock(), repo = TestRepo('A');
      final c = StudyController(clock, TestStore(), () => repo, ticking: false);
      c.identity(null, resolved: true);
      await c.settled;
      final alerts = TestAlerts()..allowed = false;
      final focus = TestFocusService()
        ..capability = FocusCapability.unsupported;
      final container = ProviderContainer(
        overrides: [
          studyControllerProvider.overrideWith((ref) => c),
          focusServiceProvider.overrideWithValue(focus),
          mockNotificationProvider.overrideWithValue(alerts),
        ],
      );
      addTearDown(container.dispose);
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
      Future<void> press(String text) async {
        final f = find.text(text).last;
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await press('모의고사');
      await tester.enterText(find.byKey(const Key('mock-title')), '');
      await press('연습 시작');
      expect(find.text('시험명은 1~80자로 입력해 주세요.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('mock-title')), '가' * 80);
      final subject = find.byKey(const ValueKey('mock-subject-국어'));
      await tester.ensureVisible(subject);
      await tester.tap(subject);
      await tester.pumpAndSettle();
      await press('영어');
      expect(c.mockSetup!.subject, '영어');
      final dropdown = find.byKey(const Key('mock-duration'));
      await tester.ensureVisible(dropdown);
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      await press('사용자 지정');
      await tester.enterText(find.byKey(const Key('mock-minutes')), '721');
      await press('연습 시작');
      expect(find.text('시험 시간은 1~720분으로 입력해 주세요.'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('mock-minutes')), '1');
      await press('시험 종료 알림');
      expect(find.text('알림 없이도 시험을 시작할 수 있어요.'), findsOneWidget);
      await press('연습 시작');
      expect(c.mockPhase, MockPhase.running);
      expect(find.text('00:01:00'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await press('공부 타이머');
      expect(c.mockSelected, true);
      clock.advance(5000);
      await c.tick();
      await tester.pumpAndSettle();
      await press('제출');
      clock.advance(5000);
      await c.tick();
      await tester.pumpAndSettle();
      await press('돌아가기');
      expect(c.elapsedMs, 10000);
      expect(c.mockPhase, MockPhase.running);
      await press('일시정지');
      clock.advance(60000);
      await c.tick();
      await tester.pumpAndSettle();
      expect(c.remainingMs, 50000);
      await press('계속하기');
      await press('제출');
      clock.advance(60000);
      await c.tick();
      await tester.pumpAndSettle();
      await press('돌아가기');
      expect(c.mockPhase, MockPhase.timeUp);
      expect(c.records, isEmpty);
      await tester.ensureVisible(find.text('시험 종료'));
      expect(
        tester.getSize(find.widgetWithText(OutlinedButton, '시험 종료')).height,
        greaterThanOrEqualTo(48),
      );
      expect(tester.takeException(), isNull);
      await press('시험 종료');
      await press('종료 확인');
      expect(c.records.single.activeMs, 60000);
      expect(find.text('1분 0초 응시했어요.'), findsOneWidget);
      expect(find.text('이 기기에 저장됨'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
