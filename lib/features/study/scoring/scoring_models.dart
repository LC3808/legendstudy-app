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
      verificationStatus = j['verification_status'] as String?,
      availability = switch (j['availability']) {
        'timer_only' => ScoringAvailability.timerOnly,
        'scoring_available' => ScoringAvailability.scoringAvailable,
        _ => throw const FormatException('Invalid availability'),
      } {
    scoringCheck(
      examSubjectId.isNotEmpty &&
          ['mcq5-v1', 'mixed-v2'].contains(scoringVersion),
    );
    scoringCheck(
      verificationStatus == null ||
          ['READY', 'PARTIAL', 'NOT_READY'].contains(verificationStatus),
    );
    if (available &&
        (scoringVersion == 'mixed-v2' || verificationStatus != null)) {
      scoringCheck(verificationStatus == 'READY');
    }
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
  final String? verificationStatus;
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
    if (verificationStatus != null) 'verification_status': verificationStatus,
  };
}

/// Deliberately cannot carry a correct answer into the running UI/state.
class AnswerEntryQuestion {
  const AnswerEntryQuestion(
    this.questionNumber,
    this.points, {
    this.answerType = 'multiple_choice',
  });
  final int questionNumber, points;
  final String answerType;
  bool accepts(int? answer) =>
      answer == null ||
      (answerType == 'multiple_choice'
          ? answer >= 1 && answer <= 5
          : answerType == 'numeric' && answer >= 0 && answer <= 999);
  factory AnswerEntryQuestion.fromJson(Map<String, dynamic> j) {
    scoringCheck(['multiple_choice', 'numeric'].contains(j['answer_type']));
    final q = AnswerEntryQuestion(
      j['question_number'] as int,
      j['points'] as int,
      answerType: j['answer_type'] as String,
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
            ['multiple_choice', 'numeric'].contains(questions[i].answerType) &&
            questions[i].points >= 1 &&
            questions[i].points <= 100 &&
            questions[i].accepts(this.answers[i]) &&
            (availability.scoringVersion == 'mixed-v2' ||
                questions[i].answerType == 'multiple_choice'),
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
          questions[number - 1].accepts(choice),
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
  AnswerReview(this.number, this.submitted, int correct, this.points)
    : answerType = 'multiple_choice',
      acceptedAnswers = List.unmodifiable([correct]),
      allCredit = false,
      questionId = null,
      unit = null,
      domain = null,
      itemType = null;
  AnswerReview.typed(
    this.number,
    this.submitted,
    this.points, {
    required this.answerType,
    required List<int> acceptedAnswers,
    this.allCredit = false,
    required this.questionId,
    this.unit,
    this.domain,
    this.itemType,
  }) : acceptedAnswers = List.unmodifiable(acceptedAnswers) {
    scoringCheck(
      questionId != null &&
          questionId!.isNotEmpty &&
          ['multiple_choice', 'numeric'].contains(answerType) &&
          number >= 1 &&
          number <= 100 &&
          points >= 1 &&
          points <= 100,
    );
    final entry = AnswerEntryQuestion(number, points, answerType: answerType);
    scoringCheck(
      entry.accepts(submitted) &&
          (allCredit ? acceptedAnswers.isEmpty : acceptedAnswers.isNotEmpty) &&
          acceptedAnswers.length <=
              (answerType == 'multiple_choice' ? 5 : 1000) &&
          acceptedAnswers.toSet().length == acceptedAnswers.length &&
          acceptedAnswers.every(entry.accepts),
    );
  }
  final int number, points;
  final int? submitted;
  final String answerType;
  final List<int> acceptedAnswers;
  final bool allCredit;
  final String? questionId, unit, domain, itemType;
  int? get correct =>
      acceptedAnswers.length == 1 ? acceptedAnswers.single : null;
  bool get isCorrect =>
      allCredit || submitted != null && acceptedAnswers.contains(submitted);
  String formatAnswer(int? value) => value == null
      ? '—'
      : answerType == 'numeric'
      ? '$value'
      : ['①', '②', '③', '④', '⑤'][value - 1];
  String get correctLabel =>
      allCredit ? '전원 정답' : acceptedAnswers.map(formatAnswer).join(' / ');
  Map<String, dynamic> toJson() => {
    'question_number': number,
    'submitted_answer': submitted,
    'correct_answer_snapshot': correct,
    'points_snapshot': points,
    'is_correct': isCorrect,
    'awarded_points': isCorrect ? points : 0,
    if (questionId != null) ...{
      'answer_type': answerType,
      'accepted_answers_snapshot': acceptedAnswers,
      'all_credit_snapshot': allCredit,
      'question_id': questionId,
      'unit': unit,
      'domain': domain,
      'item_type': itemType,
    },
  };
  factory AnswerReview.fromJson(Map<String, dynamic> j) {
    final r = j['accepted_answers_snapshot'] != null
        ? AnswerReview.typed(
            j['question_number'] as int,
            j['submitted_answer'] as int?,
            j['points_snapshot'] as int,
            answerType: j['answer_type'] as String,
            acceptedAnswers: (j['accepted_answers_snapshot'] as List)
                .cast<int>(),
            allCredit: j['all_credit_snapshot'] as bool,
            questionId: j['question_id'] as String,
            unit: j['unit'] as String?,
            domain: j['domain'] as String?,
            itemType: j['item_type'] as String?,
          )
        : AnswerReview(
            j['question_number'] as int,
            j['submitted_answer'] as int?,
            j['correct_answer_snapshot'] as int,
            j['points_snapshot'] as int,
          );
    scoringCheck(
      AnswerEntryQuestion(
            r.number,
            r.points,
            answerType: r.answerType,
          ).accepts(r.submitted) &&
          (r.questionId != null || (r.correct! >= 1 && r.correct! <= 5)) &&
          r.points > 0 &&
          r.points <= 100 &&
          j['correct_answer_snapshot'] == r.correct &&
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
    final identities = <String>{};
    for (var i = 0; i < answers.length; i++) {
      scoringCheck(
        answers[i].number == i + 1 &&
            (answers[i].questionId == null ||
                identities.add(answers[i].questionId!)),
      );
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
      ? '등급 산출 불가'
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

/// mixed-v2 retains the same result/attempt envelope. Solutions are fetched only
/// after submit. Unknown metadata remains null; no topic inference is performed.
ScoreResult scoreMixed(
  List<Map<String, dynamic>> questions,
  List<int?> answers, {
  List<int>? minimumScores,
  String certainty = 'unavailable',
}) {
  scoringCheck(
    questions.isNotEmpty &&
        questions.length <= 100 &&
        questions.length == answers.length,
  );
  final review = <AnswerReview>[];
  final ids = <String>{};
  for (var i = 0; i < questions.length; i++) {
    final q = questions[i];
    scoringCheck(
      q['question_number'] == i + 1 &&
          q['question_id'] is String &&
          ids.add(q['question_id'] as String),
    );
    review.add(
      AnswerReview.typed(
        i + 1,
        answers[i],
        q['points'] as int,
        answerType: q['answer_type'] as String,
        acceptedAnswers: (q['accepted_answers'] as List).cast<int>(),
        allCredit: q['all_credit'] as bool,
        questionId: q['question_id'] as String,
        unit: q['unit'] as String?,
        domain: q['domain'] as String?,
        itemType: q['item_type'] as String?,
      ),
    );
  }
  final raw = review.fold(0, (n, a) => n + (a.isCorrect ? a.points : 0));
  final maximum = review.fold(0, (n, a) => n + a.points);
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
