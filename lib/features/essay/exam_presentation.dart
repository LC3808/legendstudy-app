/// Display-only: canonical Registry fields and engine bindings remain untouched.
enum EssayServiceArea { humanities, socialBusiness, science }

EssayServiceArea? essayServiceArea(Map<String, dynamic> exam) {
  final track = '${exam['track'] ?? ''}';
  if (RegExp('상경|경상|사회|경제|경영').hasMatch(track)) {
    return EssayServiceArea.socialBusiness;
  }
  if (RegExp(r'자연|공학|이학|의예|의학|약학|과학|^물리$|^화학$').hasMatch(track)) {
    return EssayServiceArea.science;
  }
  if (RegExp('인문|언어').hasMatch(track)) return EssayServiceArea.humanities;
  return null;
}

String essayExamTitle(Map<String, dynamic> exam) {
  final university = '${exam['universityName'] ?? ''}';
  String clean(Object? value) => '${value ?? ''}'
      .replaceAll(
        university.isEmpty ? RegExp(r'$^') : RegExp(RegExp.escape(university)),
        '',
      )
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  final session = clean(exam['session']);
  final track = clean(exam['track']);
  // Browse catalog may use the complete official title for both fields.
  for (final full in [session, track]) {
    if (RegExp(r'\d{4}학년도').hasMatch(full)) return full;
  }
  final kind = switch (exam['kind']) {
    'admission' => '수시 논술',
    'mock' => '모의논술',
    final Object value => '$value',
    _ => '',
  };
  return <String>{
    if (exam['year'] != null) '${exam['year']}학년도',
    kind,
    track,
    session,
    clean(exam['campus']),
  }.where((s) => s.isNotEmpty).join(' · ');
}

String essayQuestionStatus(Object? state) => switch ('$state'.toLowerCase()) {
  'completed' => '완료',
  'failed' => '재처리 필요',
  'processing' => '첨삭 중',
  'waiting' || 'requested' || 'queued' => '대기 중',
  _ => '상태 확인 중',
};

String essayServiceAreaLabel(Map<String, dynamic> exam) =>
    switch (essayServiceArea(exam)) {
      EssayServiceArea.humanities => '인문논술',
      EssayServiceArea.socialBusiness => '사회·상경논술 · 수리 문항 포함 가능',
      EssayServiceArea.science => '자연·공학·이학·의예논술 · 첨삭 공개 보류',
      null => '논술',
    };

String essayQuestionAvailability(
  Map<String, dynamic> exam,
  Map<String, dynamic> question,
  Map<String, dynamic>? admission,
) {
  final id = question['dbQuestionId'];
  final admitted =
      admission?['ready'] == true &&
      (admission?['questionIds'] as List? ?? []).contains(id);
  final math = (admission?['mathQuestions'] as Map? ?? {}).containsKey(id);
  if (essayServiceArea(exam) == EssayServiceArea.science) {
    return '이 시험은 아직 첨삭을 이용할 수 없어요.';
  }
  if (essayServiceArea(exam) == null && math) {
    return '시험 정보를 확인한 뒤 첨삭을 이용할 수 있어요.';
  }
  if (admission == null || !admission.containsKey('ready')) {
    return '첨삭 가능 여부를 확인하고 있어요.';
  }
  return admitted ? '' : '현재 이 문항은 첨삭을 이용할 수 없어요.';
}
