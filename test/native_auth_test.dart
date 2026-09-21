import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
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
