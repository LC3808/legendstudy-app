import 'package:flutter/material.dart';

import 'evaluation_report.dart';
import 'student_feedback.dart';
import 'result_disclosure.dart';
import 'result_pdf.dart';
import 'essay_voice.dart';
import 'growth_share.dart';

class EvaluationReportView extends StatelessWidget {
  const EvaluationReportView({required this.report, this.before, super.key});
  final EvaluationReport report;
  final EvaluationReport? before;
  @override
  Widget build(BuildContext context) => StudentFeedbackView(
    report: report,
    before: before,
    header: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (report.question.isNotEmpty) Text(report.question),
        ResultAccordion(
          title: '제출 답안',
          child: SelectableText(
            report.answer.isEmpty ? '첨부 답안 · 비공개 보관' : report.answer,
          ),
        ),
        if (before != null)
          ResultAccordion(
            title: '비교 대상 · 이전 제출 답안',
            child: SelectableText(before!.answer),
          ),
      ],
    ),
    voice: EssayVoice(report: report, before: before),
    actions: Column(
      children: [
        ResultPdfButton(report: report),
        OutlinedButton(
          onPressed: () => showGrowthShare(
            context,
            completed: 1,
            rewrites: before == null ? 0 : 1,
            report: report,
            before: before,
          ),
          child: const Text('성장 기록 공유'),
        ),
      ],
    ),
  );
}
