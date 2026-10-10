import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/evaluation_report.dart';
import 'package:legendstudy_app/features/essay/evaluation_report_view.dart';

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/evaluation-display-v1.json').readAsStringSync(),
  ) as Map;
  for (final row in fixture['ratings'] as List) {
    test(
      'shared rating ${row['raw']}',
      () => expect(evaluationRating(row['raw']), row['expected']),
    );
  }
  for (final row in fixture['math'] as List) {
    test('shared comparison ${row['name']}', () {
      final before = mathEvaluationReport(row['before']),
          after = mathEvaluationReport(row['after']);
      final changes = compareEvaluationReports(before, after);
      expect(changes?.first.direction, row['expected']);
      expect(before.rubric.first.rating, isNull);
      expect(before.strengths.first.evidence, 'x=2');
      expect(before.summary, '답을 정확하게 구했고, 풀이 근거도 충분히 설명했어요.');
    });
  }
  for (final row in fixture['human'] as List) {
    test('shared human ${row['name']}', () {
      final before = humanEvaluationReport(row['before']),
          after = humanEvaluationReport(row['after'], priorId: before.id);
      expect(
        compareEvaluationReports(before, after)?.first.direction,
        row['expected'],
      );
      expect(before.rubric.first.rating, 2);
      expect(after.rubric.first.rating, 3);
    });
  }
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('native report ${platform.name} at 360px and text 200%', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final row = (fixture['math'] as List).first;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Scaffold(
              body: EvaluationReportView(
                report: mathEvaluationReport(row['after']),
                before: mathEvaluationReport(row['before']),
              ),
            ),
          ),
        ),
      );
      expect(find.text('종합 평가'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(ListView), const Offset(0, -1800));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
