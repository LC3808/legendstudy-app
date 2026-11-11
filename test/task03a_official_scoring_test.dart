import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';

void main() {
  final data = jsonDecode(
    File('data/mock_expansion/task03a/verified_papers.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final papers = (data['papers'] as List).cast<Map<String, dynamic>>();
  for (final p in papers) {
    final name =
        '${p['academic_year']}/${p['exam_month']} ${p['subject_label']} ${p['paper_variant']}';
    test('$name official perfect/wrong/blank and READY contract', () {
      final qs = [
        for (final q in p['questions'] as List)
          <String, dynamic>{
            ...q as Map<String, dynamic>,
            'question_number': q['number'],
          },
      ];
      final perfect = [
        for (final q in qs)
          q['all_credit'] == true
              ? null
              : (q['accepted_answers'] as List).first as int,
      ];
      final wrong = [
        for (final q in qs)
          List.generate(
            q['answer_type'] == 'numeric' ? 1000 : 5,
            (i) => q['answer_type'] == 'numeric' ? i : i + 1,
          ).firstWhere((n) => !(q['accepted_answers'] as List).contains(n)),
      ];
      final compulsory = qs
          .where((q) => q['all_credit'] == true)
          .fold<int>(0, (n, q) => n + (q['points'] as int));
      for (final v in [
        (perfect, p['max_score'] as int),
        (wrong, compulsory),
        (List<int?>.filled(qs.length, null), compulsory),
      ]) {
        final result = scoreMixed(qs, v.$1);
        expect(result.rawScore, v.$2);
        expect(result.maxScore, p['max_score']);
        expect(result.grade, isNull);
        expect(result.gradeLabel, '등급 산출 불가');
        expect(result.answers.length, p['question_count']);
        for (var i = 0; i < qs.length; i++) {
          expect(result.answers[i].questionId, qs[i]['question_id']);
          expect(
            result.answers[i].isCorrect,
            qs[i]['all_credit'] == true ||
                (qs[i]['accepted_answers'] as List).contains(v.$1[i]),
          );
        }
      }
      final available = <String, dynamic>{
        'exam_subject_id': p['exam_subject_id'],
        'paper_variant': p['paper_variant'],
        'answer_key_version_id': 'isolated-test-key',
        'answer_key_version': 1,
        'question_count': p['question_count'],
        'max_score': p['max_score'],
        'grade_status': 'unavailable',
        'scoring_version': 'mixed-v2',
        'verification_status': 'READY',
        'availability': 'scoring_available',
      };
      expect(MockScoringAvailability.fromJson(available).available, isTrue);
      for (final status in ['PARTIAL', 'NOT_READY']) {
        expect(
          () => MockScoringAvailability.fromJson({
            ...available,
            'verification_status': status,
          }),
          throwsFormatException,
        );
      }
    });
  }
}
