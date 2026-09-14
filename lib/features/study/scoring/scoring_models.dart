enum ScoringAvailability { timerOnly, scoringAvailable }

enum ScoringOutcome { pending, stale, complete }

void scoringCheck(bool value) {
  if (!value) throw const FormatException('Invalid scoring contract');
}

class MockScoringAvailability {
  MockScoringAvailability.fromJson(Map<String, dynamic> j)
    : examSubjectId = j['exam_subject_id'] as String,
      paperVariant = j['paper_variant'] as String?,
      answerKeyVersionId = j['answer_key_version_id'] as String?,
      answerKeyVersion = j['answer_key_version'] as int?,
      questionCount = j['question_count'] as int?,
      maxScore = j['max_score'] as int?,
      gradeCutoffVersionId = j['grade_cutoff_version_id'] as String?,
      gradeStatus = j['grade_status'] as String,
      scoringVersion = j['scoring_version'] as String,
      availability = switch (j['availability']) {
        'timer_only' => ScoringAvailability.timerOnly,
        'scoring_available' => ScoringAvailability.scoringAvailable,
        _ => throw const FormatException('Invalid availability'),
      } {
    scoringCheck(examSubjectId.isNotEmpty && scoringVersion == 'mcq5-v1');
    if (available) {
      scoringCheck(
        answerKeyVersionId != null &&
            paperVariant != null &&
            (answerKeyVersion ?? 0) > 0 &&
            (questionCount ?? 0) >= 1 &&
            questionCount! <= 100 &&
            (maxScore ?? 0) > 0 &&
            maxScore! <= 1000,
      );
    }
  }
  final String examSubjectId, gradeStatus, scoringVersion;
  final String? paperVariant, answerKeyVersionId, gradeCutoffVersionId;
  final int? answerKeyVersion, questionCount, maxScore;
  final ScoringAvailability availability;
  bool get available => availability == ScoringAvailability.scoringAvailable;
  Map<String, dynamic> toJson() => {
    'exam_subject_id': examSubjectId,
    'paper_variant': paperVariant,
    'answer_key_version_id': answerKeyVersionId,
    'answer_key_version': answerKeyVersion,
    'question_count': questionCount,
    'max_score': maxScore,
    'grade_cutoff_version_id': gradeCutoffVersionId,
    'grade_status': gradeStatus,
    'scoring_version': scoringVersion,
    'availability': available ? 'scoring_available' : 'timer_only',
  };
}

/// Deliberately cannot carry a correct answer into the running UI/state.
class AnswerEntryQuestion {
  const AnswerEntryQuestion(this.questionNumber, this.points);
  final int questionNumber, points;
  String get answerType => 'multiple_choice';
  factory AnswerEntryQuestion.fromJson(Map<String, dynamic> j) {
    scoringCheck(j['answer_type'] == 'multiple_choice');
    final q = AnswerEntryQuestion(
      j['question_number'] as int,
      j['points'] as int,
    );
    scoringCheck(
      q.questionNumber >= 1 &&
          q.questionNumber <= 100 &&
          q.points > 0 &&
          q.points <= 100,
    );
    return q;
  }
  Map<String, dynamic> toJson() => {
    'question_number': questionNumber,
    'points': points,
    'answer_type': answerType,
  };
}

class AnswerDraft {
  AnswerDraft(
    this.availability,
    List<AnswerEntryQuestion> questions, [
    List<int?>? answers,
  ]) : questions = List.unmodifiable(questions),
       answers = List.unmodifiable(
         answers ?? List<int?>.filled(questions.length, null),
       ) {
    scoringCheck(
      availability.available &&
          questions.length == availability.questionCount &&
          this.answers.length == questions.length,
    );
    for (var i = 0; i < questions.length; i++) {
      scoringCheck(
        questions[i].questionNumber == i + 1 &&
            (this.answers[i] == null ||
                (this.answers[i]! >= 1 && this.answers[i]! <= 5)),
      );
    }
    scoringCheck(
      questions.fold(0, (n, q) => n + q.points) == availability.maxScore,
    );
  }
  final MockScoringAvailability availability;
  final List<AnswerEntryQuestion> questions;
  final List<int?> answers;
  int get answered => answers.whereType<int>().length;
  int get unanswered => answers.length - answered;
  AnswerDraft select(int number, int? choice) {
    scoringCheck(
      number >= 1 &&
          number <= answers.length &&
          (choice == null || choice >= 1 && choice <= 5),
    );
    final next = [...answers]..[number - 1] = choice;
    return AnswerDraft(availability, questions, next);
  }

