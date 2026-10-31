import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'approved_result_adapter.dart';
import 'evaluation_report.dart';
import 'growth_bars.dart';
import 'result_disclosure.dart';
import 'essay_sentence_review.dart';
import 'essay_models.dart';

/// A view of stored judgments, never a new evaluation or a rubric summarizer.
String studentCriterionName(String name, int index) =>
    reviewedCriterionAlias(name) ?? '평가 항목 ${index + 1}';

List<String> distinctFeedback(Iterable<String> values) =>
    values.where((s) => s.trim().isNotEmpty).toSet().toList();

class StudentFeedbackView extends StatelessWidget {
  const StudentFeedbackView({
    super.key,
    required this.report,
    this.before,
    this.header,
    this.actions,
    this.voice,
    this.rewrite,
    this.comparison,
  });
  final EvaluationReport report;
  final EvaluationReport? before;
  final Widget? header, actions, rewrite, comparison, voice;

  Widget text(String value) => SelectableText(
    value,
    textAlign: TextAlign.left,
    style: AppTokens.body.copyWith(height: 1.7),
  );
  Widget card(String title, List<Widget> children, {Color? color}) => Container(
    margin: const EdgeInsets.only(bottom: 24),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFDCE3EC)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AppTokens.cardTitle),
        const SizedBox(height: 12),
        ...children,
      ],
    ),
  );
  List<Widget> paragraphs(Iterable<String> values) => [
    for (final value in distinctFeedback(values))
      Padding(padding: const EdgeInsets.only(bottom: 12), child: text(value)),
  ];
  Widget feedback(
    String title,
    List<EvaluationFeedback> items,
    Color color,
  ) => card(
    title,
    items.isEmpty
        ? [text('이 기록에는 해당 피드백이 저장되어 있지 않습니다.')]
        : [
            for (final (index, f) in items.indexed) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${index + 1}. ${f.title.isEmpty || f.title == title ? title : f.title}',
                  style: AppTokens.cardTitle,
                ),
              ),
              ...paragraphs([f.explanation]),
              if (f.evidence.isNotEmpty && report.answer.contains(f.evidence))
                card('학생이 작성한 글', [
                  text(f.evidence),
                ], color: const Color(0xFFF2F4F6)),
              if (f.action.isNotEmpty)
                card('개선 방법', [text(f.action)], color: const Color(0xFFFFF5E4)),
              const SizedBox(height: 8),
            ],
          ],
    color: color,
  );

  @override
  Widget build(BuildContext context) {
    final changes = before == null
        ? null
        : compareEvaluationReports(before!, report);
    final linkedActions = report.weaknesses.map((f) => f.action).toSet();
    final extraActions = distinctFeedback(report.actions)
        .where((a) => !linkedActions.contains(a));
    final checklist = distinctFeedback(
      report.nextSteps,
    ).where((a) => !linkedActions.contains(a) && !report.actions.contains(a));
    return SingleChildScrollView(
      key: ValueKey(report.id),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (header != null) header!,
              card('종합 평가', [
                text(
                  report.summary.isEmpty ? '저장된 종합 평가가 없습니다.' : report.summary,
                ),
              ]),
              if (voice != null) ...[voice!, const SizedBox(height: 24)],
              card('높은 평가를 위한 작성 가이드', [
                text(
                  '이 문항에 저장된 수정 방향과 확인 항목입니다. 보완 사유와 연결된 개선 방법은 아래에서 확인하세요.',
                ),
                const SizedBox(height: 12),
                if (report.actions.isNotEmpty) ...[
                  const Text('우선 개선 과제', style: AppTokens.cardTitle),
                  // Linked actions have one full rendering in the issue card below.
                  for (final f in report.weaknesses.where(
                    (f) => report.actions.contains(f.action),
                  ))
                    text(
                      '${f.title.isEmpty ? '보완할 점' : f.title} · 아래 개선 방법 확인',
                    ),
                  ...paragraphs(extraActions),
                ],
                if (checklist.isNotEmpty) ...[
                  const Text('다시 쓸 때 확인할 것', style: AppTokens.cardTitle),
                  ...paragraphs(checklist),
                ],
                text(
                  '이 기록에는 별도로 검증된 높은 평가의 핵심 조건과 추천 답안 전개 순서가 없습니다. 저장된 피드백만 안내합니다.',
                ),
              ], color: const Color(0xFFFFF8EC)),
              feedback('잘한 점', report.strengths, const Color(0xFFF1F8F4)),
              feedback(
                '보완할 점과 개선 방법',
                report.weaknesses,
                const Color(0xFFFCF3F3),
              ),
              EssaySentenceSection(
                review: report.sentenceReview,
                evaluationId: report.id,
                attemptId: report.sentenceReview?.attemptId,
                submittedAnswer: report.answer,
              ),
              ResultAccordion(
                title: '평가 항목별 설명과 단계',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < report.rubric.length; i++) ...[
                      Text(
                        studentCriterionName(report.rubric[i].name, i),
                        style: AppTokens.cardTitle,
                      ),
                      text(
                        '${report.rubric[i].display}${report.rubric[i].rating == null ? '' : ' · ${report.rubric[i].rating}/5단계'}',
                      ),
                      ...paragraphs(
                        studentCriterionFeedback(report, report.rubric[i]),
                      ),
                    ],
                    text('저장된 평가 단계이며 대학의 공식 점수나 종합 점수가 아닙니다.'),
                  ],
                ),
              ),
              if (before != null)
                ResultAccordion(
                  title: '재첨삭 성장 비교',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (changes == null)
                        text('평가 조건이 달라 직접 비교하기 어려워요.')
                      else ...[
                        GrowthBars(
                          before: before!,
                          after: report,
                          studentLabels: true,
                        ),
                        const Text(
                          '이전 첨삭에서 지적된 부분',
                          style: AppTokens.cardTitle,
                        ),
                        ...paragraphs(
                          before!.weaknesses.map((f) => f.explanation),
                        ),
                        const Text(
                          '이번 평가에서 확인한 변화',
                          style: AppTokens.cardTitle,
                        ),
                        ...paragraphs(
                          report.previousReviews.map(
                            (r) => evaluationText(r['reason']),
                          ),
                        ),
                        if (report.previousReviews.isEmpty)
                          text('별도의 개선 여부 설명이 저장되어 있지 않습니다.'),
                        text(
                          '평가 단계 변화만으로 글쓰기 문제의 해결을 판단하지 않습니다. 남은 과제는 위 보완할 점을 확인하세요.',
                        ),
                      ],
                    ],
                  ),
                ),
              if (comparison != null) comparison!,
              if (actions != null) ...[actions!, const SizedBox(height: 24)],
              card('다시 써보기', [
                text('이번 첨삭에서 확인한 개선 방향을 적용해 답안을 다시 작성해 보세요.'),
                const SizedBox(height: 12),
                if (rewrite != null)
                  rewrite!
                else
                  text('이 기록에서 재작성 가능한 경로가 제공되지 않았습니다.'),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Legacy live workspace already holds a validated stored evaluation. Do not
/// invent pins, a parent report, new scores or missing guide fields.
EvaluationReport studentWorkspaceReport(
  EssayEvaluation e,
  String answer,
  String id,
  EssaySentenceReview? sentences,
) => EvaluationReport(
  id: id,
  answer: answer,
  question: '',
  summary: e.summary,
  rubric: [
    for (final d in e.dimensions)
      EvaluationCriterion(
        d.key,
        d.officialCriterion ?? d.label,
        '',
        d.level,
        d.explanation,
      ),
  ],
  strengths: [for (final s in e.strengths) EvaluationFeedback('', s, '', '')],
  weaknesses: [
    for (final s in e.improvements) EvaluationFeedback('', s, '', ''),
  ],
  actions: e.priorities,
  nextSteps: e.checklist,
  pins: const [],
  sentenceReview: sentences,
);

List<String> studentCriterionFeedback(
  EvaluationReport report,
  EvaluationCriterion c,
) {
  final prefix = '${c.name} — ';
  final values = distinctFeedback([
    c.feedback,
    ...report.evidenceLabels
        .where((e) => e.startsWith(prefix))
        .map((e) => e.substring(prefix.length)),
  ]);
  return values.isEmpty ? ['상세 평가 설명이 제공되지 않았습니다.'] : values;
}

class StudentWorkspaceComparison extends StatelessWidget {
  const StudentWorkspaceComparison(this.evaluation, {super.key});
  final EssayEvaluation evaluation;
  @override
  Widget build(BuildContext context) => ResultAccordion(
    title: '재첨삭 성장 비교',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!evaluation.comparable)
          const Text('평가 조건이 달라 직접 비교하기 어려워요.')
        else ...[
          for (var i = 0; i < evaluation.dimensions.length; i++) ...[
            Text(
              studentCriterionName(evaluation.dimensions[i].label, i),
              style: AppTokens.cardTitle,
            ),
            Text(
              '이전 ${evaluation.dimensions[i].previousLevel ?? "정보 없음"} → 최근 ${evaluation.dimensions[i].level ?? "정보 없음"}',
            ),
            Text(evaluation.dimensions[i].explanation),
          ],
          for (final entry in evaluation.changes.entries) ...[
            Text(entry.key, style: AppTokens.cardTitle),
            for (final value in entry.value) Text(value),
          ],
          const Text('평가 단계 변화만으로 글쓰기 문제의 해결을 판단하지 않습니다.'),
        ],
      ],
    ),
  );
}
