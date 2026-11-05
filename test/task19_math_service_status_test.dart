import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';

void main() {
  const exam = '25dc068b-4672-56e1-b8df-08ee8800e2f6';
  final rows = <Map<String, dynamic>>[
    {
      'essay_exam_id': exam,
      'essay_question_id': 'q1',
      'leaf_id': '22222222-2222-4222-8222-222222222222',
    },
  ];
  test('Konkuk standalone release matches exact question, not track name', () {
    expect(hasReleasedMathQuestion(rows, exam, ['q1']), isTrue);
    expect(hasReleasedMathQuestion(rows, exam, ['q2']), isFalse);
    expect(hasReleasedMathQuestion(rows, 'other', ['q1']), isFalse);
    expect(hasReleasedMathQuestion([], exam, ['q1']), isFalse);
    expect(hasReleasedMathQuestion([...rows, ...rows], exam, ['q1']), isFalse);
    expect(
      hasReleasedMathQuestion(
        [
          {...rows.single, 'leaf_id': ''},
        ],
        exam,
        ['q1'],
      ),
      isFalse,
    );
  });
}
