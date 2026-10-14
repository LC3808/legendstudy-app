import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/evaluation_report.dart';

void main() {
  test('same stored exam result and rewrite use existing Native report', () {
    final data = jsonDecode(
      File('test/fixtures/exam-history-v1.json').readAsStringSync(),
    ) as Map;
    final before = examEvaluationReport(
      Map<String, dynamic>.from(data['before'] as Map),
      'question',
    );
    final after = examEvaluationReport(
      Map<String, dynamic>.from(data['after'] as Map),
      'question',
    );
    expect(after.priorId, before.id);
    expect(after.answer, 'Rewritten answer');
    expect(after.rubric.first.name, 'Reasoning');
    expect(after.rubric.first.rating, 3);
    expect(after.actions, ['Add reason']);
    expect(
      compareEvaluationReports(before, after)?.first.direction,
      'IMPROVED',
    );
  });
}
