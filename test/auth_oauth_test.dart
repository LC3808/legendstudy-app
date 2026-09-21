import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/auth/auth_errors.dart';
import 'package:legendstudy_app/features/auth/auth_oauth.dart';
import 'package:legendstudy_app/features/auth/auth_recovery.dart';
import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';

/// In-memory double. No browser and no network is reachable from these tests.
class FakeOAuthService implements OAuthService {
  FakeOAuthService({this.opened = true, this.error});
  final bool opened;
  final Object? error;
  final started = <OAuthProvider>[];

  @override
  Future<bool> startSignIn(OAuthProvider provider) async {
    started.add(provider);
    await Future<void>.delayed(Duration.zero);
    if (error != null) throw error!;
    return opened;
  }
}

AuthException authError(String message, {String? code, String? statusCode}) =>
    AuthException(message, code: code, statusCode: statusCode);

void main() {
  late GoRouter router;

  Future<void> mountLogin(
    WidgetTester tester, {
    OAuthService? service,
    Stream<AuthStatus>? auth,
  }) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    router = GoRouter(
      initialLocation: '/auth',
      routes: [
        GoRoute(
          path: '/auth',
          builder: (_, _) => const Scaffold(body: AuthPage()),
        ),
        GoRoute(
          path: '/home',
          builder: (_, _) => const Scaffold(body: Text('MY')),
        ),
        GoRoute(
          path: '/auth/recovery',
          builder: (_, _) => const Scaffold(body: Text('RECOVERY')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          oauthServiceProvider.overrideWithValue(service),
          availableOAuthProvidersProvider.overrideWithValue(
            supportedOAuthProviders,
          ),
          authStateProvider.overrideWith(
            (ref) =>
                withAuthFailures(auth ?? Stream.value(const AuthStatus(null))),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
  }

  String currentPath() => router.routerDelegate.currentConfiguration.uri.path;

  group('provider actions', () {
    for (final (label, provider) in const [
      ('Google로 계속하기', OAuthProvider.google),
      ('Apple로 계속하기', OAuthProvider.apple),
      ('Kakao로 계속하기', OAuthProvider.kakao),
    ]) {
      testWidgets('$label starts exactly that provider', (tester) async {
        final service = FakeOAuthService();
        await mountLogin(tester, service: service);
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(service.started, [provider]);
      });
    }

    testWidgets('all three providers are offered', (tester) async {
      await mountLogin(tester, service: FakeOAuthService());
      expect(supportedOAuthProviders.length, 3);
      for (final label in const [
        'Google로 계속하기',
        'Apple로 계속하기',
        'Kakao로 계속하기',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    });
  });

  group('starting a flow', () {
    testWidgets('a second tap while starting is ignored', (tester) async {
      final service = FakeOAuthService();
      await mountLogin(tester, service: service);
      await tester.tap(find.text('Google로 계속하기'));
      await tester.pump(); // busy, provider page opening
      await tester.tap(find.text('Kakao로 계속하기'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(service.started, [
        OAuthProvider.google,
      ], reason: 'two providers must not run at once');
    });

    testWidgets('the buttons are usable again after the flow starts', (
      tester,
    ) async {
      final service = FakeOAuthService();
      await mountLogin(tester, service: service);
      await tester.tap(find.text('Google로 계속하기'));
      await tester.pumpAndSettle();
      // The user can cancel in the browser and come straight back, so the
      // screen must not stay disabled.
      await tester.tap(find.text('Kakao로 계속하기'));
      await tester.pumpAndSettle();
      expect(service.started, [OAuthProvider.google, OAuthProvider.kakao]);
    });

    testWidgets('a provider page that will not open says so in Korean', (
      tester,
    ) async {
      await mountLogin(tester, service: FakeOAuthService(opened: false));
      await tester.tap(find.text('Google로 계속하기'));
      await tester.pumpAndSettle();
      expect(find.textContaining('열지 못했어요'), findsOneWidget);
    });

    testWidgets('a start failure is localized, never raw', (tester) async {
      await mountLogin(
        tester,
        service: FakeOAuthService(
          error: authError('Unsupported provider: provider is not enabled'),
        ),
      );
      await tester.tap(find.text('Apple로 계속하기'));
      await tester.pumpAndSettle();
      expect(find.text(genericAuthFailure), findsOneWidget);
      expect(find.textContaining('provider is not enabled'), findsNothing);
    });

    testWidgets('an unconfigured backend does not crash the screen', (
      tester,
    ) async {
      await mountLogin(tester, service: null);
      await tester.tap(find.text('Google로 계속하기'));
      await tester.pumpAndSettle();
      expect(find.textContaining('사용할 수 없어요'), findsOneWidget);
      expect(currentPath(), '/auth');
    });
  });

  group('callback outcome', () {
    testWidgets('a signed-in session leaves the login screen', (tester) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      await mountLogin(tester, service: FakeOAuthService(), auth: auth.stream);
      expect(currentPath(), '/auth');
      auth.add(const AuthStatus('user-a', event: AuthChangeEvent.signedIn));
      await tester.pumpAndSettle();
      expect(currentPath(), '/home');
    });

    testWidgets('a cancelled consent screen is explained, not silent', (
      tester,
    ) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      await mountLogin(tester, service: FakeOAuthService(), auth: auth.stream);
      auth.addError(authError('Access denied', code: 'access_denied'));
      await tester.pumpAndSettle();
      expect(find.text('로그인이 취소되었어요.'), findsOneWidget);
      expect(
        currentPath(),
        '/auth',
        reason: 'a cancelled social login must not open password recovery',
      );
    });

    testWidgets('housekeeping events leave the login screen alone', (
      tester,
    ) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      await mountLogin(tester, service: FakeOAuthService(), auth: auth.stream);
      for (final event in [
        AuthChangeEvent.tokenRefreshed,
        AuthChangeEvent.userUpdated,
      ]) {
        auth.add(AuthStatus('user-a', event: event));
        await tester.pumpAndSettle();
        expect(
          currentPath(),
          '/auth',
          reason: '$event is not a sign-in and must not close this screen',
        );
      }
    });

    testWidgets('a recovery session does not hijack the login return', (
      tester,
    ) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      await mountLogin(tester, service: FakeOAuthService(), auth: auth.stream);
      auth.add(
        const AuthStatus('user-a', event: AuthChangeEvent.passwordRecovery),
      );
      await tester.pumpAndSettle();
      expect(
        currentPath(),
        '/auth',
        reason: 'the recovery route owns that navigation',
      );
    });
  });

  group('error separation', () {
    test('a cancelled social login is not a recovery link failure', () {
      final cancelled = authError('Access denied', code: 'access_denied');
      expect(isRecoveryLinkFailure(cancelled), isFalse);
      expect(authErrorMessage(cancelled), '로그인이 취소되었어요.');
    });

    test('a provider that is not enabled is stated as a user-facing limit', () {
      final disabled = authError('x', code: 'provider_disabled');
      expect(isRecoveryLinkFailure(disabled), isFalse);
      expect(authErrorMessage(disabled), contains('로그인할 수 없어요'));
    });

    test('an expired recovery link still wins over the coarse code', () {
      final expired = authError(
        'Email link is invalid or has expired',
        code: 'access_denied',
        statusCode: 'otp_expired',
      );
      expect(isRecoveryLinkFailure(expired), isTrue);
      expect(authErrorMessage(expired), contains('만료'));
    });
  });

  group('callback registration', () {
    final oauth = Uri.parse(oauthCallbackUrl);
    final recovery = Uri.parse(recoveryDeepLink);

    test('the two callbacks share a scheme and differ by host', () {
      expect(oauth.scheme, recovery.scheme);
      expect(oauth.host, 'login-callback');
      expect(recovery.host, 'auth-recovery');
      expect(oauth.hasQuery, isFalse);
    });

    test('iOS covers both callbacks with one scheme entry', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      // iOS matches on scheme alone, so one entry serves both hosts.
      expect(plist, contains('<string>${oauth.scheme}</string>'));
      expect(
        '<key>CFBundleURLSchemes</key>'.allMatches(plist).length,
        1,
        reason: 'no duplicate scheme entries',
      );
    });

    test('Android registers the social login callback host', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(
        manifest,
        contains('android:host="${oauth.host}"'),
        reason: 'without this the provider callback never reaches the app',
      );
      expect(manifest, contains('android:host="${recovery.host}"'));
      expect(
        'android.intent.category.BROWSABLE'.allMatches(manifest).length,
        2,
      );
    });
  });
}
