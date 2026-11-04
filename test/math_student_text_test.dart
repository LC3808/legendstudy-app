import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/math_text.dart';

void main() {
  test(
    'explicit indexed roots match WEB without inventing operand boundaries',
    () {
      expect(displayMathSource('1/⁴√3'), r'1/\sqrt[4]{3}');
      expect(displayMathSource('√[4]{u}'), r'\sqrt[4]{u}');
      expect(displayMathSource('x⁴√3'), r'x⁴\sqrt{3}');
      expect(displayMathSource('√[4]'), '√[4]');
      expect(displayMathSource('⁴√{x+1}'), r'\sqrt[4]{x+1}');
    },
  );
  testWidgets('invalid formula has visible warning and unchanged source', (
    tester,
  ) async {
    const source = r'\[\frac{1}{\]';
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MathText(source))),
    );
    expect(find.text('수식 표시 오류 · 원문'), findsOneWidget);
    expect(find.text(source), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'rectangular source table preserves values; malformed rows stay source',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathStudentText(
              '| 구분 | 값 |\n| --- | --- |\n| 표본 | -0.25 |\n| 확률 | 1/2 |',
            ),
          ),
        ),
      );
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('-0.25'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MathStudentText(
              '확률분포\nk/l | 1 | 1/2\nP(W=k/l) | 1/4 | 19/140\nE(W)=69/56',
            ),
          ),
        ),
      );
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('19/140'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: MathStudentText('|\n|'))),
      );
      expect(find.byType(Table), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'confirmed prose and multiline source are never forced into a formula',
    (tester) async {
      for (final source in [
        '조건을 확인한 뒤 계산한다.\nx = 2',
        r'함수 $f(x)$의 조건을 확인한다.',
        'A valid alternative proof',
        'Assume x=2 and verify the condition',
      ]) {
        await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: MathStudentText(source))),
        );
        expect(
          tester
              .widgetList<MathText>(find.byType(MathText))
              .map(
                (part) => part.text.replaceAll(r'\[', '').replaceAll(r'\]', ''),
              )
              .join('\n'),
          source,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets('isolated TeX renders and existing delimiters are not nested', (
    tester,
  ) async {
    for (final source in [r'\frac{x^2}{2}=1', r'\[x^2=2\]']) {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: MathStudentText(source))),
      );
      expect(
        tester.widget<MathText>(find.byType(MathText)).text,
        source.startsWith(r'\[') ? source : r'\[' + source + r'\]',
      );
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('Hanyang formulas and long matrix preserve a narrow viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final source in [
      r'\frac{\sqrt{2}e^{\pi/4}}{2(e^\pi-1)}',
      r'\int_0^\alpha (x^2-11x+18)\,dx',
      r'\bar{x}-2.5\frac{2}{\sqrt n}\le m\le\bar{x}+2.5\frac{2}{\sqrt n}',
      'b-a=10/√n, d-c=6/√n',
      'f(t)=t⁴-1, f′(t)=4t³',
      'f′(-2)=-32.',
      '1<10/√n, 6/√n<6/5',
      r'\begin{pmatrix}x_1^2&x_2^2&x_3^2&x_4^2&x_5^2&x_6^2\\1&2&3&4&5&6\end{pmatrix}',
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 280, child: MathText(r'\[' + source + r'\]')),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<MathText>(find.byType(MathText)).text,
        r'\[' + source + r'\]',
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is SingleChildScrollView &&
              w.scrollDirection == Axis.horizontal,
        ),
        findsOneWidget,
      );
      // Rendering failure must not silently count as formula success.
      expect(find.text(r'\[' + source + r'\]'), findsNothing);
    }
  });
}
