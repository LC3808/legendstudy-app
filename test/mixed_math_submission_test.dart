import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/exam_rewrite.dart';
import 'package:legendstudy_app/features/essay/exam_submission.dart';
import 'package:legendstudy_app/features/essay/math_exam_session.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';
import 'package:legendstudy_app/features/essay/prepared_math_input.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';

import 'auth_lifecycle_sdk_test.dart' show fixtureSession;

const owner = 'fixture-a';
const attempt = '11111111-1111-4111-8111-111111111111';
const confirmed = '22222222-2222-4222-8222-222222222222';

class MixedInputGateway extends MathGateway {
  MixedInputGateway(SupabaseClient client) : super(client, 'fixture-a');
  final sessions = <String>[];
  final inputCalls = <String>[];
  final evaluated = <String>[];
  @override
  void checkOwner() {}
  @override
  Future<dynamic> session(String name, Map<String, dynamic> params) async {
    sessions.add(name);
    throw StateError('Mixed inputs must not reserve a Math round');
  }

  @override
  Future<void> evaluate(String id) async => evaluated.add(id);
  @override
  Future<Map<String, dynamic>> call(
    String fn,
    String action,
    Map<String, dynamic> payload,
  ) async {
    inputCalls.add(action);
    if (action == 'create_attempt') return {'attempt_id': attempt};
    if (action == 'read_input') {
      return {
        'can_request_evaluation': true,
        'input_state': 'CONFIRMED',
        'selected_extraction_id': confirmed,
        'candidate_regions': <dynamic>[],
      };
    }
    throw StateError(action);
  }
}

class MixedExamGateway extends ExamSubmissionGateway {
  MixedExamGateway(SupabaseClient client) : super(client, 'fixture-a');
  final calls = <Map<String, dynamic>>[];
  @override
  Future<Map<String, dynamic>> request(Map<String, dynamic> payload) async {
    calls.add(payload);
    if (payload['action'] == 'quote') {
      return {'version': 'essay-exam-quote-v1', 'credits': 1};
    }
    if (payload['action'] == 'submit') return {'runId': 'mixed-run'};
    throw StateError('${payload['action']}');
  }
}

