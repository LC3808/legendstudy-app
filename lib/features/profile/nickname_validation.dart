/// Existing LegendStudy nickname policy, shared by MY and onboarding.
/// Callers trim the value before passing it to the existing profile repository.
String? nicknameValidationError(String raw) {
  final value = raw.trim();
  if (value.isEmpty ||
      value.runes.length > 80 ||
      value.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
    return '닉네임은 공백을 제외한 1~80자로 입력해 주세요.';
  }
  return null;
}
