import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/auth/auth_email.dart';
import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';

import 'auth_lifecycle_sdk_test.dart' show MemoryPkce;

class SignupFixture implements EmailAuthService {
  Object? loginError;
  int signups = 0;
  int logins = 0;
  @override
  Future<bool> signUp(String email, String password) async {
    signups++;
    return false;
  }

  @override
  Future<void> login(String email, String password) async {
    logins++;
    if (loginError != null) throw loginError!;
  }
}

void main() {
  testWidgets(
    'signup enters verification guidance; cooldown does not block login',
    (tester) async {
      final service = SignupFixture();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus(null)),
            ),
            emailAuthServiceProvider.overrideWithValue(service),
          ],
          child: const MaterialApp(home: Scaffold(body: AuthPage())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('회원가입'));
      await tester.tap(find.text('회원가입'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'student@example.test',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'fixture-password',
      );
      await tester.enterText(
        find.byType(TextFormField).at(2),
        'fixture-password',
      );
      final submit = find.widgetWithText(FilledButton, '회원가입');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(service.signups, 1);
      expect(find.textContaining('가입을 요청했어요'), findsOneWidget);
      expect(find.textContaining('인증 메일 재요청까지'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).at(1))
            .controller!
            .text,
        isEmpty,
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'fixture-password',
      );
      final login = find.widgetWithText(FilledButton, '로그인');
      await tester.ensureVisible(login);
      await tester.tap(login);
      await tester.pumpAndSettle();
      expect(service.logins, 1);
      expect(find.textContaining('메일에서 인증을 마쳤다면'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  test(
    'resend uses signup endpoint, PKCE and configured app redirect',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.test',
        'fixture',
        authOptions: AuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          pkceAsyncStorage: MemoryPkce(),
          autoRefreshToken: false,
        ),
        httpClient: MockClient((request) async {
          requests.add(request);
          return http.Response('{}', 200);
        }),
      );
      final c = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(client),
          appConfigProvider.overrideWithValue(
            const AppConfig(
              signupRedirectUrl: 'com.legendstudy.app://login-callback',
            ),
          ),
        ],
      );
      await c.read(resendSignupEmailProvider)!('student@example.test');
      expect(requests.single.url.path, '/auth/v1/resend');
      expect(
        requests.single.url.queryParameters['redirect_to'],
        'com.legendstudy.app://login-callback',
      );
      final body = jsonDecode(requests.single.body) as Map<String, dynamic>;
      expect(body['type'], 'signup');
      expect(body['code_challenge'], isNotEmpty);
      expect(body.containsKey('password'), isFalse);
      c.dispose();
      await client.dispose();
    },
  );
  test('cooldown expires using elapsed wall time without storing identity', () {
    var now = DateTime(2026, 11, 11);
    final cooldown = EmailRequestCooldown(now: () => now);
    cooldown.start();
    expect(cooldown.remainingSeconds, 60);
    now = now.add(const Duration(seconds: 61));
    expect(cooldown.remainingSeconds, 0);
  });
  for (final fails in [false, true]) {
    testWidgets('resend guard and safe success/error feedback: $fails', (
      tester,
    ) async {
      final gate = Completer<void>();
      var calls = 0;
      var now = DateTime(2026, 11, 11);
      final cooldown = EmailRequestCooldown(now: () => now);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus(null)),
            ),
            emailAuthServiceProvider.overrideWithValue(
              SignupFixture()
                ..loginError = const AuthException(
                  'fixture',
                  code: 'email_not_confirmed',
                  statusCode: '400',
                ),
            ),
            emailRequestCooldownProvider.overrideWithValue(cooldown),
            resendSignupEmailProvider.overrideWithValue((email) async {
              calls++;
              expect(email, 'student@example.test');
              await gate.future;
              if (fails) {
                throw const AuthException(
                  'private server detail',
                  code: 'over_email_send_rate_limit',
                );
              }
            }),
          ],
          child: const MaterialApp(home: Scaffold(body: AuthPage())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'student@example.test',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'fixture-password',
      );
      final login = find.widgetWithText(FilledButton, '로그인');
      await tester.ensureVisible(login);
      await tester.tap(login);
      await tester.pumpAndSettle();
      final resend = find.text('인증 메일 다시 요청');
      await tester.ensureVisible(resend);
      await tester.tap(resend);
      await tester.tap(resend);
      await tester.pump();
      expect(calls, 1);
      gate.complete();
      await tester.pumpAndSettle();
      expect(
        find.textContaining(fails ? '이메일 발송 한도' : '발송을 요청했어요'),
        findsOneWidget,
      );
      expect(find.textContaining('private server detail'), findsNothing);
      expect(find.textContaining('정상 전달'), findsNothing);
      expect(find.text('인증 메일 재요청까지 60초'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '로그인'))
            .onPressed,
        isNotNull,
      );
      now = now.add(const Duration(seconds: 61));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('인증 메일 다시 요청'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
