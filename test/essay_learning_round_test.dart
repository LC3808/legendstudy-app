import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/shared_history.dart';
import 'package:legendstudy_app/features/essay/evaluation_report.dart';
import 'package:legendstudy_app/features/essay/growth_timeline.dart';

SharedEssayRecord record(
  String id,
  int day, {
  String? parent,
  String exam = 'exam',
  bool truncated = false,
  String state = 'completed',
}) => SharedEssayRecord(
  id: id,
  math: false,
  exam: true,
  at: DateTime.utc(2026, 10, day),
  rewrite: parent != null,
  examData: {
    'exam_id': exam,
    'question_ids': ['q'],
    'state': state,
    'parent_id': parent,
    if (truncated) '_historyTruncated': true,
  },
  evaluations: const [],
);
void main() {
  test(
    'paid independent third is learning third, failed requests excluded',
    () {
      final raw = [
        record('paid2', 3),
        record('first', 1),
        record('free', 2, parent: 'first'),
        record('failed', 2, state: 'failed'),
        record('other', 4, exam: 'other'),
      ];
      final rows = numberEssayLearningRounds(raw);
      expect(essayHistoryType(rows.first), '3차 첨삭');
      expect(essayHistoryType(rows[1]), '첫 첨삭');
      expect(essayHistoryType(rows[2]), '2차 첨삭');
      expect(rows.first.examData['parent_id'], isNull);
      expect(rows[2].examData['parent_id'], 'first');
      expect(rows[3].examData['learning_round'], isNull);
      expect(raw.first.examData.containsKey('learning_round'), false);
    },
  );
  test('truncated histories never assign false first rounds', () {
    final rows = numberEssayLearningRounds([
      record('a', 1, truncated: true),
      record('b', 2),
    ]);
    expect(rows.every((r) => r.examData['learning_round'] == null), true);
  });
  testWidgets(
    'three real rounds show full line timeline and decline; changed pins cannot connect',
    (tester) async {
      final fixture = jsonDecode(
        File('test/fixtures/exam-history-v1.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final first = examEvaluationReport(
        fixture['before'] as Map<String, dynamic>,
        'question',
      );
      final second = examEvaluationReport(
        fixture['after'] as Map<String, dynamic>,
        'question',
      );
      final paid = {
        ...fixture['before'] as Map<String, dynamic>,
        'id': 'paid-third',
        'parent_id': null,
      };
      final third = examEvaluationReport(paid, 'question');
      expect(compareEvaluationReports(second, third), isNull);
      expect(
        compareEvaluationReports(second, third, requireLineage: false),
        isNotNull,
      );
      final changed = jsonDecode(jsonEncode(paid)) as Map<String, dynamic>;
      changed['result']['questions'][0]['rubricVersion'] = 'changed';
      expect(
        compareEvaluationReports(
          second,
          examEvaluationReport(changed, 'question'),
          requireLineage: false,
        ),
        isNull,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GrowthTimeline(reports: [first, second, third])),
        ),
      );
      expect(find.textContaining('3회:'), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
