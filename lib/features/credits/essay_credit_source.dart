/// Server-selected source consent; never allocates Credit locally.
class EssayCreditSource {
  const EssayCreditSource(
    this.grantId,
    this.source,
    this.beta,
    this.signup,
    this.paid,
    this.other,
  );
  final String? grantId;
  final String source;
  final int beta, signup, paid, other;
  static const labels = {
    'beta': '일일 베타 이용권',
    'signup_bonus': '신규가입 무료 이용권',
    'purchase': '유료 이용권',
    'admin_grant': '관리자 지급 이용권',
    'promotion': '프로모션 이용권',
    'compensation': '보상 이용권',
    'b2b_program': '학교 지급 이용권',
    'included': '무료 재첨삭',
  };

  /// Single-line "which Credit is being used" text for the submit confirmation,
  /// built from the server-confirmed deduction source only — never inferred.
  static const usageLabels = {
    'beta': '베타 테스트 이용권 사용',
    'signup_bonus': '무료 이용권 사용',
    'purchase': '유료 이용권 사용',
    'admin_grant': '관리자 지급 이용권 사용',
    'promotion': '프로모션 이용권 사용',
    'compensation': '보상 이용권 사용',
    'b2b_program': '학교 지급 이용권 사용',
    'included': '추가 이용권이 사용되지 않아요',
  };
  String get label => labels[source]!;
  String get usageLabel => usageLabels[source]!;
  factory EssayCreditSource.parse(dynamic raw, int credits) {
    if (raw is! Map ||
        raw['version'] != 'essay-credit-source-v1' ||
        !labels.containsKey(raw['source'])) {
      throw const FormatException('CREDIT_SOURCE_INVALID');
    }
    for (final key in ['beta', 'signup_bonus', 'purchase', 'other']) {
      final value = raw[key];
      if (value is! int || value < 0) {
        throw const FormatException('CREDIT_SOURCE_INVALID');
      }
    }
    final grant = raw['grant_id'];
    if (credits == 0
        ? (grant != null || raw['source'] != 'included')
        : (credits != 1 ||
              raw['source'] == 'included' ||
              grant is! String ||
              !RegExp(
                r'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$',
              ).hasMatch(grant))) {
      throw const FormatException('CREDIT_SOURCE_INVALID');
    }
    return EssayCreditSource(
      grant as String?,
      raw['source'] as String,
      raw['beta'] as int,
      raw['signup_bonus'] as int,
      raw['purchase'] as int,
      raw['other'] as int,
    );
  }
}
