import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/auth/auth_email.dart';
import 'package:legendstudy_app/features/auth/auth_errors.dart';
import 'package:legendstudy_app/features/auth/auth_oauth.dart';
import 'package:legendstudy_app/features/auth/auth_recovery.dart';

// Synthetic unsigned fixture, never a credential and never sent to Production.
Map<String, dynamic> fixtureSession({bool expired = false}) {
  String encode(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final expiry =
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + (expired ? -3600 : 3600);
  final token =
      '${encode({'alg': 'none'})}.${encode({'sub': 'fixture-a', 'exp': expiry})}.test-only';
  return {
    'access_token': token,
    'refresh_token': ['fixture', 'refresh'].join('-'),
    'token_type': 'bearer',
    'expires_in': 3600,
    'user': {
      'id': 'fixture-a',
      'aud': 'authenticated',
      'email': 'student@example.test',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-01-01T00:00:00Z',
    },
  };
}

class MemorySessions extends LocalStorage {
  String? value;
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() async => value != null;
  @override
  Future<String?> accessToken() async => value;
  @override
  Future<void> persistSession(String s) async {
    value = s;
  }

  @override
  Future<void> removePersistedSession() async {
    value = null;
  }
}

class MemoryPkce extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Flutter SDK persisted-session restart and logout restore correct identity',
    () async {
      final storage = MemorySessions()..value = jsonEncode(fixtureSession());
      final requests = <http.Request>[];
      Future<ProviderContainer> boot() async {
        await Supabase.initialize(
          url: 'https://example.test',
          publishableKey: 'test-only',
          debug: false,
          httpClient: MockClient((r) async {
            requests.add(r);
            return http.Response('', 204, request: r);
          }),
          authOptions: FlutterAuthClientOptions(
            localStorage: storage,
            pkceAsyncStorage: MemoryPkce(),
            autoRefreshToken: false,
            detectSessionInUri: false,
          ),
        );
        return ProviderContainer(
          overrides: [
            supabaseClientProvider.overrideWithValue(Supabase.instance.client),
          ],
        );
      }

      var c = await boot();
      c.listen(authStateProvider, (_, _) {});
      expect(
        (await c
                .read(authStateProvider.future)
                .timeout(const Duration(seconds: 5)))
            .userId,
        'fixture-a',
      );
      c.dispose();
      await Supabase.instance.dispose();
      c = await boot();
      c.listen(authStateProvider, (_, _) {});
      expect(
        (await c
                .read(authStateProvider.future)
                .timeout(const Duration(seconds: 5)))
            .userId,
        'fixture-a',
      );
      expect(requests, isEmpty);
      await c.read(localLogoutProvider)!();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(c.read(authStateProvider).value?.userId, isNull);
      expect(storage.value, isNull);
      c.dispose();
      await Supabase.instance.dispose();
      c = await boot();
      c.listen(authStateProvider, (_, _) {});
      expect((await c.read(authStateProvider.future)).isAuthenticated, isFalse);
      c.dispose();
      await Supabase.instance.dispose();
    },
  );
  test('expired or malformed SDK session is Guest until refreshed; no token in status', () {
    final expired = Session.fromJson(fixtureSession(expired: true));
    expect(
      authStatusFromSdk(AuthState(AuthChangeEvent.initialSession, expired))
          .userId,
      isNull,
    );
    expect(
      authStatusFromSdk(
        AuthState(
          AuthChangeEvent.tokenRefreshed,
          Session.fromJson(fixtureSession()),
        ),
      ).userId,
      'fixture-a',
    );
    final malformed = fixtureSession()
      ..['access_token'] = 'invalid-local-fixture';
    expect(
      authStatusFromSdk(
        AuthState(AuthChangeEvent.initialSession, Session.fromJson(malformed)),
      ).userId,
      isNull,
    );
    expect(
      authStatusFromSdk(const AuthState(AuthChangeEvent.signedOut, null))
          .userId,
      isNull,
    );
  });
  test('signup reflects session presence and uses explicitly configured verification redirect', () async {
    var session = false;
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.test',
      'test-only',
      authOptions: AuthClientOptions(
        autoRefreshToken: false,
        pkceAsyncStorage: MemoryPkce(),
      ),
      httpClient: MockClient((r) async {
        requests.add(r);
        return http.Response(
          jsonEncode(session ? fixtureSession() : fixtureSession()['user']),
          200,
          request: r,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final c = ProviderContainer(
      overrides: [
        supabaseClientProvider.overrideWithValue(client),
        appConfigProvider.overrideWithValue(
          const AppConfig(signupRedirectUrl: oauthCallbackUrl),
        ),
      ],
    );
    addTearDown(c.dispose);
    final service = c.read(emailAuthServiceProvider)!;
    expect(
      await service.signUp('student@example.test', 'fixture-only-password'),
      isFalse,
    );
    expect(
      requests.single.url.queryParameters['redirect_to'],
      oauthCallbackUrl,
    );
    session = true;
    expect(
      await service.signUp('student@example.test', 'fixture-only-password'),
      isTrue,
    );
    expect(const AppConfig().signupRedirectTo, isNull);
  });
  test('recovery callback expired/reused/missing code are safely classified by actual SDK', () async {
    var calls = 0;
    final client = SupabaseClient(
      'https://example.test',
      'test-only',
      authOptions: AuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: false,
        pkceAsyncStorage: MemoryPkce(),
      ),
      httpClient: MockClient((r) async {
        calls++;
        return http.Response('{}', 400, request: r);
      }),
    );
    addTearDown(client.dispose);
    for (final suffix in [
      '?error=access_denied&error_code=otp_expired',
      '?error=access_denied&error_code=flow_state_not_found',
      '',
    ]) {
      await expectLater(
        client.auth.getSessionFromUrl(Uri.parse('$recoveryDeepLink$suffix')),
        throwsA(predicate((e) => isRecoveryLinkFailure(e))),
      );
    }
    expect(calls, 0);
  });
  test('duplicate-email copy does not assert that an account exists', () {
    for (final code in ['email_exists', 'user_already_exists']) {
      final message = authErrorMessage(AuthException('private', code: code));
      expect(message, contains('있다면'));
      expect(message, isNot(contains('이미 가입')));
      expect(message, isNot(contains('private')));
    }
  });
}
