import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/math_text.dart';

void main() {
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
        expect(tester.widget<MathText>(find.byType(MathText)).text, source);
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
        source.startsWith(r'\[') ? source : '\\[$source\\]',
      );
      expect(tester.takeException(), isNull);
    }
  });
}
