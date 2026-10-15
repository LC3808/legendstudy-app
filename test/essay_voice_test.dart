import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/essay_voice.dart';
import 'package:legendstudy_app/features/essay/evaluation_report.dart';

void main() {
  test('native speech uses only stored section titles, levels and text', () {
    const r = EvaluationReport(
      id: 'a',
      answer: 'private answer not spoken automatically',
      question: 'q',
      summary: '저장된 종합평가',
      rubric: [EvaluationCriterion('c', '논리', '', 3, '저장된 근거')],
      strengths: [],
      weaknesses: [],
      actions: ['한 문장 추가'],
      nextSteps: [],
      pins: [],
    );
    final sections = essaySpeechSections(r);
    expect(sections.keys, ['종합 평가', '평가요소별 결과', '잘한 점', '보완할 점', '수정 방향 안내']);
    expect(sections['평가요소별 결과'], contains('평가 단계 3/5'));
    expect(sections['보완할 점'], '');
    expect(sections.values.join(), isNot(contains('private answer')));
  });
}
