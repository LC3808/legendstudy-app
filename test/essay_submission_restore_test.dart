import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/exam_submission.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';

import 'auth_lifecycle_sdk_test.dart' show fixtureSession;

class FixtureGateway extends ExamSubmissionGateway {
  FixtureGateway(super.client, super.owner);
  final actions = <String>[];
  @override
  Future<Map<String, dynamic>> request(Map<String, dynamic> payload) async {
    actions.add(payload['action'] as String);
    if (payload['action'] != 'availability') {
      throw StateError('Unexpected execution');
    }
    return {
      'ready': true,
      'questionIds': ['q'],
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final terminal in ['failed', 'completed']) {
    testWidgets(
      'saved run polls beyond 100s, pauses, resumes and handles $terminal',
      (tester) async {
        var state = 'reserved';
        var questionState = 'completed';
        final fixture = jsonDecode(
          File('test/fixtures/exam-history-v1.json')
              .readAsStringSync()
              .replaceAll('"question"', '"q"'),
        ) as Map<String, dynamic>;
        var reads = 0;
        final client = SupabaseClient(
          'https://fixture.supabase.co',
          'fixture-public',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((request) async {
            if (request.url.path.contains('/auth/')) {
              return http.Response(jsonEncode(fixtureSession()), 200);
            }
            if (request.url.path.endsWith('essay_exam_history_page')) {
              return http.Response(
                jsonEncode({'code': 'PGRST202', 'message': 'not deployed'}),
                404,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }
            if (request.url.path.endsWith('essay_exam_session_status')) {
              return http.Response(
                jsonEncode({
                  'version': 'exam-session-v1',
                  'questions': [
                    {'question_id': 'q', 'state': questionState},
                  ],
                }),
                200,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }
            if (request.url.path.endsWith('essay_exam_history')) {
              final id = jsonDecode(request.body)['p_run'];
              if (id != null) {
                if (id != 'run') {
                  throw StateError('Unexpected run');
                }
                reads++;
              }
              return http.Response(
                jsonEncode({
                  'version': 'essay-exam-history-v1',
                  'runs': id == null
                      ? <Map<String, dynamic>>[]
                      : [
                          {
                            if (state == 'completed')
                              ...Map<String, dynamic>.from(
                                fixture['before'] as Map,
                              ),
                            'id': 'run',
                            'state': state,
                            'question_ids': ['q'],
                            'exam_id': 'exam',
                            'created_at': '2026-10-28T00:00:00Z',
                          },
                        ],
                }),
                200,
                headers: {'content-type': 'application/json'},
                request: request,
              );
            }
            return http.Response(
              '{}',
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
        final gateway = FixtureGateway(client, 'fixture-a');
        final key = SourceDraftGateway(
          'fixture-a',
          'exam-request:exam:initial',
        ).key;
        final disk = <String, String>{
          key: jsonEncode({
            'revision': 1,
            'body': jsonEncode({
              'key': 'request',
              'runId': 'run',
              'fingerprint': 'kept',
            }),
          }),
        };
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async {
              if (call.method == 'read') return disk[call.arguments];
              if (call.method == 'write') {
                final args = Map<String, dynamic>.from(call.arguments as Map);
                disk[args['key'] as String] = args['value'] as String;
                return null;
              }
              throw StateError('Unexpected storage action');
            });
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              supabaseClientProvider.overrideWithValue(client),
              authStateProvider.overrideWith(
                (ref) => Stream.value(const AuthStatus('fixture-a')),
              ),
              examSubmissionGatewayProvider('fixture-a')
                  .overrideWithValue(gateway),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: ExamSubmissionPanel(
                    owner: 'fixture-a',
                    exam: {
                      'key': 'exam',
                      'dbExamId': 'exam',
                      'questions': [
                        {'key': 'q', 'dbQuestionId': 'q', 'label': '문제 1'},
                      ],
                    },
                    included: {'q'},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        expect(find.text('첨삭을 진행하고 있어요'), findsOneWidget);
        expect(find.text('완료'), findsOneWidget);
        expect(find.text('잠시 쉬어가세요 ☕'), findsOneWidget);
        questionState = 'failed';
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(find.text('일부 문항의 첨삭이 완료되지 않았어요.'), findsOneWidget);
        expect(find.text('화면을 닫아도 첨삭은 계속 진행됩니다.'), findsNothing);
        questionState = 'completed';
        for (var i = 0; i < 41; i++) {
          await tester.pump(const Duration(seconds: 3));
          await tester.pump();
        }
        expect(reads, greaterThan(30));
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        final paused = reads;
        await tester.pump(const Duration(seconds: 60));
        expect(reads, paused);
        state = terminal;
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        await tester.pump();
        await tester.pump();
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(seconds: 3));
        }

        if (terminal == 'failed') {
          expect(jsonDecode(disk[key]!)['body'], '');
        } else {
          expect(find.text('첨삭 결과'), findsOneWidget);
          expect(
            jsonDecode(jsonDecode(disk[key]!)['body'] as String)['runId'],
            'run',
          );
        }
        expect(gateway.actions, ['availability']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SourceDraftGateway.channel, null);
        unawaited(client.dispose());
      },
    );
  }
}
