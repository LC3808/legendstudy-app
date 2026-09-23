import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/lab/score_summary.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';

import 'support/grade_fixture.dart';

void main() {
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
    });
  }
}
