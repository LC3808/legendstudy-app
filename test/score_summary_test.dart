import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/lab/score_summary.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';

import 'support/grade_fixture.dart';

void main() {
  test(
    'missing snapshot has no invented trend',
    () => expect(mockScoreComment([]), '분석할 성적이 아직 부족해요.'),
  );
  test(
    'empty score is not invented',
    () => expect(mockScoreSummary([]), contains('성적을 입력해 주세요.')),
  );
  for (final status in ['confirmed', 'estimated', 'unavailable']) {
    test('real raw score and grade provenance $status retained', () {
      final choices = List<int?>.filled(100, 1);
      final result = gradeResult(status, choices);
      final attempt = ScoringAttempt(
        id: 'offline',
        title: '시험',
        draft: gradeDraft(status, choices),
        result: result,
        outcome: ScoringOutcome.complete,
      );
      expect(
        mockScoreSummary([attempt]),
        contains('${result.rawScore}/${result.maxScore}점'),
      );
      expect(mockScoreSummary([attempt]), contains(result.gradeLabel));
      expect(
        mockScoreComment([attempt]),
        '최근 결과는 100문항 중 ${result.answers.where((a) => a.isCorrect).length}문항 정답이에요.',
      );
    });
  }
}
