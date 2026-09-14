import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/study/focus/focus_service.dart';
import 'package:legendstudy_app/features/study/focus/study_focus_controller.dart';
import 'package:legendstudy_app/features/study/focus/focus_ui.dart';

class TestFocusService implements FocusService {
  FocusCapability capability = FocusCapability.ownedRule;
  FocusPreference preference = FocusPreference.ask;
  bool permission = true,
      fail = false,
      requestFail = false,
      activationFail = false;
  FocusResult result = FocusResult.requested;
  final writes = <FocusPreference>[],
      activations = <String>[],
      reconciled = <String?>[];
  int requests = 0, statusCalls = 0;
  Completer<FocusStatus>? heldStatus;
  Completer<FocusResult>? heldActivation;
  @override
  Future<FocusStatus> status() async {
    if (fail) throw StateError('native');
    if (++statusCalls > 1 && heldStatus != null) return heldStatus!.future;
    return FocusStatus(capability, permission);
  }

  @override
  Future<FocusPreference> readPreference() async => preference;
  @override
  Future<void> writePreference(FocusPreference v) async {
    writes.add(v);
    preference = v;
  }

  @override
  Future<void> requestPermission() async {
    requests++;
    if (requestFail) throw StateError('settings');
  }

  @override
  Future<FocusResult> activateForStudy(String s) async {
    activations.add(s);
    if (activationFail) throw StateError('native error');
    return heldActivation == null ? result : await heldActivation!.future;
  }

