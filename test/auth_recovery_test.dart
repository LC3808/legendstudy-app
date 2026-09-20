import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/auth/auth_errors.dart';
import 'package:legendstudy_app/features/auth/auth_recovery.dart';
import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';
import 'package:legendstudy_app/features/auth/presentation/new_password_page.dart';
import 'package:legendstudy_app/features/auth/presentation/password_recovery_page.dart';

/// In-memory double. No network call is reachable from these tests.
class FakeRecoveryService implements AuthRecoveryService {
  FakeRecoveryService({this.sendError, this.updateError, this.delay});
  final Object? sendError;
  final Object? updateError;
  final Duration? delay;
  final sentEmails = <String>[];
  final passwords = <String>[];

  @override
  Future<void> sendRecoveryEmail(String email) async {
    sentEmails.add(email);
    if (delay != null) await Future<void>.delayed(delay!);
    if (sendError != null) throw sendError!;
  }

  @override
  Future<void> updatePassword(String password) async {
    passwords.add(password);
    if (delay != null) await Future<void>.delayed(delay!);
    if (updateError != null) throw updateError!;
  }
}

AuthException authError(String message, {String? code, String? statusCode}) =>
    AuthException(message, code: code, statusCode: statusCode);

void main() {
  /// A real GoRouter, because the screens navigate on success and on back.
  late GoRouter pageRouter;

  Future<void> mountPage(
    WidgetTester tester,
    Widget page, {
    AuthRecoveryService? service,
    AuthStatus auth = const AuthStatus('user-a'),
  }) async {
    pageRouter = GoRouter(
      initialLocation: '/page',
      routes: [
        GoRoute(path: '/page', builder: (_, _) => Scaffold(body: page)),
        GoRoute(
          path: '/my',
          builder: (_, _) => const Scaffold(body: Text('MY')),
        ),
        GoRoute(
          path: '/auth',
          builder: (_, _) => const Scaffold(body: Text('AUTH')),
        ),
        GoRoute(
          path: '/auth/recovery',
          builder: (_, _) => const Scaffold(body: Text('RECOVERY')),
        ),
      ],
    );
    addTearDown(pageRouter.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRecoveryServiceProvider.overrideWithValue(service),
          authStateProvider.overrideWith((ref) => Stream.value(auth)),
        ],
        child: MaterialApp.router(routerConfig: pageRouter),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('forgot password entry', () {
    testWidgets('login offers the recovery entry point', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus(null)),
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: AuthPage())),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('비밀번호를 잊으셨나요?'), findsOneWidget);
    });
  });

  group('recovery request', () {
    testWidgets('rejects a malformed email without calling the service',
        (tester) async {
      final service = FakeRecoveryService();
      await mountPage(tester, const PasswordRecoveryPage(), service: service);
      await tester.enterText(find.byType(TextField), 'not-an-email');
      await tester.tap(find.text('재설정 메일 보내기'));
      await tester.pumpAndSettle();
      expect(service.sentEmails, isEmpty);
      expect(find.text('이메일 형식을 확인해 주세요.'), findsOneWidget);
    });

    testWidgets('success shows neutral copy that does not disclose the account',
        (tester) async {
      final service = FakeRecoveryService();
      await mountPage(tester, const PasswordRecoveryPage(), service: service);
      await tester.enterText(find.byType(TextField), 'lc@example.com');
      await tester.tap(find.text('재설정 메일 보내기'));
      await tester.pumpAndSettle();
      expect(service.sentEmails, ['lc@example.com']);
      expect(find.text('입력한 이메일로 비밀번호 재설정 안내를 요청했습니다.'), findsOneWidget);
      expect(find.textContaining('가입되지 않은'), findsNothing);
      expect(find.textContaining('존재하지 않'), findsNothing);
    });

    testWidgets('duplicate taps send exactly one request', (tester) async {
      final service =
          FakeRecoveryService(delay: const Duration(milliseconds: 80));
      await mountPage(tester, const PasswordRecoveryPage(), service: service);
      await tester.enterText(find.byType(TextField), 'lc@example.com');
      await tester.tap(find.text('재설정 메일 보내기'));
      await tester.pump();
      await tester.tap(find.text('보내는 중'), warnIfMissed: false);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(service.sentEmails, hasLength(1));
    });

    testWidgets('failure shows mapped Korean, never the raw SDK text',
        (tester) async {
      final service = FakeRecoveryService(
        sendError: authError('Email rate limit exceeded'),
      );
      await mountPage(tester, const PasswordRecoveryPage(), service: service);
      await tester.enterText(find.byType(TextField), 'lc@example.com');
      await tester.tap(find.text('재설정 메일 보내기'));
      await tester.pumpAndSettle();
      expect(find.text('요청이 너무 잦아요. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
      expect(find.textContaining('rate limit'), findsNothing);
      expect(find.text('입력한 이메일로 비밀번호 재설정 안내를 요청했습니다.'), findsNothing);
    });
  });

  group('new password', () {
    testWidgets('without a session the form is not offered', (tester) async {
      await mountPage(
        tester,
        const NewPasswordPage(),
        service: FakeRecoveryService(),
        auth: const AuthStatus(null),
      );
      expect(find.text('재설정 링크를 다시 열어 주세요.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('mismatched values do not call updateUser', (tester) async {
      final service = FakeRecoveryService();
      await mountPage(tester, const NewPasswordPage(), service: service);
      await tester.enterText(find.byType(TextField).at(0), 'longenough1');
      await tester.enterText(find.byType(TextField).at(1), 'different11');
      await tester.tap(find.text('비밀번호 변경'));
      await tester.pumpAndSettle();
      expect(service.passwords, isEmpty);
      expect(find.text('두 비밀번호가 서로 달라요.'), findsOneWidget);
    });

    testWidgets('too short is rejected client side', (tester) async {
      final service = FakeRecoveryService();
      await mountPage(tester, const NewPasswordPage(), service: service);
      await tester.enterText(find.byType(TextField).at(0), 'short');
      await tester.enterText(find.byType(TextField).at(1), 'short');
      await tester.tap(find.text('비밀번호 변경'));
      await tester.pumpAndSettle();
      expect(service.passwords, isEmpty);
    });

    testWidgets('matching values update the password once', (tester) async {
      final service =
          FakeRecoveryService(delay: const Duration(milliseconds: 60));
      await mountPage(tester, const NewPasswordPage(), service: service);
      await tester.enterText(find.byType(TextField).at(0), 'longenough1');
      await tester.enterText(find.byType(TextField).at(1), 'longenough1');
      await tester.tap(find.text('비밀번호 변경'));
      await tester.pump();
      await tester.tap(find.text('변경하는 중'), warnIfMissed: false);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(service.passwords, ['longenough1']);
      expect(pageRouter.routerDelegate.currentConfiguration.uri.path, '/my',
          reason: 'success must leave the recovery screen immediately');
    });

    testWidgets('server rejection is shown in Korean', (tester) async {
      final service = FakeRecoveryService(
        updateError: authError(
          'New password should be different from the old password.',
        ),
      );
      await mountPage(tester, const NewPasswordPage(), service: service);
      await tester.enterText(find.byType(TextField).at(0), 'longenough1');
      await tester.enterText(find.byType(TextField).at(1), 'longenough1');
      await tester.tap(find.text('비밀번호 변경'));
      await tester.pumpAndSettle();
      expect(find.text('이전과 다른 비밀번호를 입력해 주세요.'), findsOneWidget);
      expect(find.textContaining('should be different'), findsNothing);
    });
  });

  group('error localization', () {
    test('invalid login credentials maps to Korean', () {
      expect(authErrorMessage(authError('Invalid login credentials')),
          '이메일 또는 비밀번호가 올바르지 않습니다.');
      expect(
          authErrorMessage(authError('anything', code: 'invalid_credentials')),
          '이메일 또는 비밀번호가 올바르지 않습니다.');
    });

    test('email confirmation, rate limit and expired link map', () {
      expect(authErrorMessage(authError('Email not confirmed')),
          contains('이메일 인증'));
      expect(authErrorMessage(authError('over_email_send_rate_limit',
              code: 'over_email_send_rate_limit')),
          contains('잠시 후'));
      expect(
          authErrorMessage(
              authError('Email link is invalid or has expired')),
          contains('만료'));
    });

    test('error_code arriving as statusCode is still mapped', () {
      // A link callback reports error=access_denied&error_code=otp_expired,
      // which gotrue turns into code=access_denied, statusCode=otp_expired.
      expect(
        authErrorMessage(
          authError(
            'Email link is invalid or has expired',
            code: 'access_denied',
            statusCode: 'otp_expired',
          ),
        ),
        contains('만료'),
      );
    });

    test('recovery link failures are told apart from ordinary failures', () {
      expect(
        isRecoveryLinkFailure(
          authError('x', code: 'access_denied', statusCode: 'otp_expired'),
        ),
        isTrue,
      );
      expect(
        isRecoveryLinkFailure(authError('x', code: 'flow_state_expired')),
        isTrue,
      );
      expect(
        isRecoveryLinkFailure(
          authError('Code verifier could not be found in local storage.'),
        ),
        isTrue,
        reason: 'a link opened on a device that did not request it',
      );
      expect(
        isRecoveryLinkFailure(authError('x', code: 'invalid_credentials')),
        isFalse,
      );
      expect(isRecoveryLinkFailure(StateError('x')), isFalse);
    });

    test('unknown errors use the safe fallback and leak nothing', () {
      for (final error in <Object>[
        authError('pq: duplicate key value violates unique constraint "x"'),
        StateError('Bearer eyJhbGciOi.payload.sig'),
        Exception('https://example.com/#access_token=secret'),
      ]) {
        final message = authErrorMessage(error);
        expect(message, genericAuthFailure);
        expect(message, isNot(contains('eyJ')));
        expect(message, isNot(contains('access_token')));
        expect(message, isNot(contains('http')));
      }
    });
  });

  group('recovery event routing', () {
    /// Mounts the router exactly as LegendStudyApp does: watched through a
    /// Consumer. This matters beyond fidelity. ProviderContainer.read opens a
    /// subscription and closes it again, which leaves routerProvider with no
    /// listener; Riverpod then deactivates that provider's own listen on
    /// authStateProvider, and no auth event would ever reach the router. Only a
    /// watched routerProvider reproduces the app's runtime.
    Future<GoRouter> mountAppRouter(
      WidgetTester tester,
      ProviderContainer container, {
      String? at = '/auth',
    }) async {
      late GoRouter router;
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              router = ref.watch(routerProvider);
              return MaterialApp.router(routerConfig: router);
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (at != null) {
        router.go(at);
        await tester.pumpAndSettle();
      }
      return router;
    }

    /// The override wraps the fake stream in withAuthFailures, exactly as the
    /// real provider wraps the SDK stream, so `auth.addError` exercises the
    /// production path rather than a test-only shortcut.
    ProviderContainer recoveryContainer(StreamController<AuthStatus> auth) {
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => withAuthFailures(auth.stream),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    testWidgets('a passwordRecovery status routes to the new password screen',
        (tester) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      final router = await mountAppRouter(tester, recoveryContainer(auth));

      auth.add(const AuthStatus('user-a', event: AuthChangeEvent.signedIn));
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        isNot('/auth/new-password'),
        reason: 'an ordinary sign-in must not open the recovery screen',
      );

      auth.add(
        const AuthStatus('user-a', event: AuthChangeEvent.passwordRecovery),
      );
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/auth/new-password',
      );
    });

    testWidgets('recovery routes exist and are reachable', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = await mountAppRouter(tester, container);

      for (final path in ['/auth', '/auth/recovery', '/auth/new-password']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, path);
      }
    });

    testWidgets('housekeeping events navigate nowhere at all', (tester) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      final router = await mountAppRouter(tester, recoveryContainer(auth));

      // A session the user already had is refreshed or its user record is
      // updated: nothing about that is a navigation.
      for (final event in [
        AuthChangeEvent.tokenRefreshed,
        AuthChangeEvent.userUpdated,
      ]) {
        auth.add(AuthStatus('user-a', event: event));
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/auth',
          reason: '$event must move no one',
        );
      }
    });

    testWidgets('an ordinary sign-in never reaches a recovery screen',
        (tester) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      final router = await mountAppRouter(tester, recoveryContainer(auth));

      auth.add(const AuthStatus('user-a', event: AuthChangeEvent.signedIn));
      await tester.pumpAndSettle();
      // Leaving the login screen after a successful sign-in belongs to
      // AuthPage and is asserted in auth_oauth_test.dart. What the router
      // guarantees is narrower and is what matters here: no recovery screen.
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        isNot(anyOf('/auth/new-password', '/auth/recovery')),
        reason: 'signedIn must not open a recovery screen',
      );
    });

    testWidgets('an authenticated cold start is not pulled to /my',
        (tester) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      // A social or recovery callback can start the app anywhere. Without a
      // login screen on display there is nothing to leave.
      final router = await mountAppRouter(tester, recoveryContainer(auth),
          at: '/home');

      auth.add(const AuthStatus('user-a', event: AuthChangeEvent.signedIn));
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
    });

    testWidgets('a recovery state that is already current is not missed',
        (tester) async {
      // Cold start: gotrue replays the last auth state to a new subscriber, so
      // the event can precede the router. fireImmediately must still catch it.
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthStatus(
                'user-a',
                event: AuthChangeEvent.passwordRecovery,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = await mountAppRouter(tester, container, at: null);
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/auth/new-password',
      );
    });

    testWidgets('an unusable recovery link explains itself in Korean',
        (tester) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      final router = await mountAppRouter(tester, recoveryContainer(auth));

      auth.addError(
        authError(
          'Email link is invalid or has expired',
          code: 'access_denied',
          statusCode: 'otp_expired',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/auth/recovery',
      );
      expect(find.text(recoveryLinkUnusableMessage), findsOneWidget);
      expect(find.textContaining('expired'), findsNothing);
      expect(find.textContaining('token'), findsNothing);
    });

    testWidgets('a failure keeps the identity and never retries',
        (tester) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      final container = recoveryContainer(auth);
      await mountAppRouter(tester, container);

      auth.add(const AuthStatus('user-a', event: AuthChangeEvent.signedIn));
      await tester.pumpAndSettle();
      auth.addError(authError('x', code: 'invalid_credentials'));
      await tester.pumpAndSettle();

      final status = container.read(authStateProvider);
      expect(
        status.hasError,
        isFalse,
        reason: 'an auth failure must not fail the identity provider, which '
            'would also start Riverpod\'s retry timer',
      );
      expect(status.value?.userId, 'user-a');
      expect(status.value?.failure, isNotNull);
      expect(status.value?.isPasswordRecovery, isFalse);
    });

    testWidgets('an unrelated auth failure does not hijack navigation',
        (tester) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      final router = await mountAppRouter(tester, recoveryContainer(auth));

      auth.addError(authError('x', code: 'invalid_credentials'));
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');
    });

    testWidgets('recovery navigates once and does not trap the router',
        (tester) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      final router = await mountAppRouter(tester, recoveryContainer(auth));

      auth.add(
        const AuthStatus('user-a', event: AuthChangeEvent.passwordRecovery),
      );
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/auth/new-password',
      );

      // A later ordinary event must not re-navigate, and leaving the screen
      // must not be bounced back by a standing redirect.
      auth.add(
        const AuthStatus('user-a', event: AuthChangeEvent.tokenRefreshed),
      );
      await tester.pumpAndSettle();
      router.go('/auth/recovery');
      await tester.pumpAndSettle();
      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        '/auth/recovery',
      );
    });
  });

  group('deep link configuration', () {
    final link = Uri.parse(recoveryDeepLink);

    test('the recovery link uses a scheme this app can own', () {
      // Reverse-DNS scheme equal to the bundle id / application id: no domain,
      // no hosting, no store verification, and no collision with another app.
      expect(link.scheme, 'com.legendstudy.app');
      expect(link.host, isNotEmpty);
      expect(link.hasQuery, isFalse, reason: 'no token or address in the URL');
    });

    test('iOS registers the recovery URL scheme', () {
      final plist = File('ios/Runner/Info.plist').readAsStringSync();
      expect(plist, contains('<key>CFBundleURLSchemes</key>'));
      expect(plist, contains('<string>${link.scheme}</string>'));
    });

    test('Android registers the recovery deep link', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(manifest, contains('android:scheme="${link.scheme}"'));
      expect(manifest, contains('android:host="${link.host}"'));
      expect(manifest, contains('android.intent.category.BROWSABLE'));
    });
  });

  group('configuration', () {
    test('an unconfigured recovery redirect stays null', () {
      expect(const AppConfig().recoveryRedirectTo, isNull);
      expect(
        const AppConfig(recoveryRedirectUrl: 'legendstudy://recovery')
            .recoveryRedirectTo,
        'legendstudy://recovery',
      );
    });

    test('email shape check accepts and rejects the obvious cases', () {
      expect(isPlausibleEmail('lc@example.com'), isTrue);
      expect(isPlausibleEmail(' lc@example.com '), isTrue);
      for (final bad in ['', 'lc', 'lc@', '@example.com', 'lc@example']) {
        expect(isPlausibleEmail(bad), isFalse, reason: bad);
      }
    });
  });
}
