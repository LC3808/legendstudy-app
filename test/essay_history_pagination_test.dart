import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/essay/shared_history.dart';

import 'auth_lifecycle_sdk_test.dart' show fixtureSession;

void main() {
  test('owner history follows all pages beyond 50 and rejects duplicate cursor rows', () async {
    var calls = 0;
    var duplicate = false;
    final client = SupabaseClient(
      'https://fixture.supabase.co',
      'fixture',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        dynamic data;
        if (request.url.path.contains('/auth/')) {
          data = fixtureSession();
        } else {
          expect(request.url.path.endsWith('essay_exam_history_page'), true);
          calls++;
          final params = jsonDecode(request.body) as Map<String, dynamic>;
          final next = params['p_before_id'];
          data = {
            'version': 'essay-exam-history-page-v1',
            'runs': [
              for (
                var i = next == null ? 0 : 50;
                i < (next == null ? 50 : 61);
                i++
              )
                {
                  'id': duplicate ? 'r0' : 'r$i',
                  'created_at': '2026-10-28T00:00:00Z',
                },
            ],
            'next': next == null
                ? {'at': '2026-10-28T00:00:00Z', 'id': 'r49'}
                : null,
          };
        }
        return http.Response(
          jsonEncode(data),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
    await client.auth.signInWithPassword(
      email: 'student@example.test',
      password: 'fixture',
    );
    final rows = await SharedEssayHistory(client, 'fixture-a').examRuns();
    expect(rows.length, 61);
    expect(calls, 2);
    expect(rows.last['id'], 'r60');
    duplicate = true;
    await expectLater(
      SharedEssayHistory(client, 'fixture-a').examRuns(),
      throwsFormatException,
    );
    await client.dispose();
  });
}
