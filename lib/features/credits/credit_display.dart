import 'dart:convert';

/// Display-only mapping; never participates in allocation or settlement.
String creditEntryLabel(String type, String? reason, num balance) {
  if (type == 'promotion' && reason == 'essay_beta_daily') {
    return '베타 무료 첨삭 이용권 지급';
  }
  if (type == 'admin_grant' && (reason?.trim().startsWith('{') ?? false)) {
    try {
      final audit = jsonDecode(reason!);
      if (audit is Map &&
          audit['operation'] == 'admin_grant_v2' &&
          audit['kind'] == 'other') {
        return '기타 지급';
      }
    } on FormatException {
      /* Preserve unknown reason without inventing a type. */
    }
  }
  if (type == 'refund' && balance > 0 ||
      type == 'adjustment' &&
          balance > 0 &&
          [
            'iap_refund_reversal_apple',
            'iap_refund_reversal_google',
          ].contains(reason)) {
    return '이용권 복구';
  }
  if (type == 'adjustment' &&
      balance < 0 &&
      [
        'purchase_cancel_v1',
        'iap_refund_apple',
        'iap_refund_google',
      ].contains(reason)) {
    return '환불에 따른 이용권 조정';
  }
  return switch (type) {
    'signup_bonus' => '신규가입 무료 이용권 지급',
    'promotion' => '이벤트 이용권 지급',
    'admin_grant' => '관리자 지급',
    'purchase' => '이용권 구매',
    'compensation' => '이용권 복구 또는 보상 지급',
    'b2b_program' => '학교 단체 이용권 지급',
    'reserve' => '첨삭 이용권 사용 대기',
    'consume' => '첨삭 이용권 사용 완료',
    'release' => '이용권 예약 취소',
    'expiration' => '이용권 만료',
    _ => '이용권 조정',
  };
}
