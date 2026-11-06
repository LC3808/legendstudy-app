import 'package:legendstudy_app/features/essay/exam_submission.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';
import 'package:legendstudy_app/features/essay/math_exam_session.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';

class NoClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation i) => throw StateError('No network');
}

class RoundGateway extends MathGateway {
  RoundGateway({this.free = false, this.changeSource = false})
    : super(NoClient(), 'owner');
  final bool free;
  bool changeSource;
  int betaClaims = 0, sourceQuotes = 0;
  String grant = '11111111-1111-4111-8111-111111111111';
  int creates = 0;
  bool lose = true;
  final submissions = <Map<String, dynamic>>[];
  final evaluated = <String>[];
  @override
  void checkOwner() {}
  @override
  Future<void> claimDailyBeta() async => betaClaims++;
  @override
  Future<dynamic> session(String name, Map<String, dynamic> params) async {
    if (name == 'math_session_history') {
      return {
        'version': 'math-session-history-v1',
        'runs': <dynamic>[
          if (free)
            {
              'version': 'math-session-v1',
              'run_id': 'previous',
              'exam_id': 'exam',
              'state': 'completed',
              'continuous_cycles_supported': true,
              'created_at': '2026-11-03T00:00:00Z',
              'next_quote': {'credits_required': 0},
              'questions': [
                {
                  'evaluation_id': 'previous-e',
                  'attempt_id': 'previous-a',
                  'question_id': 'q1',
                  'state': 'COMPLETED',
                },
              ],
            },
        ],
      };
    }
    if (name == 'math_session_quote') {
      return {'credits_required': free ? 0 : 1};
    }
    if (name == 'math_session_quote_source') {
      sourceQuotes++;
      return {
        'version': 'math-session-quote-v1',
        'credits_required': free ? 0 : 1,
        'credit_source': {
          'version': 'essay-credit-source-v1',
          'grant_id': free ? null : grant,
          'source': free ? 'included' : 'beta',
          'beta': free ? 0 : 1,
          'signup_bonus': 0,
          'purchase': 0,
          'other': 0,
        },
      };
    }
    if (name == 'math_session_continue_source') {
      submissions.add(params);
      if (changeSource) {
        changeSource = false;
        lose = false;
        grant = '22222222-2222-4222-8222-222222222222';
        throw const PostgrestException(message: 'CHARGE_SOURCE_CHANGED');
      }
      if (lose) {
        lose = false;
        throw StateError('lost response');
      }
      return 'run';
    }
    if (name == 'math_session_read') {
      return {
        'version': 'math-session-v1',
        'run_id': 'run',
        'exam_id': 'exam',
        'state': evaluated.isEmpty ? 'reserved' : 'completed',
        'questions': [
          {
            'evaluation_id': 'e',
            'attempt_id': 'a',
            'question_id': 'q1',
            'state': evaluated.isEmpty ? 'REQUESTED' : 'COMPLETED',
          },
        ],
      };
    }
    throw StateError(name);
  }

  @override
  Future<Map<String, dynamic>> call(
    String fn,
    String action,
    Map<String, dynamic> payload,
  ) async {
    if (action == 'create_attempt') {
      creates++;
      return {'attempt_id': 'a'};
    }
    if (action == 'read_input') {
      return {'can_request_evaluation': true, 'candidate_regions': <dynamic>[]};
    }
    throw StateError(action);
  }

  @override
  Future<void> evaluate(String id) async {
    evaluated.add(id);
  }
}

