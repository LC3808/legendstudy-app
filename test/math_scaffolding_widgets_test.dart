import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/math_text.dart';
import 'package:legendstudy_app/features/essay/math_learning_panel.dart';

void main() {
  testWidgets('native formulas render and malformed source survives', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MathText(r'\(\frac{x_1^2}{2}+\int_0^1 x\,dx\)'),
              MathText(r'\(\notacommand{a}\)'),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text(r'\(\notacommand{a}\)'), findsOneWidget);
  });
  testWidgets('hints progress before explicit collapsed solution', (
    tester,
  ) async {
    var exposed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MathLearningPanel(
              state: {
                'core': [
                  {'core_id': 'c', 'title': '오류 위치'},
                ],
                'hints': [
                  for (final l in [1, 2])
                    {'core_id': 'c', 'level': l, 'can_reveal': true},
                ],
                'solutions': [
                  {'reveal_state': 'AVAILABLE_ON_EXPLICIT_REQUEST'},
                ],
              },
              revealHint: (h) async => '힌트 ${h['level']}',
              revealSolution: (s) async {
                exposed++;
                return {
                  'body': '참고 풀이 본문',
                  'provenance': 'AI_GENERATED_REFERENCE',
                };
              },
              onRewrite: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('3단계 · 해결 방향'), findsNothing);
    expect(exposed, 0);
    await tester.tap(find.text('2단계 · 개념 힌트'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('3단계 · 해결 방향'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수정 풀이 비교 준비'));
    await tester.pumpAndSettle();
    expect(exposed, 0);
    await tester.tap(find.text('참고 풀이 확인'));
    await tester.pumpAndSettle();
    expect(exposed, 1);
    expect(find.text('참고 풀이 본문'), findsNothing);
  });
}
