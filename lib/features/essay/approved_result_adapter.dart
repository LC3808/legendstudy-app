import 'essay_models.dart';
import 'evaluation_report.dart';

// Display only: immutable source labels and stored evaluations remain untouched.
String readableEssayText(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();
String shortCriterionTitle(String value) {
  final text = readableEssayText(value);
  final compact = String.fromCharCodes(text.runes.take(35)).replaceAll(' ', '');
  for (final pair in const [
    ('구성과전개', '구성과 전개'),
    ('사회계약론', '사회계약론 이해'),
    ('공리주의', '공리주의 이해와 평가'),
    ('미래세대', '미래 세대의 도덕적 의무'),
    ('문장과표현', '문장과 표현'),
  ]) {
    if (compact.contains(pair.$1)) return pair.$2;
  }
  return text.runes.length > 38
      ? '${String.fromCharCodes(text.runes.take(38))}…'
      : text;
}

EssayEvaluation approvedEssayEvaluation(
  EvaluationReport report,
  EvaluationReport? before,
) {
  final changes = before == null
      ? null
      : compareEvaluationReports(before, report);
  String feedback(EvaluationFeedback f) => [
    f.explanation,
    if (f.evidence.isNotEmpty) '답안 근거: ${f.evidence}',
    if (f.action.isNotEmpty) '개선 방법: ${f.action}',
  ].where((s) => s.isNotEmpty).join('\n');
  return EssayEvaluation(
    summary: report.summary,
    strengths: report.strengths.map(feedback).toList(),
    dimensions: [
      for (final c in report.rubric)
        EssayDimension(
          c.id,
          shortCriterionTitle(c.name),
          c.rating,
          '${readableEssayText(c.name)}\n\n${c.feedback}',
          previousLevel: changes
              ?.where((x) => x.after.id == c.id)
              .firstOrNull
              ?.before
              .rating,
        ),
    ],
    improvements: report.weaknesses.map(feedback).toList(),
    priorities: report.actions,
    checklist: report.nextSteps,
    example: '',
    comparable: before == null || changes != null,
    changes: {
      '해결한 부분': [
        for (final r in report.previousReviews.where(
          (r) => r['outcome'] == 'resolved',
        ))
          evaluationText(r['reason']),
      ],
      if (changes != null)
        '좋아진 부분': [
          for (final c in changes.where((x) => x.direction == 'IMPROVED'))
            '${shortCriterionTitle(c.after.name)}: ${c.before.rating} → ${c.after.rating}',
        ],
      if (changes != null)
        '유지한 부분': [
          for (final c in changes.where((x) => x.direction == 'UNCHANGED'))
            shortCriterionTitle(c.after.name),
        ],
      if (changes != null)
        '아직 확인할 부분': [
          for (final c in changes.where((x) => x.direction == 'DECLINED'))
            '${shortCriterionTitle(c.after.name)}: ${c.before.rating} → ${c.after.rating}',
        ],
    },
  );
}
