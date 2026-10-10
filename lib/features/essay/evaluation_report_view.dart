import 'package:flutter/material.dart';

import 'evaluation_report.dart';

class EvaluationReportView extends StatelessWidget {
  const EvaluationReportView({required this.report, this.before, super.key});
  final EvaluationReport report;
  final EvaluationReport? before;
  @override
  Widget build(BuildContext context) {
    final changes = before == null
        ? null
        : compareEvaluationReports(before!, report);
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
    List<Widget> feedback(String title, List<EvaluationFeedback> items) => [
      heading(title),
      if (items.isEmpty) const Text('이 기록에는 해당 피드백이 저장되어 있지 않습니다.'),
      for (final f in items)
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.title, style: Theme.of(context).textTheme.titleSmall),
              SelectableText(f.explanation),
              if (f.evidence.isNotEmpty) SelectableText('답안 근거\n${f.evidence}'),
              if (f.action.isNotEmpty) SelectableText('이렇게 고쳐보세요\n${f.action}'),
            ],
          ),
        ),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (report.question.isNotEmpty) ...[
          heading('문제'),
          SelectableText(report.question),
        ],
        heading('제출 답안'),
        SelectableText(
          report.answer.isEmpty ? '첨부 답안 · 비공개 보관' : report.answer,
        ),
        heading('종합 평가'),
        SelectableText(
          report.summary.isEmpty ? '종합 평가가 저장되어 있지 않습니다.' : report.summary,
        ),
        heading('평가 기준별 분석'),
        for (final c in report.rubric)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.name),
                Semantics(
                  label: c.rating == null ? null : '5단계 중 ${c.rating}단계',
                  child: Text(c.display),
                ),
                if (c.feedback.isNotEmpty) SelectableText(c.feedback),
              ],
            ),
          ),
        if (report.rubric.any((c) => c.rating != null))
          const Text(
            '별은 저장된 1~5단계 평가를 그대로 표시합니다. 대학의 공식 점수나 합격 가능성을 뜻하지 않습니다.',
          ),
        ...feedback('잘한 점', report.strengths),
        ...feedback('보완할 점과 이유', report.weaknesses),
        heading('구체적인 개선 방법'),
        if (report.actions.isEmpty)
          const Text('이 기록에는 구체적인 개선 방법이 저장되어 있지 않습니다.'),
        for (final s in report.actions) SelectableText(s),
        heading('다음 답안에서 확인할 점'),
        if (report.nextSteps.isEmpty) const Text('별도의 다음 학습 방향은 저장되어 있지 않습니다.'),
        for (final s in report.nextSteps) SelectableText(s),
        heading('최초 첨삭과 재첨삭 비교'),
        if (before == null)
          const Text('재작성 후 다시 첨삭받으면 답안이 어떻게 달라졌는지 비교할 수 있어요.')
        else if (changes == null)
          const Text('평가 기준이 다르거나 비교에 필요한 정보가 없어 직접 비교하기 어렵습니다.')
        else ...[
          for (final c in changes)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${c.after.name}\n최초 ${c.before.display}\n재첨삭 ${c.after.display}\n${const {'IMPROVED': '향상', 'UNCHANGED': '동일', 'DECLINED': '하락', 'UNAVAILABLE': '비교 불가'}[c.direction]}',
              ),
            ),
          heading('성장 과정 요약'),
          Text(
            '${changes.where((c) => c.direction == 'IMPROVED').length}개 항목 향상 · ${changes.where((c) => c.direction == 'UNCHANGED').length}개 동일 · ${changes.where((c) => c.direction == 'DECLINED').length}개 하락 · ${changes.where((c) => c.direction == 'UNAVAILABLE').length}개 비교 불가',
          ),
          const Text(
            '동일한 문제·평가 기준의 결과만 비교합니다. 등급 변화만으로 어떤 수정이 변화의 원인인지 단정하지 않습니다.',
          ),
        ],
        if (before != null) ...[
          heading('최초 답안'),
          SelectableText(
            before!.answer.isEmpty ? '첨부 답안 · 비공개 보관' : before!.answer,
          ),
          heading('최초 종합 평가'),
          SelectableText(before!.summary),
        ],
      ],
    );
  }
}
