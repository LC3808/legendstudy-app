import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/features/auth/auth_oauth.dart';
import 'package:legendstudy_app/features/auth/shared_account_check.dart';

import 'auth_lifecycle_sdk_test.dart' show fixtureSession;

void main() {
  test(
    'shared identity requires SDK/server/expected match; GET only',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.test',
        'test-only',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          requests.add(r);
          return http.Response(
            jsonEncode(fixtureSession()['user']),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      expect(await verifySharedAccount(client, 'fixture-a'), isFalse);
      expect(requests, isEmpty);
      await client.auth.setInitialSession(jsonEncode(fixtureSession()));
      expect(await verifySharedAccount(client, 'fixture-a'), isTrue);
      expect(await verifySharedAccount(client, 'fixture-b'), isFalse);
      expect(
        requests.every(
          (r) => r.method == 'GET' && r.url.path == '/auth/v1/user',
        ),
        isTrue,
      );
    },
  );
  test('shared identity rejects response after logout', () async {
    final gate = Completer<http.Response>();
    final client = SupabaseClient(
      'https://example.test',
      'test-only',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient(
        (r) async => r.method == 'GET' ? gate.future : http.Response('', 204),
      ),
    );
    addTearDown(client.dispose);
    await client.auth.setInitialSession(jsonEncode(fixtureSession()));
    final result = verifySharedAccount(client, 'fixture-a');
    await client.auth.signOut(scope: SignOutScope.local);
    gate.complete(
      http.Response(
        jsonEncode(fixtureSession()['user']),
        200,
        headers: {'content-type': 'application/json'},
      ),
    );
    expect(await result, isFalse);
  });
  test('Google flag without native client config stays hidden', () {
    final c = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(googleOAuthEnabled: true),
        ),
      ],
    );
    addTearDown(c.dispose);
    expect(c.read(availableOAuthProvidersProvider), isEmpty);
  });
}
