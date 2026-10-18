import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/profile/data/intended_major_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('major update uses owner PATCH only, supports clearing, rejects missing row', () async {
    const owner = '11111111-1111-4111-8111-111111111111';
    var calls = 0;
    final client = SupabaseClient(
      'https://example.invalid',
      'offline',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((r) async {
        calls++;
        expect(r.method, 'PATCH');
        expect(r.url.queryParameters['id'], 'eq.$owner');
        expect(jsonDecode(r.body), {
          'intended_major': calls == 1 ? '공학' : null,
        });
        return http.Response(
          calls == 3 ? '[]' : '{"id":"$owner"}',
          200,
          headers: {'content-type': 'application/json'},
          request: r,
        );
      }),
    );
    await client.auth.setInitialSession(
      jsonEncode({
        'access_token': 'offline',
        'refresh_token': 'offline',
        'token_type': 'bearer',
        'expires_in': 3600,
        'user': {
          'id': owner,
          'aud': 'authenticated',
          'role': 'authenticated',
          'created_at': '2026-01-01T00:00:00Z',
        },
      }),
    );
    final repo = SupabaseIntendedMajorRepository(client);
    await repo.set('공학');
    await repo.set(null);
    await expectLater(repo.set(null), throwsA(anything));
    expect(calls, 3);
    await client.dispose();
  });
}
