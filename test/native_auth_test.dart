import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/features/auth/apple_auth_diagnostics.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/auth/auth_oauth.dart';
import 'package:legendstudy_app/features/auth/native_auth.dart';

import 'auth_lifecycle_sdk_test.dart' show fixtureSession;

class FakeIdentity extends NativeIdentityProvider {
  final calls = <String>[];
  Completer<void>? pending;
  bool cancel = false;
  Future<NativeIdentityToken> result(String name) async {
    calls.add(name);
    await pending?.future;
    if (cancel) throw const NativeAuthCancelled();
    return const NativeIdentityToken(
      'synthetic-provider-token',
      'synthetic-nonce',
    );
  }

  @override
  Future<NativeIdentityToken> google() => result('google');
  @override
  Future<NativeIdentityToken> apple() => result('apple');
}

void main() {
  test('Apple fresh nonce is hashed for native and raw for exchange', () async {
    final hashes = <String>[];
    final provider = DeviceIdentityProvider(
      const AppConfig(),
      appleCredentialRequest: (hash) async {
        hashes.add(hash);
        return const AuthorizationCredentialAppleID(
          authorizationCode: 'unused-fixture-code',
          userIdentifier: null,
          givenName: null,
          familyName: null,
          email: null,
          state: null,
          identityToken: 'fixture-token',
        );
      },
    );
    final a = await provider.apple();
    final b = await provider.apple();
    expect(a.token, 'fixture-token');
    expect(a.nonce, isNot(b.nonce));
    expect(hashes, [
      for (final x in [a, b]) sha256.convert(utf8.encode(x.nonce!)).toString(),
    ]);
  });
  for (final token in <String?>[null, '']) {
    test('Apple rejects missing identity token ($token)', () async {
      final lines = <String>[];
      final provider = DeviceIdentityProvider(
        const AppConfig(),
        appleDiagnostics: AppleAuthDiagnostics(enabled: true, sink: lines.add),
        appleCredentialRequest: (_) async => AuthorizationCredentialAppleID(
          authorizationCode: 'unused-fixture-code',
          userIdentifier: null,
          givenName: null,
          familyName: null,
          email: null,
          state: null,
          identityToken: token,
        ),
      );
      await expectLater(provider.apple(), throwsA(isA<AuthException>()));
      expect(lines.last, contains('stage=identityToken'));
      expect(lines.last, contains('code=session_not_found'));
      expect(lines.join(), isNot(contains('unused-fixture-code')));
    });
  }
  test('Apple SDK cancellation is safely classified before mapping', () async {
    final lines = <String>[];
    final provider = DeviceIdentityProvider(
      const AppConfig(),
      appleDiagnostics: AppleAuthDiagnostics(enabled: true, sink: lines.add),
      appleCredentialRequest: (_) async =>
          throw const SignInWithAppleAuthorizationException(
            code: AuthorizationErrorCode.canceled,
            message: 'private-fixture-description',
          ),
    );
    await expectLater(provider.apple(), throwsA(isA<NativeAuthCancelled>()));
    expect(lines.last, contains('code=canceled'));
    expect(lines.join(), isNot(contains('private-fixture')));
  });
  test(
    'Apple diagnostics are off by default and never print uncontrolled values',
    () {
      final lines = <String>[];
      AppleAuthDiagnostics(sink: lines.add)
          .report(AppleAuthStage.nativeCredential);
      expect(lines, isEmpty);
      final d = AppleAuthDiagnostics(enabled: true, sink: lines.add);
      d.report(
        AppleAuthStage.supabaseExchange,
        error: const AuthException(
          'private-fixture',
          code: 'private-fixture',
          statusCode: 'private-fixture',
        ),
      );
      d.report(
        AppleAuthStage.nativeCredential,
        error: PlatformException(
          code: 'private-fixture',
          message: 'private-fixture',
          details: 'private-fixture',
        ),
      );
      expect(lines.length, 2);
      expect(lines.join(), isNot(contains('private-fixture')));
      expect(lines.every((s) => s.endsWith('code=unknown')), isTrue);
    },
  );
  for (final missingSession in [false, true]) {
    test(
      'Apple exchange ${missingSession ? 'missing session' : 'error'} safe diagnostic and retry',
      () async {
        var requests = 0;
        final lines = <String>[];
        final client = SupabaseClient(
          'https://example.test',
          'test-only',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((r) async {
            requests++;
            return http.Response(
              requests > 1
                  ? jsonEncode(fixtureSession())
                  : missingSession
                  ? '{}'
                  : jsonEncode({'code': 'bad_jwt', 'msg': 'private-fixture'}),
              requests > 1 || missingSession ? 200 : 400,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        addTearDown(client.dispose);
        final service = SupabaseOAuthService(
          client,
          native: FakeIdentity(),
          platform: TargetPlatform.iOS,
          appleDiagnostics: AppleAuthDiagnostics(
            enabled: true,
            sink: lines.add,
          ),
        );
        await expectLater(
          service.startSignIn(OAuthProvider.apple),
          throwsA(isA<AuthException>()),
        );
        expect(lines.last, contains('stage=supabaseExchange'));
        expect(lines.join(), isNot(contains('private-fixture')));
        expect(await service.startSignIn(OAuthProvider.apple), isTrue);
        expect(lines.last, contains('stage=session'));
        expect(lines.last, contains('kind=complete'));
        expect(requests, 2);
      },
    );
  }

  for (final provider in [OAuthProvider.google, OAuthProvider.apple]) {
    test(
      '$provider native token exchanges into SDK canonical identity',
      () async {
        final calls = <http.Request>[];
        final client = SupabaseClient(
          'https://example.test',
          'test-only',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((r) async {
            calls.add(r);
            return http.Response(
              jsonEncode(fixtureSession()),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        addTearDown(client.dispose);
        final native = FakeIdentity();
        final service = SupabaseOAuthService(
          client,
          native: native,
          platform: TargetPlatform.iOS,
        );
        expect(await service.startSignIn(provider), isTrue);
        expect(native.calls, [provider.name]);
        expect(client.auth.currentUser?.id, 'fixture-a');
        expect(calls.single.url.queryParameters['grant_type'], 'id_token');
        final body = jsonDecode(calls.single.body) as Map;
        expect(body['provider'], provider.name);
        expect(body['nonce'], 'synthetic-nonce');
        expect(body['id_token'], 'synthetic-provider-token');
      },
    );
  }
  test('native cancellation sends no exchange and permits retry; duplicate guarded', () async {
    var requests = 0;
    final client = SupabaseClient(
      'https://example.test',
      'test-only',
      httpClient: MockClient((r) async {
        requests++;
        return http.Response('{}', 400);
      }),
    );
    addTearDown(client.dispose);
    final native = FakeIdentity()
      ..cancel = true
      ..pending = Completer<void>();
    final service = SupabaseOAuthService(
      client,
      native: native,
      platform: TargetPlatform.iOS,
    );
    final first = service.startSignIn(OAuthProvider.apple);
    expect(await service.startSignIn(OAuthProvider.google), isFalse);
    native.pending!.complete();
    await expectLater(first, throwsA(isA<NativeAuthCancelled>()));
    native.pending = null;
    await expectLater(
      service.startSignIn(OAuthProvider.apple),
      throwsA(isA<NativeAuthCancelled>()),
    );
    expect(requests, 0);
    expect(native.calls, ['apple', 'apple']);
  });
  test('late native identity cannot replace another signed-in owner', () async {
    var requests = 0;
    final client = SupabaseClient(
      'https://example.test',
      'test-only',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((r) async {
        requests++;
        return http.Response('{}', 400);
      }),
    );
    addTearDown(client.dispose);
    final native = FakeIdentity()..pending = Completer<void>();
    final service = SupabaseOAuthService(
      client,
      native: native,
      platform: TargetPlatform.iOS,
    );
    final started = service.startSignIn(OAuthProvider.google);
    await client.auth.setInitialSession(jsonEncode(fixtureSession()));
    native.pending!.complete();
    await expectLater(started, throwsA(isA<NativeAuthCancelled>()));
    expect(client.auth.currentUser?.id, 'fixture-a');
    expect(requests, 0);
  });
}
