import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/auth/auth_email.dart';
import 'package:legendstudy_app/features/auth/auth_errors.dart';
import 'package:legendstudy_app/features/auth/auth_oauth.dart';
import 'package:legendstudy_app/features/auth/native_auth.dart';
import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';

import 'auth_oauth_test.dart' show FakeOAuthService;

const unverified = AuthException(
  'private detail',
  code: 'email_not_confirmed',
  statusCode: '400',
);

class LoginFixture implements EmailAuthService {
  Future<void> Function() attempt = () async {};
  int calls = 0;
  @override
  Future<void> login(String email, String password) async {
    calls++;
    await attempt();
  }

  @override
  Future<bool> signUp(String email, String password) async => false;
}

final loginButton = find.widgetWithText(FilledButton, '로그인');
final resendButton = find.text('인증 메일 다시 요청');
final verificationHelp = find.textContaining('메일에서 인증을 마쳤다면');

Future<void> mountLogin(
  WidgetTester tester,
  LoginFixture service, {
  OAuthService? oauth,
  Future<void> Function(String)? resend,
  Stream<AuthStatus>? auth,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        emailAuthServiceProvider.overrideWithValue(service),
        authStateProvider.overrideWith(
          (ref) => auth ?? Stream.value(const AuthStatus(null)),
        ),
        oauthServiceProvider.overrideWithValue(oauth),
        availableOAuthProvidersProvider.overrideWithValue(
          supportedOAuthProviders,
        ),
        resendSignupEmailProvider.overrideWithValue(resend),
      ],
      child: const MaterialApp(home: Scaffold(body: AuthPage())),
    ),
  );
  await tester.pumpAndSettle();
  await tester.enterText(
    find.byType(TextFormField).at(0),
    'student@example.test',
  );
  await tester.enterText(find.byType(TextFormField).at(1), 'fixture-password');
}

Future<void> submitLogin(WidgetTester tester) async {
  await tester.ensureVisible(loginButton);
  await tester.tap(loginButton);
  await tester.pumpAndSettle();
}

void expectInputs(WidgetTester tester) {
  expect(
    tester
        .widget<TextFormField>(find.byType(TextFormField).at(0))
        .controller!
        .text,
    'student@example.test',
  );
  expect(
    tester
        .widget<TextFormField>(find.byType(TextFormField).at(1))
        .controller!
        .text,
    'fixture-password',
  );
}