  Map<String, dynamic> toJson() => {
    'availability': availability.toJson(),
    'questions': questions.map((q) => q.toJson()).toList(),
    'answers': answers,
  };
  factory AnswerDraft.fromJson(Map<String, dynamic> j) => AnswerDraft(
    MockScoringAvailability.fromJson(
      Map<String, dynamic>.from(j['availability'] as Map),
    ),
    (j['questions'] as List)
        .map(
          (q) =>
              AnswerEntryQuestion.fromJson(Map<String, dynamic>.from(q as Map)),
        )
        .toList(),
    (j['answers'] as List).cast<int?>(),
  );
}

class AnswerReview {
  const AnswerReview(this.number, this.submitted, this.correct, this.points);
  final int number, correct, points;
  final int? submitted;
  bool get isCorrect => submitted == correct;
  Map<String, dynamic> toJson() => {
    'question_number': number,
    'submitted_answer': submitted,
    'correct_answer_snapshot': correct,
    'points_snapshot': points,
    'is_correct': isCorrect,
    'awarded_points': isCorrect ? points : 0,
  };
  factory AnswerReview.fromJson(Map<String, dynamic> j) {
    final r = AnswerReview(
      j['question_number'] as int,
      j['submitted_answer'] as int?,
      j['correct_answer_snapshot'] as int,
      j['points_snapshot'] as int,
    );
    scoringCheck(
      r.correct >= 1 &&
          r.correct <= 5 &&
          r.points > 0 &&
          r.points <= 100 &&
          (r.submitted == null || r.submitted! >= 1 && r.submitted! <= 5) &&
          j['is_correct'] == r.isCorrect &&
          j['awarded_points'] == (r.isCorrect ? r.points : 0),
    );
    return r;
  }
}

/// Immutable provenance from the attempt's pinned published version.
class ScoringSource {
  ScoringSource.fromJson(Map<String, dynamic> j)
    : version = j['version'] as int,
      name = j['source_name'] as String,
      url = j['source_url'] as String,
      verifiedAt = DateTime.parse(j['verified_at'] as String).toUtc(),
      basis = j['basis'] as String?,
      certainty = j['certainty'] as String? {
    final uri = Uri.tryParse(url);
    scoringCheck(
      version > 0 &&
          name.trim().isNotEmpty &&
          name.runes.length <= 200 &&
          !RegExp(r'[\x00-\x1f\x7f]').hasMatch(name) &&
          !RegExp(r'[\x00-\x20\x7f]').hasMatch(url) &&
          uri != null &&
          ['http', 'https'].contains(uri.scheme) &&
          uri.host.isNotEmpty &&
          uri.userInfo.isEmpty &&
          ((basis == null && certainty == null) ||
              (basis == 'raw_absolute' && certainty == 'confirmed') ||
              (basis == 'raw_estimate' && certainty == 'estimated')),
    );
  }
  final int version;
  final String name, url;
  final DateTime verifiedAt;
  final String? basis, certainty;
  Map<String, dynamic> toJson() => {
    'version': version,
    'source_name': name,
    'source_url': url,
    'verified_at': verifiedAt.toIso8601String(),
    if (basis != null) 'basis': basis,
    if (certainty != null) 'certainty': certainty,
  };
}

