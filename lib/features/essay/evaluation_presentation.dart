/// Presentation only; never derives reasons or official scores from levels.
String evaluationChangeSentence(int? before, int? after) {
  if (before == null || after == null) return '평가 단계 정보가 없어 비교할 수 없습니다.';
  final delta = after - before;
  if (delta == 0) return '이전 첨삭과 동일한 평가 수준을 유지했습니다.';
  final amount = ['', '한', '두', '세', '네'][delta.abs()];
  return '이전 첨삭보다 평가 수준이 $amount 단계 ${delta > 0 ? '높아졌습니다' : '낮아졌습니다'}.';
}

String evaluationChangeSpeech(String title, int? before, int? after) {
  if (before == null || after == null) return '$title. 평가 단계 정보가 없어 비교할 수 없습니다.';
  return '$title 항목은 이전 $before단계에서 이번 $after단계로 ${after > before ? '상승했습니다' : after < before ? '하락했습니다' : '유지됐습니다'}. 5단계 기준입니다.';
}