void main() {
  testWidgets(
    'late SDK sign-in clears timeout state without changing session policy',
    (tester) async {
      final auth = StreamController<AuthStatus>.broadcast();
      final pending = Completer<void>();
      await mountLogin(
        tester,
        LoginFixture()..attempt = () => pending.future,
        auth: auth.stream,
      );
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pump(emailAuthRequestTimeout);
      await tester.pumpAndSettle();
      expect(find.text(authTimeoutFailure), findsOneWidget);
      auth.add(
        const AuthStatus('fixture-owner', event: AuthChangeEvent.signedIn),
      );
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.text(authTimeoutFailure), findsNothing);
      expect(resendButton, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await auth.close();
    },
  );

  testWidgets(
    'ordinary and successful verified login never show verification help',
    (tester) async {
      final service = LoginFixture();
      await mountLogin(tester, service);
      expect(resendButton, findsNothing);
      expect(verificationHelp, findsNothing);
      await submitLogin(tester);
      expect(service.calls, 1);
      expect(resendButton, findsNothing);
      expect(verificationHelp, findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'unverified login keeps inputs; successful retry removes guidance',
    (tester) async {
      final service = LoginFixture()..attempt = () async => throw unverified;
      await mountLogin(tester, service);
      await submitLogin(tester);
      expect(find.text(emailVerificationRequiredMessage), findsOneWidget);
      expect(resendButton, findsOneWidget);
      expect(verificationHelp, findsOneWidget);
      expectInputs(tester);
      service.attempt = () async {};
      await submitLogin(tester);
      expect(service.calls, 2);
      expect(resendButton, findsNothing);
      expect(verificationHelp, findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'changing email invalidates verification evidence without clearing password',
    (tester) async {
      await mountLogin(
        tester,
        LoginFixture()..attempt = () async => throw unverified,
      );
      await submitLogin(tester);
      await tester.enterText(
        find.byType(TextFormField).first,
        'other@example.test',
      );
      await tester.pump();
      expect(resendButton, findsNothing);
      expect(find.text(emailVerificationRequiredMessage), findsNothing);
      await tester.enterText(
        find.byType(TextFormField).first,
        'student@example.test',
      );
      await tester.pump();
      expect(resendButton, findsNothing);
      expectInputs(tester);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final (error, message) in <(Object, String)>[
    (
      const AuthException(
        'private',
        code: 'invalid_credentials',
        statusCode: '400',
      ),
      '이메일 또는 비밀번호를 확인해 주세요.',
    ),
    (const SocketException('private'), authNetworkFailure),
    (TimeoutException('private'), authTimeoutFailure),
    (
      AuthRetryableFetchException(message: 'private', statusCode: '503'),
      authServiceFailure,
    ),
    (const AuthException('Email not confirmed'), genericAuthFailure),
    (
      const AuthException(
        'private',
        code: 'email_not_confirmed',
        statusCode: '500',
      ),
      authServiceFailure,
    ),
  ]) {
    testWidgets(
      'failure $error releases loading without verification guidance',
      (tester) async {
        final service = LoginFixture()..attempt = () async => throw error;
        await mountLogin(tester, service);
        await submitLogin(tester);
        expect(find.text(message), findsOneWidget);
        expect(resendButton, findsNothing);
        expect(verificationHelp, findsNothing);
        expect(tester.widget<FilledButton>(loginButton).onPressed, isNotNull);
        expectInputs(tester);
        service.attempt = () async {};
        await submitLogin(tester);
        expect(service.calls, 2);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'hung login ignores duplicate taps and releases after deadline across resume',
    (tester) async {
      final pending = Completer<void>();
      final service = LoginFixture()..attempt = () => pending.future;
      await mountLogin(tester, service);
      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.tap(loginButton);
      await tester.pump();
      expect(service.calls, 1);
      expect(find.text('처리 중…'), findsOneWidget);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump(emailAuthRequestTimeout);
      for (final state in [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();
      expect(find.text(authTimeoutFailure), findsOneWidget);
      expect(tester.widget<FilledButton>(loginButton).onPressed, isNotNull);
      expectInputs(tester);
      service.attempt = () async {};
      await submitLogin(tester);
      pending.completeError(unverified);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(resendButton, findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'resend timeout keeps inputs and releases login while cooldown remains',
    (tester) async {
      final pending = Completer<void>();
      await mountLogin(
        tester,
        LoginFixture()..attempt = () async => throw unverified,
        resend: (_) => pending.future,
      );
      await submitLogin(tester);
      await tester.ensureVisible(resendButton);
      await tester.tap(resendButton);
      await tester.pump(emailAuthRequestTimeout);
      await tester.pumpAndSettle();
      expect(find.text(authTimeoutFailure), findsOneWidget);
      expect(find.textContaining('인증 메일 재요청까지'), findsOneWidget);
      expect(tester.widget<FilledButton>(loginButton).onPressed, isNotNull);
      expectInputs(tester);
      pending.complete();
      await tester.pumpAndSettle();
      expect(find.textContaining('발송을 요청했어요'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final (label, provider) in const [
    ('Google로 계속하기', OAuthProvider.google),
    ('Kakao로 계속하기', OAuthProvider.kakao),
    ('Apple로 계속하기', OAuthProvider.apple),
  ]) {
    testWidgets(
      '$label clears email-only guidance, preserves cancel contract',
      (tester) async {
        final oauth = FakeOAuthService(error: const NativeAuthCancelled());
        await mountLogin(
          tester,
          LoginFixture()..attempt = () async => throw unverified,
          oauth: oauth,
        );
        await submitLogin(tester);
        await tester.ensureVisible(find.text(label));
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(oauth.started, [provider]);
        expect(resendButton, findsNothing);
        expect(verificationHelp, findsNothing);
        expect(find.text('로그인을 취소했어요.'), findsOneWidget);
        expect(tester.widget<FilledButton>(loginButton).onPressed, isNotNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final (status, code, message, needsVerification) in [
    (400, 'email_not_confirmed', emailVerificationRequiredMessage, true),
    (400, 'invalid_credentials', '이메일 또는 비밀번호를 확인해 주세요.', false),
    (500, 'email_not_confirmed', authServiceFailure, false),
    (502, 'unexpected_failure', authServiceFailure, false),
    (503, 'unexpected_failure', authServiceFailure, false),
    (504, 'unexpected_failure', authTimeoutFailure, false),
  ]) {
    test(
      'installed SDK HTTP $status/$code uses typed response classification',
      () async {
        final client = SupabaseClient(
          'https://example.test',
          'fixture',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient(
            (request) async => http.Response(
              jsonEncode({
                'code': code,
                'msg': 'private detail',
                'error_code': code,
              }),
              status,
              headers: {
                'content-type': 'application/json',
                'x-supabase-api-version': '2024-01-01',
              },
            ),
          ),
        );
        addTearDown(client.dispose);
        try {
          await SupabaseEmailAuthService(client)
              .login('student@example.test', 'fixture-password');
          fail('must reject fixture response');
        } catch (error) {
          expect(authErrorMessage(error), message);
          expect(isEmailVerificationRequired(error), needsVerification);
        }
      },
    );
  }
}