void main() {
  for (final (isolated, enabled) in [
    (false, false),
    (false, true),
    (true, false),
    (true, true),
  ]) {
    testWidgets(
      'natural submission requires runtime admission in both environments: test=$isolated enabled=$enabled',
      (t) async {
        final fake = RoundGateway();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              SourceDraftGateway.channel,
              (_) async => null,
            );
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(SourceDraftGateway.channel, null),
        );
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              appConfigProvider.overrideWithValue(
                AppConfig(
                  environment: isolated ? 'test' : 'production',
                  supabaseUrl: isolated
                      ? 'https://kpqbedylxlyntrrfybpn.supabase.co'
                      : 'https://stlhijzpjfgwwdgunlsd.supabase.co',
                  testEssayApiOrigin: 'https://legendstudy-task16b.pages.dev',
                ),
              ),
              authStateProvider.overrideWith(
                (ref) => Stream.value(const AuthStatus('owner')),
              ),
              mathCatalogProvider('owner').overrideWith(
                (ref) async => [
                  {
                    'essay_exam_id': 'exam',
                    'essay_question_id': 'q1',
                    'leaf_id': 'leaf',
                  },
                ],
              ),
              mathGatewayProvider('owner').overrideWithValue(fake),
              mathEvaluationAvailableProvider(
                'owner',
              ).overrideWith((ref) async => !enabled),
              examAvailabilityProvider((
                owner: 'owner',
                examId: 'exam',
              )).overrideWith(
                (ref) async => {
                  'ready': enabled,
                  'questionIds': ['q1'],
                  'mathQuestions': {'q1': 'leaf'},
                },
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ExamAnswerReview(
                  owner: 'owner',
                  currentQuestion: 'q1',
                  selectedQuestions: const {'q1'},
                  exam: {
                    'key': 'exam',
                    'dbExamId': 'exam',
                    'track': '자연계열',
                    'questions': [
                      {
                        'key': 'q1',
                        'dbQuestionId': 'q1',
                        'label': '문제 1',
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
        expect(
          find.byType(MathExamSession),
          enabled ? findsOneWidget : findsNothing,
        );
        expect(find.text('이 시험은 아직 첨삭을 이용할 수 없어요.'), findsNothing);
        expect(fake.submissions, isEmpty);
        expect(fake.evaluated, isEmpty);
        expect(t.takeException(), isNull);
      },
    );
  }
  test('retry preserves successful questions and rejects in-flight rounds', () {
    Map<String, dynamic> r(List<String> states) => {
      'state': 'reserved',
      'questions': states.map((s) => <String, dynamic>{'state': s}).toList(),
    };
    expect(mathSessionRetryable(r(['COMPLETED', 'FAILED'])), isTrue);
    expect(
      mathSessionRetryable(r(['COMPLETED', 'PROCESSING', 'FAILED'])),
      isFalse,
    );
    expect(mathSessionRetryable(r(['COMPLETED'])), isFalse);
  });
  for (final mode in [
    'lost response',
    'legacy replay',
    'source changed',
    'free rewrite',
  ]) {
    testWidgets('source consent and durable round retry: $mode', (t) async {
      await t.binding.setSurfaceSize(const Size(700, 1600));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final disk = <String, String>{};
      final free = mode == 'free rewrite';
      final changed = mode == 'source changed';
      final fake = RoundGateway(free: free, changeSource: changed);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async {
            if (call.method == 'read') return disk[call.arguments];
            if (call.method == 'write') {
              final a = call.arguments as Map;
              disk[a['key'] as String] = a['value'] as String;
            }
            return null;
          });
      await SourceDraftGateway(
        'owner',
        essayWritingDraftKey('draft1', free ? {'id': 'previous'} : null),
      ).saveLocalDraft('저장한 풀이', 0);
      Future<void> mount() async {
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => Stream.value(const AuthStatus('owner')),
              ),
              mathGatewayProvider('owner').overrideWithValue(fake),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: MathExamSession(
                    owner: 'owner',
                    rewriteRun: free
                        ? {
                            'id': 'previous',
                            'free_rewrite_until': '2026-11-10T15:00:00Z',
                          }
                        : null,
                    exam: {
                      'dbExamId': 'exam',
                      'questions': [
                        {
                          'key': 'draft1',
                          'dbQuestionId': 'q1',
                          'label': '문제 1',
                        },
                        {
                          'key': 'draft2',
                          'dbQuestionId': 'q2',
                          'label': '문제 2',
                        },
                      ],
                    },
                    selected: {'draft1'},
                    leaves: {'q1': 'leaf'},
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
      }

      await mount();
      await t.tap(find.text('저장한 답안 확인'));
      await t.pumpAndSettle();
      expect(fake.submissions, isEmpty);
      await t.tap(find.text('첨삭 요청하기'));
      await t.pumpAndSettle();
      expect(find.text('작성하지 않은 답안이 있습니다'), findsOneWidget);
      expect(fake.submissions, isEmpty);
      await t.tap(find.text(free ? '무료 재첨삭하기' : '이용권 1개 사용하고 첨삭하기'));
      await t.pumpAndSettle();
      expect(fake.submissions, hasLength(1));
      expect(fake.submissions.single['p_expected_credits'], free ? 0 : 1);
      expect(fake.submissions.single['p_previous'], free ? 'previous' : null);
      expect(
        fake.submissions.single['p_expected_grant'],
        free ? null : '11111111-1111-4111-8111-111111111111',
      );
      expect(fake.betaClaims, free ? 0 : 1);
      if (mode == 'legacy replay') {
        for (final key in disk.keys.toList()) {
          final draft = jsonDecode(disk[key]!) as Map<String, dynamic>;
          final body = draft['body'];
          if (body is! String || !body.contains('expectedGrant')) continue;
          final saved = jsonDecode(body) as Map<String, dynamic>;
          saved.remove('expectedGrant');
          saved.remove('sourceConsent');
          draft['body'] = jsonEncode(saved);
          disk[key] = jsonEncode(draft);
        }
      }
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      await mount();
      if (changed) {
        await t.tap(find.text('저장한 답안 확인'));
        await t.pumpAndSettle();
        await t.tap(find.text('첨삭 요청하기'));
        await t.pumpAndSettle();
        expect(fake.submissions, hasLength(1));
        await t.tap(find.text('이용권 1개 사용하고 첨삭하기'));
      } else {
        await t.tap(find.text('접수한 첨삭 계속하기'));
      }
      await t.pumpAndSettle();
      expect(fake.creates, 1);
      expect(fake.submissions, hasLength(2));
      if (changed) {
        expect(fake.submissions[0]['p_key'], fake.submissions[1]['p_key']);
        expect(fake.submissions[1]['p_expected_grant'], fake.grant);
        expect(fake.sourceQuotes, 2);
        expect(fake.betaClaims, 2);
      } else if (mode == 'legacy replay') {
        expect(fake.submissions[1]['p_key'], fake.submissions[0]['p_key']);
        expect(fake.submissions[1]['p_expected_grant'], isNull);
        expect(fake.sourceQuotes, 1);
        expect(fake.betaClaims, 1);
      } else {
        expect(
          jsonEncode(fake.submissions[0]),
          jsonEncode(fake.submissions[1]),
        );
        expect(fake.sourceQuotes, 1);
        expect(fake.betaClaims, free ? 0 : 1);
      }
      expect(fake.evaluated, ['e']);
      expect(find.text('문제 1 첨삭 결과 보기'), findsOneWidget);
      expect(find.text('첨삭 상태 새로고침'), findsNothing);
      expect(find.text('새 답안 준비'), findsNothing);
      expect(fake.evaluated, ['e']);
    });
  }
}