class ScoreResult {
  ScoreResult(
    this.rawScore,
    this.maxScore,
    List<AnswerReview> answers, {
    this.grade,
    this.gradeStatus = 'unavailable',
    this.keySource,
    this.cutoffSource,
    this.submittedAt,
  }) : answers = List.unmodifiable(answers) {
    scoringCheck(
      answers.isNotEmpty &&
          answers.length <= 100 &&
          maxScore > 0 &&
          maxScore <= 1000 &&
          answers.fold(0, (n, a) => n + a.points) == maxScore &&
          answers.fold(0, (n, a) => n + (a.isCorrect ? a.points : 0)) ==
              rawScore,
    );
    for (var i = 0; i < answers.length; i++) {
      scoringCheck(answers[i].number == i + 1);
    }
    scoringCheck(
      (cutoffSource == null || cutoffSource!.certainty == gradeStatus) &&
          ['unavailable', 'confirmed', 'estimated'].contains(gradeStatus) &&
          (gradeStatus == 'unavailable'
              ? grade == null
              : grade != null && grade! >= 1 && grade! <= 9),
    );
  }
  final ScoringSource? keySource, cutoffSource;
  final DateTime? submittedAt;
  bool get hasGradeBasis =>
      cutoffSource != null && cutoffSource!.certainty == gradeStatus;
  String get gradeLabel => gradeStatus == 'unavailable' || !hasGradeBasis
      ? '등급 정보 준비 중'
      : gradeStatus == 'estimated'
      ? '예상 $grade등급'
      : '$grade등급';
  String? get gradeExplanation => !hasGradeBasis
      ? null
      : gradeStatus == 'estimated'
      ? '예상 등급컷 기준'
      : '확정 등급 기준';
  ScoreResult withSources(ScoringSource key, ScoringSource? cutoff) {
    scoringCheck(
      cutoff == null
          ? gradeStatus == 'unavailable'
          : cutoff.certainty == gradeStatus,
    );
    return ScoreResult(
      rawScore,
      maxScore,
      answers,
      grade: grade,
      gradeStatus: gradeStatus,
      keySource: key,
      cutoffSource: cutoff,
      submittedAt: submittedAt,
    );
  }

  final int rawScore, maxScore;
  final int? grade;
  final String gradeStatus;
  final List<AnswerReview> answers;
  int get correctCount => answers.where((a) => a.isCorrect).length;
  List<int> get wrong => answers
      .where((a) => a.submitted != null && !a.isCorrect)
      .map((a) => a.number)
      .toList();
  List<int> get unanswered =>
      answers.where((a) => a.submitted == null).map((a) => a.number).toList();
  Map<String, dynamic> toJson() => {
    if (keySource != null) 'key_source': keySource!.toJson(),
    if (cutoffSource != null) 'cutoff_source': cutoffSource!.toJson(),
    if (submittedAt != null) 'submitted_at': submittedAt!.toIso8601String(),
    'raw_score': rawScore,
    'max_score': maxScore,
    'correct_count': correctCount,
    'question_count': answers.length,
    'unanswered_count': unanswered.length,
    'incorrect_questions': wrong,
    'unanswered_questions': unanswered,
    'grade': grade,
    'grade_status': gradeStatus,
    'answers': answers.map((a) => a.toJson()).toList(),
  };
  factory ScoreResult.fromJson(Map<String, dynamic> j) {
    final r = ScoreResult(
      j['raw_score'] as int,
      j['max_score'] as int,
      (j['answers'] as List)
          .map(
            (a) => AnswerReview.fromJson(Map<String, dynamic>.from(a as Map)),
          )
          .toList(),
      grade: j['grade'] as int?,
      gradeStatus: j['grade_status'] as String,
      keySource: j['key_source'] == null
          ? null
          : ScoringSource.fromJson(
              Map<String, dynamic>.from(j['key_source'] as Map),
            ),
      cutoffSource: j['cutoff_source'] == null
          ? null
          : ScoringSource.fromJson(
              Map<String, dynamic>.from(j['cutoff_source'] as Map),
            ),
      submittedAt: j['submitted_at'] == null
          ? null
          : DateTime.parse(j['submitted_at'] as String).toUtc(),
    );
    scoringCheck(
      (r.cutoffSource == null || r.cutoffSource!.certainty == r.gradeStatus) &&
          j['correct_count'] == r.correctCount &&
          j['question_count'] == r.answers.length &&
          j['unanswered_count'] == r.unanswered.length,
    );
    return r;
  }
}

