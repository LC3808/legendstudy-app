import 'evaluation_presentation.dart';
import 'essay_models.dart';
import 'evaluation_report.dart';

// Display only: immutable source labels and stored evaluations remain untouched.
String readableEssayText(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();
String withoutUnverifiedWeight(String value) =>
    value.replaceAll(RegExp(r'\(?\s*\d+(?:\.\d+)?\s*%\s*\)?'), '').trim();
String? reviewedCriterionAlias(String value) {
  final text = readableEssayText(withoutUnverifiedWeight(value));
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
  return null;
}

String shortCriterionTitle(String value) {
  final alias = reviewedCriterionAlias(value);
  if (alias != null) return alias;
  final text = readableEssayText(withoutUnverifiedWeight(value));
  return text.runes.length > 38
      ? '${String.fromCharCodes(text.runes.take(38))}…'
      : text;
}

bool isRubricTable(String text) =>
    RegExp(r'(채점\s*기준|평가\s*기준)[\s\S]*배점').hasMatch(text);

String resultCriterionTitle(String name, {required int criterionCount}) =>
    reviewedCriterionAlias(name) ??
    (criterionCount == 1 && isRubricTable(name)
        ? '문항별 채점기준'
        : shortCriterionTitle(name));

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
  ].where((s) => s.isNotEmpty).join('\n\n');
  return EssayEvaluation(
    summary: report.summary,
    strengths: report.strengths.map(feedback).toList(),
    dimensions: [
      for (final c in report.rubric)
        EssayDimension(
          c.id,
          resultCriterionTitle(c.name, criterionCount: report.rubric.length),
          c.rating,
          c.feedback,
          officialCriterion: c.name,
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
            '평가 기준\n${resultCriterionTitle(c.after.name, criterionCount: report.rubric.length)}\n\n평가 변화\n${evaluationChangeSentence(c.before.rating, c.after.rating)}\n\n평가 설명\n${c.after.feedback}',
        ],
      if (changes != null)
        '유지한 부분': [
          for (final c in changes.where((x) => x.direction == 'UNCHANGED'))
            shortCriterionTitle(c.after.name),
        ],
      if (changes != null)
        '아직 확인할 부분': [
          for (final c in changes.where((x) => x.direction == 'DECLINED'))
            '평가 기준\n${resultCriterionTitle(c.after.name, criterionCount: report.rubric.length)}\n\n평가 변화\n${evaluationChangeSentence(c.before.rating, c.after.rating)}\n\n평가 설명\n${c.after.feedback}',
        ],
    },
  );
}
