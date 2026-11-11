import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:legendstudy_app/core/config/app_information.dart';
import 'package:legendstudy_app/core/links/external_link.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/app_update/app_update_controller.dart';
import 'package:legendstudy_app/features/app_update/app_update_gate.dart';
import 'package:legendstudy_app/features/app_update/app_update_policy.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';

final now = DateTime.utc(2026, 11, 4);
Map<String, Object?> policy({
  String platform = 'ios',
  String version = '1.0.2',
  int build = 60,
  bool required = false,
}) => {
  'version': 'app-update-policy-v1',
  'platform': platform,
  'enabled': true,
  'latest_version': version,
  'latest_build': build,
  'minimum_supported_version': required ? '1.0.1' : null,
  'minimum_supported_build': required ? 55 : null,
  'update_type': required ? 'REQUIRED' : 'OPTIONAL',
  'required_approved': required,
  'store_release_verified': true,
  'verified_at': now.subtract(const Duration(hours: 1)).toIso8601String(),
  'release_notes': '학습 화면과 이용 편의성을 개선했어요.',
  'store_url': platform == 'ios'
      ? officialIosStoreUrl
      : officialAndroidStoreUrl,
};

class MemoryPreferences implements AppUpdatePreferenceStore {
  Completer<DateTime?>? delayedRead;
  final values = <String, DateTime>{};
  @override
  Future<DateTime?> deferredAt(String key) async =>
      delayedRead == null ? values[key] : await delayedRead!.future;
  @override
  Future<void> defer(String key, DateTime at) async {
    values[key] = at;
  }
}

