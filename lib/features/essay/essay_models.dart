import 'package:flutter/foundation.dart';

enum EssayStage { writing, processing, result, revising, comparison, failed }

enum DraftStatus { saved, saving, conflict, failed }

enum EssayAvailability { ready, officialBasis, partial, questionOnly }

extension EssayAvailabilityLabel on EssayAvailability {
  String get label => switch (this) {
    EssayAvailability.ready => '첨삭 가능',
    EssayAvailability.officialBasis => '공식 평가 자료 기반',
    EssayAvailability.partial => '평가 자료 일부',
    EssayAvailability.questionOnly => '문제만 제공',
  };
  bool get canEvaluate =>
      this == EssayAvailability.ready ||
      this == EssayAvailability.officialBasis;
}

enum CriteriaOrigin { officialExam, officialMock, derived, basic }

extension CriteriaOriginLabel on CriteriaOrigin {
  String get label => switch (this) {
    CriteriaOrigin.officialExam => '해당 시험 대학 공식 평가 기준',
    CriteriaOrigin.officialMock => '대학 공식 모의논술 자료 기반',
    CriteriaOrigin.derived => '공식 자료를 바탕으로 LegendStudy가 정리한 평가 기준',
    CriteriaOrigin.basic => 'LegendStudy 기본 평가 기준',
  };
}

@immutable
class EssayQuestion {
  const EssayQuestion({
    required this.id,
    required this.university,
    required this.exam,
    required this.title,
    required this.prompt,
    required this.passages,
    required this.origin,
    this.availability = EssayAvailability.questionOnly,
    this.minLength,
    this.maxLength,
    this.examMinutes,
    this.officialSource,
    this.resourceUrl,
    this.figureUrl,
  });
  final String id, university, exam, title, prompt;
  final List<({String label, String body})> passages;
  final CriteriaOrigin origin;
  final EssayAvailability availability;
  final int? minLength, maxLength, examMinutes;
  final Uri? officialSource, resourceUrl, figureUrl;
}

@immutable
class EssayDimension {
  const EssayDimension(
    this.key,
    this.label,
    this.level,
    this.explanation, {
    this.previousLevel,
    this.officialWeight,
  });
  final String key, label, explanation;
  final int? level, previousLevel;
  final num? officialWeight;
}

@immutable
class EssayEvaluation {
  const EssayEvaluation({
    required this.summary,
    required this.strengths,
    required this.dimensions,
    required this.improvements,
    required this.priorities,
    required this.checklist,
    required this.example,
    required this.changes,
    this.includedRevision = false,
    this.comparable = true,
    this.uncertainty,
  });
  final String summary, example;
  final String? uncertainty;
  final List<String> strengths, improvements, priorities, checklist;
  final List<EssayDimension> dimensions;
  final Map<String, List<String>> changes;
  // Supplied by the backend decision, never inferred from attempt_no in the UI.
  final bool includedRevision, comparable;
}

@immutable
class EssayDraft {
  const EssayDraft(this.body, this.revision);
  final String body;
  final int revision;
}

class EssayConflict implements Exception {}

/// Client operations only. Implementations separate live persistence from preview fixtures.
/// Maps to save_draft / submit_attempt / request_evaluation / request_rewrite.
abstract interface class EssayGateway {
  Future<EssayDraft> saveDraft(String body, int expectedRevision);
  Future<EssayDraft> loadDraft();
  Future<String> submit(String body, int expectedRevision, String requestKey);
  Future<EssayEvaluation> requestEvaluation(String attemptId);
}
