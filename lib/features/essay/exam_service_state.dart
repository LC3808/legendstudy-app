/// Display contract only. Server quote/submit remains the authorization boundary.
enum ExamServiceState { available, preparing, blocked, error, loading }

ExamServiceState resolveExamServiceState({
  required Set<String> questions,
  Map<String, dynamic>? admission,
  Set<String> standaloneMathQuestions = const {},
  bool policyBlocked = false,
  bool failed = false,
  bool loading = false,
}) {
  if (policyBlocked ||
      [
        'MIXED_QA_PENDING',
        'RELEASE_SCOPE_CHANGED',
      ].contains(admission?['code'])) {
    return ExamServiceState.blocked;
  }
  final allowed = <String>{
    if (admission?['ready'] == true)
      ...(admission?['questionIds'] as List? ?? []).whereType<String>(),
    ...standaloneMathQuestions,
  };
  if (allowed.isNotEmpty &&
      (questions.isEmpty || questions.every(allowed.contains))) {
    return ExamServiceState.available;
  }
  if (loading) return ExamServiceState.loading;
  if (failed || admission == null || admission['ready'] is! bool) {
    return ExamServiceState.error;
  }
  if (['ACCESS_DENIED', 'NATURAL_MATH_HOLD'].contains(admission['code'])) {
    return ExamServiceState.blocked;
  }
  return ExamServiceState.preparing;
}

String examServiceMessage(ExamServiceState state, {String? admissionCode}) =>
    switch (state) {
      ExamServiceState.available => '선택한 문항은 첨삭을 이용할 수 있어요.',
      ExamServiceState.preparing => '선택한 시험·문항의 평가자료 또는 첨삭 기능을 준비 중입니다.',
      ExamServiceState.blocked => switch (admissionCode) {
        'MIXED_QA_PENDING' => '이 시험은 서술형·수리형 문항의 통합 첨삭을 검수 중입니다.',
        'RELEASE_SCOPE_CHANGED' => '시험의 공개 범위가 변경되었습니다. 시험을 다시 선택해 주세요.',
        'NATURAL_MATH_HOLD' => '선택한 수리 문항은 첨삭 공개 전입니다.',
        _ => '선택한 문항은 현재 첨삭 공개 범위에 포함되지 않습니다.',
      },
      ExamServiceState.error => '첨삭 가능 여부를 확인하지 못했어요. 다시 조회해 주세요.',
      ExamServiceState.loading => '첨삭 가능 여부를 확인하고 있어요.',
    };

/// Only server-confirmed individual questions may be advertised as available.
Set<String> availableExamQuestionIds({
  Map<String, dynamic>? admission,
  Set<String> standaloneMathQuestions = const {},
  bool policyBlocked = false,
}) {
  if (policyBlocked ||
      [
        'MIXED_QA_PENDING',
        'RELEASE_SCOPE_CHANGED',
      ].contains(admission?['code'])) {
    return {};
  }
  return {
    if (admission?['ready'] == true)
      ...(admission?['questionIds'] as List? ?? []).whereType<String>(),
    ...standaloneMathQuestions,
  };
}

String examServiceNoticeMessage(
  ExamServiceState state, {
  String? admissionCode,
  List<String> availableLabels = const [],
  bool partialRelease = false,
}) {
  if (partialRelease &&
      availableLabels.isNotEmpty &&
      state != ExamServiceState.error &&
      state != ExamServiceState.loading) {
    final available =
        '현재 첨삭 가능: ${availableLabels.join(', ')}. 다른 문항은 아직 첨삭을 제공하지 않습니다.';
    return state == ExamServiceState.available
        ? available
        : '$available 첨삭을 요청하려면 가능한 문항만 선택해 주세요. 다른 문항도 문제 열람과 답안 작성은 가능합니다.';
  }
  return examServiceMessage(state, admissionCode: admissionCode);
}