void main() {
  const capture = bool.fromEnvironment('APP_UPDATE_CAPTURE');
  setUpAll(() async {
    if (!capture) return;
    await (FontLoader(
      'Pretendard',
    )..addFont(rootBundle.load('fonts/Pretendard-SemiBold.otf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  Future<void> screenshot(WidgetTester tester, String name) async {
    if (!capture) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('update-capture')),
      );
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final folder = Directory('/private/tmp/legendstudy-app-update-preview');
      await folder.create(recursive: true);
      await File('${folder.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  group('numeric version and verified release policy', () {
    test('numeric segments/builds, including 9 versus 10', () {
      int compare(String a, int ab, String b, int bb) =>
          AppInstalledVersion.parse(
            a,
            ab,
          ).compareTo(AppInstalledVersion.parse(b, bb));
      expect(compare('1.0.9', 99, '1.0.10', 1), lessThan(0));
      expect(compare('1.10.0', 1, '1.9.0', 100), greaterThan(0));
      expect(compare('1.0.1', 57, '1.0.1', 58), lessThan(0));
      expect(compare('1.0', 58, '1.0.0', 58), 0);
      expect(compare('2.0.0', 1, '1.99.99', 100), greaterThan(0));
    });
    test('latest and newer candidate never prompt', () {
      final p = AppUpdatePolicy.parse(policy(), platform: 'ios', now: now)!;
      expect(p.forInstalled(AppInstalledVersion.parse('1.0.2', 60)), isNull);
      expect(p.forInstalled(AppInstalledVersion.parse('1.0.2', 61)), isNull);
      expect(p.forInstalled(AppInstalledVersion.parse('1.0.3', 1)), isNull);
    });
    test('required is only below approved minimum; others remain optional', () {
      final p = AppUpdatePolicy.parse(
        policy(required: true),
        platform: 'ios',
        now: now,
      )!;
      expect(
        p.forInstalled(AppInstalledVersion.parse('1.0.1', 54))!.required,
        isTrue,
      );
      expect(
        p.forInstalled(AppInstalledVersion.parse('1.0.1', 55))!.required,
        isFalse,
      );
      expect(
        p.forInstalled(AppInstalledVersion.parse('1.0.1', 58))!.required,
        isFalse,
      );
      final unapproved = AppUpdatePolicy.parse(
        {...policy(required: true), 'required_approved': false},
        platform: 'ios',
        now: now,
      )!;
      expect(
        unapproved
            .forInstalled(AppInstalledVersion.parse('1.0.0', 1))!
            .required,
        isFalse,
      );
    });
    test('missing type defaults optional; platforms never mix', () {
      final optional = policy()..remove('update_type');
      expect(
        AppUpdatePolicy.parse(
          optional,
          platform: 'ios',
          now: now,
        )!.requiredApproved,
        isFalse,
      );
      expect(
        AppUpdatePolicy.parse(
          policy(platform: 'android'),
          platform: 'ios',
          now: now,
        ),
        isNull,
      );
      expect(
        AppUpdatePolicy.parse(
          policy(platform: 'android'),
          platform: 'android',
          now: now,
        ),
        isNotNull,
      );
    });
    for (final change in <Map<String, Object?>>[
      {'enabled': false},
      {'store_release_verified': false},
      {'verified_at': '2099-01-01T00:00:00Z'},
      {'verified_at': null},
      {'store_url': 'https://example.com/app'},
      {'store_url': '$officialIosStoreUrl?token=arbitrary'},
      {'latest_version': '1.0.2-testflight'},
      {'latest_build': '58x'},
      {'latest_build': -1},
      {'latest_version': null},
      {'minimum_supported_version': '9.0.0', 'minimum_supported_build': 1},
      {'update_type': 'FORCED'},
    ]) {
      test('invalid/unpublished policy does not block: $change', () {
        expect(
          AppUpdatePolicy.parse(
            {...policy(), ...change},
            platform: 'ios',
            now: now,
          ),
          isNull,
        );
      });
    }
  });
  group('check lifecycle and local postponement', () {
    late MemoryPreferences preferences;
    late DateTime clock;
    late Object? response;
    late int calls;
    AppUpdateController make({
      String platform = 'ios',
      Future<Object?> Function(String)? load,
    }) {
      final c = AppUpdateController(
        platform: platform,
        installed: () async => AppInstalledVersion.parse('1.0.1', 48),
        repository: CallbackAppUpdateRepository(
          load ??
              (_) async {
                calls++;
                return response;
              },
        ),
        preferences: preferences,
        clock: () => clock,
        timeout: const Duration(milliseconds: 20),
      );
      addTearDown(c.dispose);
      return c;
    }

    setUp(() {
      preferences = MemoryPreferences();
      clock = now;
      response = policy();
      calls = 0;
    });
    test(
      'later persists exact release for 24h and resumes normal usage',
      () async {
        final c = make();
        await c.check();
        expect(c.prompt, isNotNull);
        await c.later();
        expect(c.prompt, isNull);
        final restarted = make();
        await restarted.check();
        expect(restarted.prompt, isNull);
        clock = clock.add(const Duration(hours: 23));
        await restarted.check();
        expect(restarted.prompt, isNull);
        clock = clock.add(const Duration(hours: 1));
        await restarted.check();
        expect(restarted.prompt, isNotNull);
      },
    );
    test('new public release prompts despite prior later', () async {
      final c = make();
      await c.check();
      await c.later();
      response = policy(version: '1.0.3', build: 61);
      await c.check();
      expect(c.prompt!.policy.latest.version, '1.0.3');
    });
    test('coalesces concurrent checks; failed/timeout refresh clears required gate', () async {
      response = policy(required: true);
      final c = make();
      await c.check();
      expect(c.prompt!.required, isTrue);
      response = null;
      await Future.wait([c.check(), c.check(), c.check()]);
      expect(calls, 2);
      expect(c.prompt, isNull);
      final slow = make(load: (_) => Completer<Object?>().future);
      await slow.check();
      expect(slow.prompt, isNull);
      final broken = make(load: (_) async => throw Exception('offline'));
      await broken.check();
      expect(broken.prompt, isNull);
    });
    test(
      'required cannot be postponed; optional store return does not duplicate',
      () async {
        response = policy(required: true);
        final c = make();
        await c.check();
        await c.later();
        expect(c.prompt!.required, isTrue);
        c.openedStore();
        expect(c.prompt, isNotNull);
        expect(preferences.values, isEmpty);
        response = policy();
        await c.check();
        c.openedStore();
        await c.check();
        expect(c.prompt, isNull);
      },
    );
    for (final action in ['later', 'store']) {
      test('$action wins against a delayed preference read', () async {
        final c = make();
        await c.check();
        preferences.delayedRead = Completer<DateTime?>();
        final pending = c.check();
        await Future<void>.delayed(Duration.zero);
        if (action == 'later') {
          await c.later();
        } else {
          c.openedStore();
        }
        preferences.delayedRead!.complete(null);
        await pending;
        expect(c.prompt, isNull);
      });
    }
    test(
      'old store launch does not suppress a newly published release',
      () async {
        final c = make();
        await c.check();
        final oldPrompt = c.prompt!;
        response = policy(version: '1.0.3', build: 61);
        await c.check();
        c.openedStore(oldPrompt);
        expect(c.prompt!.policy.latest.version, '1.0.3');
      },
    );
    test(
      'late optional store success cannot dismiss an upgraded required policy',
      () async {
        final c = make();
        await c.check();
        final optionalPrompt = c.prompt!;
        response = policy(required: true);
        await c.check();
        c.openedStore(optionalPrompt);
        expect(c.prompt!.required, isTrue);
        await c.check();
        expect(c.prompt!.required, isTrue);
      },
    );
    test('each platform is queried separately', () async {
      final seen = <String>[];
      for (final p in ['ios', 'android']) {
        final c = make(
          platform: p,
          load: (platform) async {
            seen.add(platform);
            return policy(platform: platform);
          },
        );
        await c.check();
        expect(c.prompt!.policy.platform, p);
      }
      expect(seen, ['ios', 'android']);
    });
  });

  Future<({AppUpdateController controller, GoRouter router})> mount(
    WidgetTester tester, {
    bool required = false,
    String route = '/home',
    bool authed = false,
    Future<UserProfile?> Function()? profile,
    Future<bool> Function(Uri)? open,
    Future<Object?> Function(String)? load,
  }) async {
    final c = AppUpdateController(
      platform: 'ios',
      installed: () async => AppInstalledVersion.parse('1.0.1', 48),
      repository: CallbackAppUpdateRepository(
        load ?? (_) async => policy(required: required),
      ),
      preferences: MemoryPreferences(),
      clock: () => now,
    );
    final router = GoRouter(
      initialLocation: route,
      routes: [
        for (final path in [
          '/home',
          '/materials',
          '/auth',
          '/intro',
          '/onboarding',
        ])
          GoRoute(
            path: path,
            builder: (_, _) =>
                Scaffold(body: Center(child: Text('기존 화면 $path'))),
          ),
      ],
    );
    addTearDown(c.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          appUpdateControllerProvider.overrideWithValue(c),
          authStateProvider.overrideWith(
            (_) => Stream.value(AuthStatus(authed ? 'u' : null)),
          ),
          if (profile != null)
            currentProfileProvider.overrideWith((_) => profile()),
          if (open != null) externalOpenerProvider.overrideWithValue(open),
        ],
        child: MaterialApp.router(
          theme: capture
              ? AppTheme.light.copyWith(
                  textTheme: AppTheme.light.textTheme.apply(
                    fontFamily: 'Pretendard',
                  ),
                )
              : AppTheme.light,
          routerConfig: router,
          builder: (_, child) => RepaintBoundary(
            key: const ValueKey('update-capture'),
            child: AppUpdateGate(router: router, child: child!),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (controller: c, router: router);
  }

  for (final completed in [false, true]) {
    testWidgets('update prompt waits for onboarding (completed=$completed)', (
      tester,
    ) async {
      await mount(
        tester,
        authed: true,
        required: true,
        profile: () async =>
            UserProfile(id: 'u', onboardingCompletedAt: completed ? now : null),
      );
      expect(
        find.byType(AlertDialog),
        completed ? findsOneWidget : findsNothing,
      );
    });
  }
  testWidgets('missing profile waits for onboarding', (tester) async {
    await mount(tester, authed: true, profile: () async => null);
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets('loading profile waits, then completed profile is allowed', (
    tester,
  ) async {
    final profile = Completer<UserProfile?>();
    await mount(tester, authed: true, profile: () => profile.future);
    expect(find.byType(AlertDialog), findsNothing);
    profile.complete(UserProfile(id: 'u', onboardingCompletedAt: now));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });
  testWidgets('profile failure does not block service or start onboarding', (
    tester,
  ) async {
    await mount(
      tester,
      authed: true,
      profile: () async => throw StateError('unavailable'),
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('기존 화면 /home'), findsOneWidget);
  });
  testWidgets('provider disposal cancels an in-flight policy deadline', (
    tester,
  ) async {
    final response = Completer<Object?>();
    final container = ProviderContainer(
      overrides: [
        appUpdatePlatformProvider.overrideWithValue('ios'),
        installedAppVersionProvider.overrideWith(
          (_) async => AppInstalledVersion.parse('1.0.1', 48),
        ),
        appUpdateRepositoryProvider.overrideWithValue(
          CallbackAppUpdateRepository((_) => response.future),
        ),
        appUpdatePreferencesProvider.overrideWithValue(MemoryPreferences()),
      ],
    );
    final controller = container.read(appUpdateControllerProvider);
    final pending = controller.check();
    await tester.idle();
    container.dispose();
    await pending;
    // A late SDK response is ignored, without a leaked deadline or notifier.
    response.complete(policy());
    await tester.idle();
    expect(controller.prompt, isNull);
  });
  testWidgets('optional Native dialog later closes and service remains', (
    tester,
  ) async {
    final result = await mount(tester);
    expect(find.text('새로운 업데이트가 있어요.'), findsOneWidget);
    expect(find.text('나중에'), findsOneWidget);
    expect(find.text('버전 1.0.2'), findsOneWidget);
    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('기존 화면 /home'), findsOneWidget);
    await result.controller.check();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets(
    'official store action and return avoid duplicate optional dialogs',
    (tester) async {
      Uri? opened;
      final result = await mount(
        tester,
        open: (uri) async {
          opened = uri;
          return true;
        },
      );
      await tester.tap(find.text('업데이트하기'));
      await tester.pumpAndSettle();
      expect(opened, Uri.parse(officialIosStoreUrl));
      await result.controller.check();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
  testWidgets(
    'store launch completing while backgrounded is remembered on resume',
    (tester) async {
      final opened = Completer<bool>();
      await mount(tester, open: (_) => opened.future);
      await tester.tap(find.text('업데이트하기'));
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      opened.complete(true);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    },
  );
  testWidgets('idle policy completion requests a frame without user input', (
    tester,
  ) async {
    final response = Completer<Object?>();
    await mount(tester, load: (_) => response.future);
    expect(tester.binding.hasScheduledFrame, isFalse);
    response.complete(policy());
    // Flush only async work, without a manual frame or user gesture.
    await tester.idle();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });
  testWidgets('store launch timeout keeps service choice available', (
    tester,
  ) async {
    await mount(tester, open: (_) => Completer<bool>().future);
    await tester.tap(find.text('업데이트하기'));
    await tester.pump();
    expect(find.text('스토어 여는 중…'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('스토어를 열지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    await tester.tap(find.text('나중에'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });
  testWidgets(
    'required store failure remains retryable without service bypass',
    (tester) async {
      await mount(tester, required: true, open: (_) async => false);
      await tester.tap(find.text('업데이트하기'));
      await tester.pumpAndSettle();
      expect(find.text('업데이트가 필요해요.'), findsOneWidget);
      expect(find.text('나중에'), findsNothing);
      expect(find.text('스토어를 열지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
      expect(find.text('업데이트하기'), findsOneWidget);
    },
  );
  testWidgets('required cannot back-dismiss or expose service via navigation', (
    tester,
  ) async {
    final result = await mount(tester, required: true);
    expect(find.text('나중에'), findsNothing);
    await result.router.routerDelegate.navigatorKey.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    result.router.go('/materials');
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });
  for (final route in ['/auth', '/intro', '/onboarding']) {
    testWidgets('defers during $route then shows once after flow completion', (
      tester,
    ) async {
      final result = await mount(tester, route: route, required: true);
      expect(find.byType(AlertDialog), findsNothing);
      result.router.go('/home');
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      result.router.go('/auth');
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      result.router.go('/home');
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  }
  testWidgets(
    'resume network failure clears required prompt and keeps navigation',
    (tester) async {
      var online = true;
      await mount(
        tester,
        required: true,
        load: (_) async {
          if (!online) throw Exception('offline');
          return policy(required: true);
        },
      );
      expect(find.byType(AlertDialog), findsOneWidget);
      online = false;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pumpAndSettle();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('기존 화면 /home'), findsOneWidget);
    },
  );
  testWidgets('resume policy timeout restores service within three seconds', (
    tester,
  ) async {
    var responsive = true;
    await mount(
      tester,
      load: (_) async => responsive
          ? policy(required: true)
          : await Completer<Object?>().future,
    );
    expect(find.byType(AlertDialog), findsOneWidget);
    responsive = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('기존 화면 /home'), findsOneWidget);
  });
  testWidgets('Native optional and required review screens', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final result = await mount(tester);
    await screenshot(tester, 'optional-mock');
    await result.controller.later();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await mount(tester, required: true);
    await screenshot(tester, 'required-mock');
  });
  testWidgets('small Native display and large text remain scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester);
    expect(tester.takeException(), isNull);
    expect(find.text('업데이트하기'), findsOneWidget);
  });
}
