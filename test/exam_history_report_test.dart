import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/evaluation_report.dart';

void main() {
  test('saved evidence references retain exact criterion judgment without invented sources', () {
    final f = jsonDecode(
      File('test/fixtures/exam-history-v1.json').readAsStringSync(),
    ) as Map;
    final run = Map<String, dynamic>.from(f['before'] as Map);
    final d =
        run['result']['questions'][0]['evaluation']['dimensions'][0] as Map;
    d['evidence_ids'] = ['e1', 'e1', 'e2'];
    expect(examEvaluationReport(run, 'question').evidenceLabels, [
      'Reasoning — Needs connection',
    ]);
    d['criterion_id'] = 'unknown';
    expect(examEvaluationReport(run, 'question').evidenceLabels, isEmpty);
    d['criterion_id'] = 'criterion';
    d['evidence_ids'] = <String>[];
    expect(examEvaluationReport(run, 'question').evidenceLabels, isEmpty);
  });

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
