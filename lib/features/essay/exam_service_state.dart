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

String examServiceMessage(ExamServiceState state) => switch (state) {
  ExamServiceState.available => '선택한 문항은 첨삭을 이용할 수 있어요.',
  ExamServiceState.preparing => '선택한 시험·문항의 평가자료 또는 첨삭 기능을 준비 중입니다.',
  ExamServiceState.blocked => '현재 운영 공개 범위에 포함되지 않은 시험·문항입니다.',
  ExamServiceState.error => '첨삭 가능 여부를 확인하지 못했어요. 다시 조회해 주세요.',
  ExamServiceState.loading => '첨삭 가능 여부를 확인하고 있어요.',
};
