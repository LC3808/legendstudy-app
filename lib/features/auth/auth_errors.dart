import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps Supabase auth failures to user-facing Korean.
///
/// Raw SDK text is English and sometimes leaks internals, so it is never shown.
/// Matching prefers the stable `code` and falls back to lowercase substrings of
/// the message; anything unrecognised becomes the safe generic fallback.
const genericAuthFailure = '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.';

const _byCode = <String, String>{
  'invalid_credentials': '이메일 또는 비밀번호가 올바르지 않습니다.',
  'email_not_confirmed': '이메일 인증이 아직 완료되지 않았어요. 받은 편지함을 확인해 주세요.',
  'over_email_send_rate_limit': '요청이 너무 잦아요. 잠시 후 다시 시도해 주세요.',
  'over_request_rate_limit': '요청이 너무 잦아요. 잠시 후 다시 시도해 주세요.',
  'otp_expired': '재설정 링크가 만료되었어요. 다시 요청해 주세요.',
  'weak_password': '비밀번호가 너무 단순해요. 더 긴 비밀번호를 사용해 주세요.',
  'same_password': '이전과 다른 비밀번호를 입력해 주세요.',
  'validation_failed': '입력한 정보를 다시 확인해 주세요.',
  'user_already_exists': '이미 가입된 이메일이에요. 로그인해 주세요.',
  'session_not_found': '로그인 정보가 만료되었어요. 다시 시도해 주세요.',
};

const _bySubstring = <String, String>{
  'invalid login credentials': '이메일 또는 비밀번호가 올바르지 않습니다.',
  'email not confirmed': '이메일 인증이 아직 완료되지 않았어요. 받은 편지함을 확인해 주세요.',
  'rate limit': '요청이 너무 잦아요. 잠시 후 다시 시도해 주세요.',
  'too many requests': '요청이 너무 잦아요. 잠시 후 다시 시도해 주세요.',
  'expired': '재설정 링크가 만료되었어요. 다시 요청해 주세요.',
  'invalid or has expired': '재설정 링크가 만료되었어요. 다시 요청해 주세요.',
  'password should be': '비밀번호가 너무 단순해요. 더 긴 비밀번호를 사용해 주세요.',
  'should be different from the old password': '이전과 다른 비밀번호를 입력해 주세요.',
  'auth session missing': '로그인 정보가 만료되었어요. 다시 시도해 주세요.',
  'unable to validate email': '이메일 형식을 확인해 주세요.',
};

/// Substring keys are matched longest first so a specific phrase wins over a
/// shorter one contained inside it: 'new password should be different from the
/// old password' must resolve to the same-password copy, not the weak-password
/// copy behind the shorter 'password should be'. Sorting removes any dependency
/// on map insertion order.
final _substringKeysLongestFirst = _bySubstring.keys.toList()
  ..sort((a, b) => b.length.compareTo(a.length));

/// Never returns raw SDK text, a token, a URL or a status code.
String authErrorMessage(Object? error) {
  if (error is! AuthException) return genericAuthFailure;
  final code = error.code?.toLowerCase();
  if (code != null && _byCode.containsKey(code)) return _byCode[code]!;
  final message = error.message.toLowerCase();
  for (final key in _substringKeysLongestFirst) {
    if (message.contains(key)) return _bySubstring[key]!;
  }
  return genericAuthFailure;
}