/// Invoked only after submission. Never attach solution rows to AnswerDraft.
ScoreResult scoreMcq5(
  List<List<int>> questions,
  List<int?> answers, {
  List<int>? minimumScores,
  String certainty = 'unavailable',
}) {
  scoringCheck(
    questions.length == answers.length &&
        questions.isNotEmpty &&
        questions.length <= 100,
  );
  final review = <AnswerReview>[];
  for (var i = 0; i < questions.length; i++) {
    final q = questions[i];
    scoringCheck(
      q.length == 3 &&
          q[0] == i + 1 &&
          q[1] >= 1 &&
          q[1] <= 5 &&
          q[2] >= 1 &&
          q[2] <= 100 &&
          (answers[i] == null || answers[i]! >= 1 && answers[i]! <= 5),
    );
    review.add(AnswerReview(i + 1, answers[i], q[1], q[2]));
  }
  final raw = review.fold(0, (n, a) => n + (a.isCorrect ? a.points : 0)),
      maximum = review.fold(0, (n, a) => n + a.points);
  int? grade;
  if (minimumScores != null) {
    scoringCheck(
      minimumScores.length == 9 &&
          minimumScores.last == 0 &&
          ['confirmed', 'estimated'].contains(certainty),
    );
    for (var i = 0; i < 9; i++) {
      scoringCheck(
        minimumScores[i] >= 0 &&
            minimumScores[i] <= maximum &&
            (i == 0 || minimumScores[i] < minimumScores[i - 1]),
      );
    }
    grade = minimumScores.indexWhere((s) => raw >= s) + 1;
  } else {
    scoringCheck(certainty == 'unavailable');
  }
  return ScoreResult(
    raw,
    maximum,
    review,
    grade: grade,
    gradeStatus: certainty,
  );
}

class ScoringAttempt {
  const ScoringAttempt({
    required this.id,
    required this.title,
    required this.draft,
    this.studyId,
    this.subject,
    this.completedAt,
    this.result,
    this.outcome = ScoringOutcome.pending,
  });
  final String id, title;
  final String? studyId, subject;
  final DateTime? completedAt;
  final AnswerDraft draft;
  final ScoreResult? result;
  final ScoringOutcome outcome;
  Map<String, dynamic> payload() => {
    'p_attempt_id': id,
    'p_study_session_id': studyId,
    'p_answer_key_version_id': draft.availability.answerKeyVersionId,
    'p_grade_cutoff_version_id': draft.availability.gradeCutoffVersionId,
    'p_scoring_version': draft.availability.scoringVersion,
    'p_answers': [
      for (var i = 0; i < draft.answers.length; i++)
        {'question_number': i + 1, 'choice': draft.answers[i]},
    ],
  };
  ScoringAttempt completed(ScoreResult score) => ScoringAttempt(
    id: id,
    title: title,
    draft: draft,
    studyId: studyId,
    subject: subject,
    completedAt: completedAt,
    result: score,
    outcome: ScoringOutcome.complete,
  );
  ScoringAttempt stale() => ScoringAttempt(
    id: id,
    title: title,
    draft: draft,
    studyId: studyId,
    subject: subject,
    completedAt: completedAt,
    outcome: ScoringOutcome.stale,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'study': studyId,
    if (subject != null) 'subject': subject,
    if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
    'draft': draft.toJson(),
    'result': result?.toJson(),
    'outcome': outcome.name,
  };
  factory ScoringAttempt.fromJson(Map<String, dynamic> j) {
    final a = ScoringAttempt(
      id: j['id'] as String,
      title: j['title'] as String,
      studyId: j['study'] as String?,
      subject: j['subject'] as String?,
      completedAt: j['completed_at'] == null
          ? null
          : DateTime.parse(j['completed_at'] as String).toUtc(),
      draft: AnswerDraft.fromJson(Map<String, dynamic>.from(j['draft'] as Map)),
      result: j['result'] == null
          ? null
          : ScoreResult.fromJson(Map<String, dynamic>.from(j['result'] as Map)),
      outcome: ScoringOutcome.values.byName(j['outcome'] as String),
    );
    scoringCheck((a.outcome == ScoringOutcome.complete) == (a.result != null));
    return a;
  }
}
