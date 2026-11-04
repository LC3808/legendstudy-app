import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/math_mobile/learning_completeness.dart';

void main() {
  final valid = <String, dynamic>{
    'version': 'learning-completeness-v1',
    'evaluation_id': 'new',
    'status': 'ASSESSED',
    'level': 3,
    'rationale': '공식 기준에 연결된 관측',
    'next_direction': '조건과 근거를 확인하세요.',
  };
  testWidgets('new reviewed judgement is distinct from university score', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningCompletenessCard(value: valid, evaluationId: 'new'),
        ),
      ),
    );
    expect(find.text('학습 완성도 · 3/5단계'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNWidgets(3));
    expect(
      find.text('학습을 돕는 단계이며 대학 공식 점수나 합격 가능성을 뜻하지 않습니다.'),
      findsOneWidget,
    );
  });
  testWidgets('missing historical and malformed grades are never inferred', (
    t,
  ) async {
    for (final v in [
      null,
      <String, dynamic>{},
      {...valid, 'level': 6},
      {...valid, 'level': 2.5},
      {...valid, 'evaluation_id': 'foreign'},
      {...valid, 'version': 'unknown'},
    ]) {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LearningCompletenessCard(value: v, evaluationId: 'new'),
          ),
        ),
      );
      expect(find.byIcon(Icons.star), findsNothing);
      expect(find.textContaining('학습 완성도'), findsNothing);
    }
  });
  testWidgets('insufficient evidence is withheld rather than zero stars', (
    t,
  ) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LearningCompletenessCard(
            value: {...valid, 'status': 'INSUFFICIENT_EVIDENCE', 'level': null},
            evaluationId: 'new',
          ),
        ),
      ),
    );
    expect(find.text('학습 완성도 · 판단 보류'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);
  });
  testWidgets('server comparison preserves evidence and policy boundaries', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningComparison(
            value: {
              'comparable': true,
              'before': 2,
              'after': 4,
              'delta': 2,
              'prior_rationale': '이전 조건 누락',
              'current_rationale': '현재 조건 확인',
              'improved_criterion_ids': ['criterion'],
              'remaining_criterion_ids': <String>[],
            },
          ),
        ),
      ),
    );
    expect(find.text('2단계 → 4단계 (+2)'), findsOneWidget);
    expect(find.text('이전 근거: 이전 조건 누락'), findsOneWidget);
    expect(find.text('현재 근거: 현재 조건 확인'), findsOneWidget);
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LearningComparison(
            value: {'comparable': false, 'reason': 'CRITERIA_CHANGED'},
          ),
        ),
      ),
    );
    expect(find.textContaining('직접 비교하지 않습니다'), findsOneWidget);
    expect(find.textContaining('2단계 →'), findsNothing);
  });
}
