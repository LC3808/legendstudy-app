import 'dart:async';

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

AuthException authError(String message, {String? code}) =>
    AuthException(message, code: code);

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
      expect(find.text('비밀번호 재설정 안내를 확인해 주세요.'), findsOneWidget);
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
      expect(find.text('비밀번호 재설정 안내를 확인해 주세요.'), findsNothing);
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
      String at = '/auth',
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
      router.go(at);
      await tester.pumpAndSettle();
      return router;
    }

    ProviderContainer recoveryContainer(StreamController<AuthStatus> auth) {
      final container = ProviderContainer(
        overrides: [authStateProvider.overrideWith((ref) => auth.stream)],
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

    testWidgets('other auth events do not open the recovery screen',
        (tester) async {
      final auth = StreamController<AuthStatus>.broadcast();
      addTearDown(auth.close);
      final router = await mountAppRouter(tester, recoveryContainer(auth));

      for (final event in [
        AuthChangeEvent.signedIn,
        AuthChangeEvent.tokenRefreshed,
        AuthChangeEvent.userUpdated,
      ]) {
        auth.add(AuthStatus('user-a', event: event));
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/auth',
          reason: '$event must not open the recovery screen',
        );
      }
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