  @override
  Future<void> reconcile(String? s) async {
    reconciled.add(s);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestFocusService service;
  late StudyFocusController focus;
  String? session;
  int starts = 0, choices = 0;
  setUp(() {
    service = TestFocusService();
    focus = StudyFocusController(service);
    session = null;
    starts = 0;
    choices = 0;
  });
  tearDown(() => focus.dispose());
  Future<void> start([FocusChoice choice = FocusChoice.once]) => focus.start(
    startTimer: () async {
      starts++;
      session = 'session-$starts';
      focus.observe(session: session, ready: true);
    },
    currentSession: () => session,
    choose: (_) async {
      choices++;
      return choice;
    },
  );
  test('ask once starts and activates without persisting preference', () async {
    await start();
    expect(starts, 1);
    expect(choices, 1);
    expect(service.writes, isEmpty);
    expect(service.activations, ['session-1']);
  });
  test('always persists device setting, later starts do not prompt', () async {
    await start(FocusChoice.always);
    await start();
    expect(choices, 1);
    expect(service.writes, [FocusPreference.always]);
    expect(starts, 2);
  });
  test('disabled starts without requesting permission or activation', () async {
    await start(FocusChoice.disabled);
    await start();
    expect(starts, 2);
    expect(choices, 1);
    expect(service.requests, 0);
    expect(service.activations, isEmpty);
  });
  test('activation exception and revocation keep timer running', () async {
    service.activationFail = true;
    await start();
    expect(starts, 1);
    expect(focus.message, contains('타이머는 정상적으로'));
    service.activationFail = false;
    service.result = FocusResult.denied;
    await start();
    expect(starts, 2);
    expect(focus.message, contains('권한이 필요'));
  });
  test(
    'always preference does not repeatedly force settings after denial',
    () async {
      service.permission = false;
      await start(FocusChoice.always);
      focus.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await focus.settled;
      await start();
      expect(starts, 2);
      expect(service.requests, 1);
      expect(service.activations, isEmpty);
      await focus.openPermissionSettings();
      expect(service.requests, 2);
    },
  );
  for (final capability in [
    FocusCapability.guideOnly,
    FocusCapability.unsupported,
  ]) {
    test(
      '$capability has no automatic activation or false active state',
      () async {
        service.capability = capability;
        await start();
        expect(starts, 1);
        expect(service.activations, isEmpty);
        expect(service.requests, 0);
        expect(focus.message, isNull);
      },
    );
  }
  test('native status exception still starts timer', () async {
    service.fail = true;
    await start();
    expect(starts, 1);
    expect(service.activations, isEmpty);
  });
  test('native activation failure cannot undo timer', () async {
    service.result = FocusResult.failed;
    await start();
    expect(starts, 1);
    expect(focus.message, contains('타이머는 정상적으로'));
  });
  test(
    'permission denied starts immediately without waiting for OS return',
    () async {
      service.permission = false;
      await start();
      expect(starts, 1);
      expect(service.requests, 1);
      expect(service.activations, isEmpty);
      focus.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await focus.settled;
      expect(service.requests, 1);
      expect(service.activations, isEmpty);
    },
  );
  test(
    'permission granted on return activates exactly once for current session',
    () async {
      service.permission = false;
      await start();
      service.permission = true;
      focus.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await focus.settled;
      focus.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await focus.settled;
      expect(service.activations, ['session-1']);
      expect(service.requests, 1);
    },
  );
  test('missing OS settings activity still leaves a started timer', () async {
    service.permission = false;
    service.requestFail = true;
    await start();
    expect(starts, 1);
    expect(focus.message, contains('타이머는 정상적으로'));
  });
  test(
    'pause resume background keep same lease; end clears owned state',
    () async {
      await start();
      final calls = service.reconciled.length;
      focus.observe(session: session, ready: true);
      focus.observe(session: session, ready: true);
      focus.didChangeAppLifecycleState(AppLifecycleState.paused);
      await focus.settled;
      expect(service.reconciled.length, calls);
      expect(service.activations.length, 1);
      session = null;
      focus.observe(session: null, ready: true);
      await focus.settled;
      expect(service.reconciled.last, isNull);
    },
  );
  test(
    'account switch clears lease but preserves preference; stale permission cannot activate',
    () async {
      service.permission = false;
      await start(FocusChoice.always);
      focus.observe(session: null, ready: false);
      focus.observe(session: 'account-b', ready: true);
      service.permission = true;
      focus.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await focus.settled;
      expect(service.reconciled, contains(null));
      expect(service.activations, isEmpty);
      expect(service.preference, FocusPreference.always);
    },
  );
  test(
    'cold restore reconciles same draft; recovery with no draft releases it',
    () async {
      focus.observe(session: null, ready: false);
      await focus.settled;
      expect(service.reconciled, isEmpty);
      focus.observe(session: 'restored', ready: true);
      await focus.settled;
      expect(service.reconciled, ['restored']);
      focus.observe(session: null, ready: true);
      await focus.settled;
      expect(service.reconciled.last, isNull);
    },
  );
  test(
    'late activation response after end is followed by owned cleanup',
    () async {
      service.heldActivation = Completer<FocusResult>();
      final pending = start();
      for (var i = 0; i < 5; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      focus.observe(session: null, ready: true);
      service.heldActivation!.complete(FocusResult.requested);
      await pending;
      await focus.settled;
      expect(service.reconciled.last, isNull);
      expect(focus.message, isNull);
    },
  );
  test('late permission status after end cannot open OS settings', () async {
    service.heldStatus = Completer<FocusStatus>();
    final pending = start();
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(starts, 1);
    focus.observe(session: null, ready: true);
    service.heldStatus!.complete(
      const FocusStatus(FocusCapability.ownedRule, false),
    );
    await pending;
    await focus.settled;
    expect(service.requests, 0);
    expect(service.activations, isEmpty);
  });
  test('local timer failure/no draft never activates focus', () async {
    await focus.start(
      startTimer: () async {},
      currentSession: () => null,
      choose: (_) async => FocusChoice.once,
    );
    expect(service.activations, isEmpty);
    expect(service.requests, 0);
  });
  for (final scale in [1.0, 2.0]) {
    for (final capability in [
      FocusCapability.ownedRule,
      FocusCapability.guideOnly,
    ]) {
      testWidgets('first-start and settings $capability 360x640 $scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        service.capability = capability;
        final semantics = tester.ensureSemantics();
        FocusChoice? picked;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: Builder(
                builder: (context) => Column(
                  children: [
                    TextButton(
                      onPressed: () async {
                        picked = await chooseStudyFocus(context, capability);
                      },
                      child: const Text('시작'),
                    ),
                    TextButton(
                      onPressed: () => showStudyFocusSettings(context, focus),
                      child: const Text('설정'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('시작'));
        await tester.pumpAndSettle();
        final action = capability == FocusCapability.ownedRule
            ? '이번만'
            : '안내 건너뛰고 시작';
        await tester.ensureVisible(find.text(action));
        expect(
          tester.getSize(find.widgetWithText(TextButton, action)).height,
          greaterThanOrEqualTo(48),
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(action));
        await tester.pumpAndSettle();
        expect(
          picked,
          capability == FocusCapability.ownedRule
              ? FocusChoice.once
              : FocusChoice.skip,
        );
        await tester.tap(find.text('설정'));
        await tester.pumpAndSettle();
        final disable = capability == FocusCapability.ownedRule
            ? '사용하지 않음'
            : '안내하지 않음';
        await tester.ensureVisible(find.text(disable));
        await tester.tap(find.text(disable));
        await tester.pumpAndSettle();
        expect(service.preference, FocusPreference.disabled);
        expect(tester.takeException(), isNull);
        semantics.dispose();
      });
    }
  }
}
