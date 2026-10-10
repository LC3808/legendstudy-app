import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';

import 'auth_lifecycle_sdk_test.dart' show fixtureSession;

void main() {
  late SupabaseClient client;
  late List<http.Request> calls;
  setUp(() async {
    calls = [];
    client = SupabaseClient(
      'https://fixture.supabase.co',
      'fixture-public',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path.contains('/auth/')) {
          return http.Response(jsonEncode(fixtureSession()), 200);
        }
        calls.add(request);
        if (request.url.path.endsWith('math_catalog')) {
          return http.Response('[]', 200, request: request);
        }
        final body = Map<String, dynamic>.from(
          jsonDecode(request.body)['p_request'] as Map,
        );
        return http.Response(
          jsonEncode({
            ...body,
            'result': {'attempt_id': 'attempt'},
          }),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    await client.auth.signInWithPassword(
      email: 'student@example.test',
      password: 'synthetic',
    );
  });
  tearDown(() async => client.dispose());
  test(
    'closed allowlist gate never loads catalog; account mismatch sends nothing',
    () async {
      final gateway = MathGateway(
        client,
        'fixture-a',
        transport: MockClient((request) async {
          calls.add(request);
          return http.Response(
            '{"version":"essay-web-v1","types":{"math":false}}',
            200,
          );
        }),
      );
      expect(await gateway.catalog(), isEmpty);
      expect(calls.length, 1);
      final wrong = MathGateway(
        client,
        'other',
        transport: MockClient((r) async => throw StateError('must not send')),
      );
      await expectLater(wrong.available(), throwsStateError);
      gateway.close();
      wrong.close();
    },
  );
  test('RPC retries retain caller idempotency key and shared DTO', () async {
    final gateway = MathGateway(client, 'fixture-a');
    final payload = {
      'client_submission_id': mathRequestId(),
      'leaf_id': 'leaf',
      'typed_answer': 'x=2',
      'kind': 'INITIAL',
      'input_kind': 'TYPED',
    };
    await gateway.call('math_input', 'create_attempt', payload);
    await gateway.call('math_input', 'create_attempt', payload);
    expect(calls[0].body, calls[1].body);
    expect(
      jsonDecode(calls[0].body)['p_request']['dto_version'],
      'math-input-v1',
    );
    gateway.close();
  });
  test('native gateway pins origin, forbids redirects and recovers ambiguous response', () async {
    final gateway = MathGateway(
      client,
      'fixture-a',
      transport: MockClient((request) async {
        expect(request.url.toString(), '$mathOrigin/api/math/evaluate');
        expect(request.headers['Origin'], mathOrigin);
        expect(request.followRedirects, false);
        expect(jsonDecode(request.body), {'evaluation_id': 'same-evaluation'});
        expect(request.headers['Authorization'], startsWith('Bearer '));
        return http.Response('', 504);
      }),
    );
    await expectLater(gateway.evaluate('same-evaluation'), throwsStateError);
    gateway.close();
    await expectLater(gateway.evaluate('same-evaluation'), throwsStateError);
  });
}
