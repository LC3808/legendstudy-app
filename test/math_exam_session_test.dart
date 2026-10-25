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
  RoundGateway() : super(NoClient(), 'owner');
  int creates = 0;
  bool lose = true;
  final submissions = <Map<String, dynamic>>[];
  final evaluated = <String>[];
  @override
  void checkOwner() {}
  @override
  Future<dynamic> session(String name, Map<String, dynamic> params) async {
    if (name == 'math_session_history') {
      return {'version': 'math-session-history-v1', 'runs': <dynamic>[]};
    }
    if (name == 'math_session_submit') {
      submissions.add(params);
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
  testWidgets(
    'partial consent and lost response reuse one round key across remount',
    (t) async {
      await t.binding.setSurfaceSize(const Size(700, 1600));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final disk = <String, String>{};
      final fake = RoundGateway();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async {
            if (call.method == 'read') return disk[call.arguments];
            if (call.method == 'write') {
              final a = call.arguments as Map;
              disk[a['key'] as String] = a['value'] as String;
            }
            return null;
          });
      await SourceDraftGateway('owner', 'draft1').saveLocalDraft('저장한 풀이', 0);
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
      await t.tap(find.text('저장한 답안 입력 확인 · 0 크레딧'));
      await t.pumpAndSettle();
      expect(fake.submissions, isEmpty);
      await t.tap(find.text('논술 첨삭하기 · 1 크레딧'));
      await t.pumpAndSettle();
      expect(find.text('작성하지 않은 답안이 있습니다'), findsOneWidget);
      expect(fake.submissions, isEmpty);
      await t.tap(find.text('1 크레딧 사용하고 첨삭하기'));
      await t.pumpAndSettle();
      expect(fake.submissions, hasLength(1));
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      await mount();
      await t.tap(find.text('같은 회차 처리 확인'));
      await t.pumpAndSettle();
      expect(fake.creates, 1);
      expect(fake.submissions, hasLength(2));
      expect(jsonEncode(fake.submissions[0]), jsonEncode(fake.submissions[1]));
      expect(fake.evaluated, ['e']);
      await t.tap(find.text('같은 회차 상태 확인'));
      await t.pumpAndSettle();
      expect(fake.evaluated, ['e']);
    },
  );
}
