import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/evaluation_presentation.dart';
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
    expect(sections.keys, ['내 답안 한눈에 보기', '종합 평가', '잘한 점', '평가 항목별 진단', '보완할 점', '먼저 고쳐야 할 부분', '다시 쓸 때 확인할 것']);
    expect(sections['평가 항목별 진단'], contains('5단계 평가 중 3단계입니다.'));
    expect(sections['보완할 점'], '');
    final after = EvaluationReport(id:'b', priorId:'a', answer:'',question:'q', summary:'이번 종합',rubric:[EvaluationCriterion('c','논리','',4,'이번 근거')],strengths:[],weaknesses:[],actions:[],nextSteps:[],pins:['same']);
    final before = EvaluationReport(id:'a', answer:'',question:'q',summary:'이전 종합',rubric:r.rubric,strengths:[],weaknesses:[],actions:[],nextSteps:[],pins:['same']);
    final comparison = essaySpeechSections(after,before);
    expect(comparison.keys.first,'이번 답안의 변화 한눈에 보기');
    expect(comparison.values.first,contains('이전 3단계에서 이번 4단계로 상승했습니다'));
    expect(comparison.values.join(),isNot(contains('/5')));
    expect(evaluationChangeSentence(3,4),contains('한 단계 높아졌습니다'));
    expect(evaluationChangeSentence(2,4),contains('두 단계 높아졌습니다'));
    expect(evaluationChangeSentence(4,2),contains('두 단계 낮아졌습니다'));
    expect(evaluationChangeSentence(3,3),contains('동일한 평가 수준'));
    expect(evaluationChangeSentence(null,3),contains('비교할 수 없습니다'));

    expect(sections.values.join(), isNot(contains('private answer')));
  });
}
