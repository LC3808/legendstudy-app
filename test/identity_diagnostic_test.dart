import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/auth/identity_diagnostic.dart';

import 'auth_lifecycle_sdk_test.dart' show fixtureSession;

void main() {
  const salt =
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  test('HMAC agrees with browser/Python vector; changes with salt', () {
    expect(
      identityDigest(salt, 'fixture-a'),
      '5012b8619b3f45c550fe2a204fe8a3825985de48f651bbb3102fdcbc27ece80e',
    );
    expect(
      identityDigest(salt, 'fixture-a'),
      isNot(identityDigest('b' * 64, 'fixture-a')),
    );
  });
  test(
    'server-validated GET emits only digest, no raw identity or credentials',
    () async {
      final requests = <http.Request>[];
      final client = SupabaseClient(
        'https://example.test',
        'test-only',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((r) async {
          requests.add(r);
          return http.Response(jsonEncode(fixtureSession()['user']), 200);
        }),
      );
      addTearDown(client.dispose);
      await client.auth.setInitialSession(jsonEncode(fixtureSession()));
      final records = <Map<String, Object>>[];
      final d = IdentityDiagnostic(
        client,
        salt,
        DateTime.now().add(const Duration(hours: 1)),
        records.add,
      );
      await d.probe('signedIn');
      await d.close();
      expect(records.single['status'], 'verified');
      expect(records.single['digest'], identityDigest(salt, 'fixture-a'));
      expect(jsonEncode(records), isNot(contains('fixture-a')));
      expect(jsonEncode(records), isNot(contains('access_token')));
      expect(requests.single.method, 'GET');
      expect(requests.single.url.path, '/auth/v1/user');
    },
  );
  test('server identity mismatch and raw SDK failure are sanitized', () async {
    var fail = false;
    final client = SupabaseClient(
      'https://example.test',
      'test-only',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((r) async {
        if (fail) throw Exception('PRIVATE_TOKEN_SENTINEL');
        return http.Response(
          jsonEncode({...fixtureSession()['user'] as Map, 'id': 'fixture-b'}),
          200,
        );
      }),
    );
    addTearDown(client.dispose);
    await client.auth.setInitialSession(jsonEncode(fixtureSession()));
    final records = <Map<String, Object>>[];
    final d = IdentityDiagnostic(
      client,
      salt,
      DateTime.now().add(const Duration(hours: 1)),
      records.add,
    );
    await d.probe('signedIn');
    fail = true;
    await d.probe('signedIn');
    await d.close();
    expect(records.map((r) => r['status']), [
      'session_changed',
      'verification_failed',
    ]);
    expect(jsonEncode(records), isNot(contains('PRIVATE_TOKEN_SENTINEL')));
  });
  test(
    'logout invalidates in-flight validation; no stale verified output',
    () async {
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
      final records = <Map<String, Object>>[];
      final d = IdentityDiagnostic(
        client,
        salt,
        DateTime.now().add(const Duration(hours: 1)),
        records.add,
      );
      final pending = d.probe('signedIn');
      await Future<void>.delayed(Duration.zero);
      await client.auth.signOut(scope: SignOutScope.local);
      await d.probe('signedOut');
      gate.complete(http.Response(jsonEncode(fixtureSession()['user']), 200));
      await pending;
      await d.close();
      expect(records.map((r) => r['status']), ['signed_out']);
    },
  );
  test('expired and default-disabled diagnostic do not call server', () async {
    var count = 0;
    final client = SupabaseClient(
      'https://example.test',
      'test-only',
      httpClient: MockClient((r) async {
        count++;
        return http.Response('', 500);
      }),
    );
    addTearDown(client.dispose);
    startIdentityDiagnostic(client);
    final d = IdentityDiagnostic(
      client,
      salt,
      DateTime.now().subtract(const Duration(seconds: 1)),
      (_) => fail('expired output'),
    );
    await d.probe('signedIn');
    await d.close();
    expect(count, 0);
  });
}
