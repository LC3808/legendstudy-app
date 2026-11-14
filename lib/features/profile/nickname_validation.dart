import 'package:characters/characters.dart';

/// New/changed names only; unchanged legacy names remain valid.
String? nicknameValidationError(String raw, {String? previous}) {
  if (raw == previous) return null;
  final value = raw.trim();
  if (value.isEmpty ||
      value.characters.length > 20 ||
      value.contains(RegExp(r'[\x00-\x1f\x7f]'))) {
    return '닉네임은 공백을 제외한 1~20자로 입력해 주세요.';
  }
  return null;
}
