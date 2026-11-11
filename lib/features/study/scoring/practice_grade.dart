import 'practice_grade_reference_data.dart';
import 'scoring_models.dart';

/// A current practice reference, not a mutation of the submitted score snapshot.
class PracticeGrade {
  const PracticeGrade({
    required this.best,
    required this.worst,
    required this.estimated,
    required this.method,
    required this.revision,
    required this.basis,
    required this.urls,
  });
  final int best, worst;
  final bool estimated;
  final String method, revision;
  final List<String> basis, urls;
  String get label =>
      '${estimated ? '추정 등급' : '예상 등급'} · '
      '${best == worst ? '$best' : '$best~$worst'}등급';

  static PracticeGrade? forAttempt(ScoringAttempt attempt) {
    final score = attempt.result;
    final a = attempt.draft.availability;
    if (score == null || !a.available || a.verificationStatus != 'READY') {
      return null;
    }
    final key =
        (practiceGradeReferenceData['keys'] as Map)[a.answerKeyVersionId];
    if (key is! Map ||
        key['exam_subject_id'] != a.examSubjectId ||
        key['variant'] != a.paperVariant ||
        key['key_version'] != a.answerKeyVersion ||
        key['max_score'] != score.maxScore ||
        key['question_count'] != score.answers.length) {
      return null;
    }
    final curve =
        (practiceGradeReferenceData['curves'] as Map)[key['curve']] as Map;
    return fromCurve(score.rawScore, score.maxScore, curve);
  }

  /// Every one of the eight grade boundaries is evidenced. Below grade 8 is 9.
  /// Bounds propagate to a grade interval rather than an arbitrary midpoint.
  static PracticeGrade? fromCurve(
    int raw,
    int max,
    Map<dynamic, dynamic> curve,
  ) {
    final rows = curve['bands'];
    if (raw < 0 || raw > max || rows is! List || rows.length != 8) return null;
    final low = <int>[], high = <int>[];
    for (final row in rows) {
      if (row is! List || row.length != 2) return null;
      final Object? lower = row[0], upper = row[1];
      if (lower is! int ||
          upper is! int ||
          lower < 0 ||
          lower > upper ||
          upper > max) {
        return null;
      }
      low.add(lower);
      high.add(upper);
    }
    for (var i = 1; i < 8; i++) {
      if (low[i] > low[i - 1] || high[i] > high[i - 1]) return null;
    }
    int grade(List<int> thresholds) {
      for (var i = 0; i < 8; i++) {
        if (raw >= thresholds[i]) return i + 1;
      }
      return 9;
    }

    return PracticeGrade(
      best: grade(low),
      worst: grade(high),
      estimated: curve['estimated'] as bool,
      method: curve['method'] as String,
      revision: curve['revision'] as String,
      basis: List<String>.from(curve['basis'] as List),
      urls: List<String>.from(curve['urls'] as List),
    );
  }
}
