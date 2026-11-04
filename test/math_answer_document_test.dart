import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/math_text.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_coaching_screen.dart';
import 'package:legendstudy_app/features/essay/math_mobile/academic_purple.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_answer_evidence.dart';

void main() {
  test(
    'layout is lossless around signs, exponents, paragraphs, TeX and tables',
    () {
      const source = r'''문제 1
r = -1/6
x_1^2 = 3/4

(i) a > 0, r < 0일 때
\[
\begin{aligned}
a &= -1 \\
b &= \frac{2}{3}
\end{aligned}
\]
조건에 맞지 않으므로 모순이다.
x | 1 | 2
P(X=x) | 1/3 | 2/3
원문 끝''';
      final blocks = mathAnswerBlocks(source);
      expect(blocks.join(), source);
      expect(
        blocks.any(
          (b) => b.contains('begin{aligned}') && b.contains('end{aligned}'),
        ),
        isTrue,
      );
      expect(
        blocks.any((b) => b.contains('x | 1') && b.contains('P(X=x)')),
        isTrue,
      );
      expect(mathAnswerBlocks('r = -1/6\nx_1^2 = 3/4').length, 2);
      const malformed = '앞 문단\n\\[x^2\n판독 불명';
      expect(mathAnswerBlocks(malformed).join(), malformed);
    },
  );
  test('sentence boundaries preserve decimals and explicit math source', () {
    const source = r'값은 $x = 1.25$이다. 다음은 조건이다. (1-2) u = t^4이라 하자.';
    final blocks = mathAnswerBlocks(source);
    expect(blocks.join(), source);
    expect(blocks.length, 3);
    expect(blocks.first, contains(r'$x = 1.25$'));
    expect(blocks.last, startsWith('(1-2)'));
    const formula = r'\[\text{이다. 다음} + 1.25\]';
    expect(mathAnswerBlocks(formula), [formula]);
  });
  testWidgets('subquestion labels remain prose rather than subtraction', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MathStudentText('(1-2) u = t^4이라 하고')),
      ),
    );
    expect(find.text('(1-2) '), findsOneWidget);
    expect(t.takeException(), isNull);
  });
  testWidgets('revealed generated solution is visible with explicit AI label', (
    t,
  ) async {
    await t.pumpWidget(
      const MaterialApp(
        home: MathSolutionPage(
          solution: {
            'generated_solution': {
              'origin': 'AI_GENERATED',
              'body': r'확인된 풀이 \(x=2\)',
            },
            'references': <Map<String, dynamic>>[],
            'steps': <Map<String, dynamic>>[],
            'paths': <Map<String, dynamic>>[],
          },
        ),
      ),
    );
    expect(find.text('AI 생성 참고 해설 · 공식 예시답안 아님'), findsOneWidget);
    expect(find.byType(Math), findsOneWidget);
    expect(find.text('공식 예시답안'), findsNothing);
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'supplemental official solution preserves provenance and indexed roots',
    (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: MathSolutionPage(
            solution: {
              'references': [
                {
                  'origin': 'OFFICIAL',
                  'relationship': 'SUPPLEMENTAL_AFTER_ASSESSMENT',
                  'source_locator': '공식 문항카드 3쪽 · 예시답안',
                  'body': r'(1-2) 치환과 최솟값 \(T(u)=S(\sqrt[4]{u})\)',
                },
              ],
              'steps': <Map<String, dynamic>>[],
            },
          ),
        ),
      );
      expect(find.text('공식 예시답안'), findsOneWidget);
      expect(find.text('추가 연결 공식 자료 · 평가 당시 참고자료와 구분'), findsOneWidget);
      expect(find.text('공식 문항카드 3쪽 · 예시답안'), findsOneWidget);
      expect(find.byType(Math), findsOneWidget);
      expect(find.text('수식 표시 오류 · 원문'), findsNothing);
      expect(t.takeException(), isNull);
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'multiline formula, table and full evidence remain reachable at $scale',
      (t) async {
        await t.binding.setSurfaceSize(const Size(393, 852));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final text =
            '문제 1\n${List.generate(15, (i) => 'x_${i + 1} = -${i + 1}/6').join('\n')}\n'
            'x | 1 | 2\nP(X=x) | 1/3 | 2/3\n최종 문장도 그대로 보존';
        await t.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: MathMobileTheme(
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          MathAnswerEvidence(text),
                          const Text('우선 개선할 부분'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(t.takeException(), isNull);
        expect(find.byType(Math), findsNWidgets(16));
        // Each original formula owns a row, instead of a single collapsed equation.
        final formulas = find.byType(Math).evaluate().toList();
        expect(
          t.getTopLeft(find.byWidget(formulas[1].widget)).dy,
          greaterThan(t.getBottomLeft(find.byWidget(formulas[0].widget)).dy),
        );
        expect(find.byType(Table), findsOneWidget);
        await t.tap(find.text('답안 근거 전체 보기'));
        await t.pumpAndSettle();
        await t.scrollUntilVisible(
          find.text('답안 근거 접기'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('최종 문장도 그대로 보존').hitTestable(), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.tap(find.text('답안 근거 접기'));
        await t.pumpAndSettle();
        expect(find.text('우선 개선할 부분').hitTestable(), findsOneWidget);
      },
    );
  }
}
