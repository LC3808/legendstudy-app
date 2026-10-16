import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/approved_result_adapter.dart';
import 'package:legendstudy_app/features/essay/essay_models.dart';
import 'package:legendstudy_app/features/essay/essay_pages.dart';
import 'package:legendstudy_app/features/essay/evaluation_report.dart';

void main() {
  final path = Platform.environment['ESSAY_QA_ADDITIONAL_RESULT_PATH'];
  testWidgets(
    'stored additional paid result renders without fabricating a free-rewrite comparison',
    (tester) async {
      final row =
          (jsonDecode(File(path!).readAsStringSync()) as List).last
              as Map<String, dynamic>;
      expect(row['submission_index'], 3);
      expect(row['previous_paid_run_id'], isNotNull);
      expect(row['parent_id'], isNull);
      expect(row['free_rewrite_available'], true);
      final q = row['answers'][0]['questionId'] as String;
      final report = examEvaluationReport(row, q);
      final evaluation = approvedEssayEvaluation(report, null);
      expect(evaluation.dimensions.length, 5);
      expect(evaluation.dimensions.every((d) => d.level == 4), true);
      tester.view.physicalSize = const Size(360, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 844),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: EssayResultView(
                evaluation: evaluation,
                question: EssayQuestion(
                  id: q,
                  university: '한양대학교',
                  exam: '2024학년도 수시 논술 · 인문계열 · 오후 2',
                  title: '문제 1',
                  prompt: '',
                  passages: const [],
                  origin: CriteriaOrigin.officialExam,
                ),
                comparison: false,
                isPreview: false,
                collapsedDetails: true,
                onRewrite: () {},
                submittedAnswer: report.answer,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('내 답안 한눈에 보기'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('다시 써보기'),
        700,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    },
    skip: path == null,
  );
}
