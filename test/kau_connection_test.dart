import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/answer_image.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';
import 'package:legendstudy_app/features/essay/math_workspace_page.dart';

import 'auth_lifecycle_sdk_test.dart' show fixtureSession;

void main() {
  final exams =
      (jsonDecode(
            File(
              const String.fromEnvironment(
                'NATURAL_CANDIDATE',
                defaultValue: 'supabase/candidates/natural_expansion_20261111/connection/web-expansion-candidate.json',
              ),
            ).readAsStringSync(),
          )['exams']
          as List);
  final bindings = <Map<String, dynamic>>[
    for (final e in exams)
      for (final entry in (e['mathQuestions'] as Map).entries)
        {'examId': e['examId'], 'questionId': entry.key, 'leafId': entry.value},
  ];
  test('Existing candidate Registry identities survive shared gateway and submission DTO', () async {
    final requests = <Map<String, dynamic>>[];
    final client = SupabaseClient(
      'https://fixture.supabase.co',
      'fixture-public',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path.contains('/auth/')) {
          return http.Response(jsonEncode(fixtureSession()), 200);
        }
        final body = Map<String, dynamic>.from(
          jsonDecode(request.body)['p_request'] as Map,
        );
        requests.add(body);
        return http.Response(
          jsonEncode({
            ...body,
            'result': {'attempt_id': 'synthetic-attempt'},
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
    final gateway = MathGateway(
      client,
      'fixture-a',
      transport: MockClient((request) async {
        expect(request.url.path, '/api/essay/availability');
        return http.Response(
          jsonEncode({
            'version': 'essay-web-v1',
            'checked': true,
            'types': {'math': true},
            'mathQuestions': bindings,
          }),
          200,
        );
      }),
    );
    addTearDown(() async {
      gateway.close();
      await client.dispose();
    });
    final released = await gateway.releasedQuestions();
    expect(released, hasLength(bindings.length));
    for (final b in bindings) {
      expect(
        released
            .where((r) => r['essay_question_id'] == b['questionId'])
            .single['leaf_id'],
        b['leafId'],
      );
      final payload = {
        'client_submission_id': mathRequestId(),
        'leaf_id': b['leafId'],
        'kind': 'INITIAL',
        'input_kind': 'TYPED',
        'typed_answer': 'Synthetic transport contract only',
      };
      await gateway.call('math_input', 'create_attempt', payload);
      expect(requests.last, {
        'dto_version': 'math-input-v1',
        'action': 'create_attempt',
        'payload': payload,
      });
    }
  });
  for (final selected in bindings) {
    testWidgets(
      'existing input opens selected natural leaf ${selected['questionId']}',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => Stream.value(const AuthStatus('fixture')),
              ),
              mathCatalogProvider('fixture').overrideWith(
                (ref) async => [
                  for (final b in bindings)
                    {
                      'leaf_id': b['leafId'],
                      'label': b['questionId'],
                      'statement': 'Registry ${b['questionId']}',
                      'problem_statement': 'Synthetic connection fixture',
                      'response_format': 'FULL_SOLUTION',
                    },
                ],
              ),
              mathEvaluationAvailableProvider('fixture')
                  .overrideWith((ref) async => false),
            ],
            child: MaterialApp(
              home: MathWorkspacePage(
                requestedLeafId: selected['leafId'] as String,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Registry ${selected['questionId']}'), findsOneWidget);
        expect(find.byType(AnswerImagesInput), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('첨삭 진행'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, '첨삭 진행'))
              .onPressed,
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