void main() {
  test(
    'confirmed references are bound to exact body, image order and image bytes',
    () {
      final a = Uint8List.fromList([1, 2]), b = Uint8List.fromList([3, 4]);
      final input = PreparedMathInput(
        attemptId: attempt,
        confirmedRunId: confirmed,
        body: 'r=-1/6',
        imageHashes: [
          for (final image in [a, b]) sha256.convert(image).toString(),
        ],
      );
      expect(input.matches('r=-1/6', [a, b]), true);
      expect(input.matches('r=-1/5', [a, b]), false);
      expect(input.matches('r=-1/6', [b, a]), false);
      expect(input.matches('r=-1/6', [a]), false);
      expect(isMathInputReference(input.reference), true);
      expect(
        isMathInputReference({'attemptId': attempt, 'confirmedRunId': null}),
        false,
      );
      expect(
        isMathInputReference({...input.reference, 'body': 'unconfirmed'}),
        false,
      );
    },
  );

  test(
    'mixed rewrite retains frozen question set and immutable input references',
    () {
      final refs = {'attemptId': attempt, 'confirmedRunId': confirmed};
      final answers = examRewriteAnswers(
        [
          {'questionId': 'q1', 'body': '수정한 논증', 'revision': 0},
          {'questionId': 'q2', 'mathInput': refs, 'revision': 0},
        ],
        {
          'question_ids': ['q1', 'q2'],
          'answers': [
            {'questionId': 'q1', 'body': '이전 논증', 'revision': 2},
            {'questionId': 'q2', 'body': '이전 확인 전사', 'revision': 4},
          ],
        },
      );
      expect(answers.map((a) => a['revision']), [3, 5]);
      expect(answers.last['mathInput'], refs);
      expect(answers.last.containsKey('body'), false);
    },
  );

  for (final changedAfterConfirmation in [false, true]) {
    testWidgets(
      'mixed photo uses one Essay parent; changed source is blocked: $changedAfterConfirmation',
      (t) async {
        await t.binding.setSurfaceSize(const Size(700, 1600));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final disk = <String, String>{}, photos = <String, Uint8List>{};
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async {
              if (call.method == 'read') return disk[call.arguments];
              if (call.method == 'readImage') return photos[call.arguments];
              final args = call.arguments;
              if (args is Map && call.method == 'write') {
                disk[args['key'] as String] = args['value'] as String;
              }
              if (args is Map && call.method == 'writeImage') {
                photos[args['key'] as String] = args['value'] as Uint8List;
              }
              return null;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(SourceDraftGateway.channel, null),
        );
        final client = SupabaseClient(
          'https://fixture.supabase.co',
          'public-fixture',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient(
            (r) async => http.Response(
              jsonEncode(
                r.url.path.contains('/auth/')
                    ? fixtureSession()
                    : r.url.path.endsWith('essay_exam_history')
                    ? {'version': 'essay-exam-history-v1', 'runs': <dynamic>[]}
                    : <String, dynamic>{},
              ),
              200,
              headers: {'content-type': 'application/json'},
              request: r,
            ),
          ),
        );
        await client.auth.signInWithPassword(
          email: 'student@example.test',
          password: 'fixture',
        );
        // Supabase auth disposal uses real async cleanup; awaiting it in the
        // widget fake clock hangs teardown (same convention as existing QA).
        addTearDown(() => unawaited(client.dispose()));
        final inputGateway = MixedInputGateway(client),
            examGateway = MixedExamGateway(client);
        final photo = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
        await SourceDraftGateway(
          owner,
          'essay-draft',
        ).saveLocalDraft('근거를 제시한 논증', 0);
        await SourceDraftGateway(owner, 'math-draft').saveImages([photo]);
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              supabaseClientProvider.overrideWithValue(client),
              authStateProvider.overrideWith(
                (ref) => Stream.value(const AuthStatus(owner)),
              ),
              mathGatewayProvider(owner).overrideWithValue(inputGateway),
              examSubmissionGatewayProvider(
                owner,
              ).overrideWithValue(examGateway),
              mathEvaluationAvailableProvider(
                owner,
              ).overrideWith((ref) async => true),
              mathCatalogProvider(owner).overrideWith(
                (ref) async => [
                  {
                    'essay_exam_id': 'exam',
                    'essay_question_id': 'q2',
                    'leaf_id': 'leaf2',
                  },
                ],
              ),
              examAvailabilityProvider((
                owner: owner,
                examId: 'exam',
              )).overrideWith(
                (ref) async => {
                  'ready': true,
                  'questionIds': ['q1', 'q2'],
                  'mathQuestions': {'q2': 'leaf2'},
                },
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ExamAnswerReview(
                  owner: owner,
                  currentQuestion: 'essay-draft',
                  selectedQuestions: const {'essay-draft', 'math-draft'},
                  exam: {
                    'key': 'exam',
                    'dbExamId': 'exam',
                    'sourceUniversityId': 'fixture',
                    'track': '상경계열',
                    'questions': [
                      {
                        'key': 'essay-draft',
                        'dbQuestionId': 'q1',
                        'label': '문제 1',
                        'inputMode': 'text',
                      },
                      {
                        'key': 'math-draft',
                        'dbQuestionId': 'q2',
                        'label': '문제 2',
                        'inputMode': 'image',
                      },
                    ],
                  },
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.byType(MathExamSession), findsOneWidget);
        expect(inputGateway.sessions, isEmpty);
        expect(examGateway.calls, isEmpty);
        await t.tap(find.text('저장한 답안 확인'));
        await t.pumpAndSettle();
        expect(find.text('답안 확인 완료'), findsOneWidget);
        expect(inputGateway.sessions, isEmpty);
        expect(inputGateway.evaluated, isEmpty);
        if (changedAfterConfirmation) {
          await SourceDraftGateway(owner, 'math-draft').saveImages([
            Uint8List.fromList([...photo, 1]),
          ]);
        }
        await t.tap(find.text('첨삭 요청'));
        await t.pumpAndSettle();
        if (changedAfterConfirmation) {
          expect(examGateway.calls, isEmpty);
          expect(find.textContaining('변경한 답안의 인식 내용을 다시 확인'), findsOneWidget);
        } else {
          expect(find.text('첨삭을 시작할까요?'), findsOneWidget);
          await t.tap(find.text('첨삭 시작'));
          await t.pump();
          await t.pump(const Duration(milliseconds: 200));
          expect(examGateway.calls.map((p) => p['action']), [
            'quote',
            'submit',
          ]);
          final request = examGateway.calls.last;
          expect(request['answers'], [
            {'questionId': 'q1', 'body': '근거를 제시한 논증', 'revision': 1},
            {
              'questionId': 'q2',
              'revision': 0,
              'mathInput': {'attemptId': attempt, 'confirmedRunId': confirmed},
            },
          ]);
          expect(request['examId'], 'exam');
          expect(request['parentId'], isNull);
          expect(inputGateway.sessions, isEmpty);
          expect(inputGateway.evaluated, isEmpty);
        }
        expect(t.takeException(), isNull);
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
      },
    );
  }
}
