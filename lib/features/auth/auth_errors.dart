import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps Supabase auth failures to user-facing Korean.
///
/// Raw SDK text is English and sometimes leaks internals, so it is never shown.
/// Matching prefers the stable `code` and falls back to lowercase substrings of
/// the message; anything unrecognised becomes the safe generic fallback.
const genericAuthFailure = '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.';

/// Shown when a recovery link cannot be exchanged for a session. Deliberately
/// broader than "expired": the same failure covers a link that was already
/// used and one opened on a device that did not request it.
const recoveryLinkUnusableMessage = '재설정 링크를 사용할 수 없어요. 다시 요청해 주세요.';

const _byCode = <String, String>{
  'email_exists': '가입 정보를 확인해 주세요. 기존 계정이 있다면 로그인하거나 비밀번호를 재설정해 주세요.',
  'oauth_provider_not_supported': '현재 이 로그인 방식을 사용할 수 없습니다.',
  'unexpected_failure': '로그인을 완료하지 못했어요. 잠시 후 다시 시도해 주세요.',
  'bad_oauth_callback': '로그인을 완료하지 못했어요. 로그인 화면에서 다시 시도해 주세요.',
  'bad_oauth_state': '로그인 요청이 만료됐어요. 다시 시도해 주세요.',
  'invalid_credentials': '이메일 또는 비밀번호가 올바르지 않습니다.',
  'email_not_confirmed': '이메일 인증이 아직 완료되지 않았어요. 받은 편지함을 확인해 주세요.',
  'over_email_send_rate_limit': '요청이 너무 잦아요. 잠시 후 다시 시도해 주세요.',
  'over_request_rate_limit': '요청이 너무 잦아요. 잠시 후 다시 시도해 주세요.',
  'otp_expired': '재설정 링크가 만료되었어요. 다시 요청해 주세요.',
  'weak_password': '비밀번호가 너무 단순해요. 더 긴 비밀번호를 사용해 주세요.',
  'same_password': '이전과 다른 비밀번호를 입력해 주세요.',
  'validation_failed': '입력한 정보를 다시 확인해 주세요.',
  'user_already_exists': '가입 정보를 확인해 주세요. 기존 계정이 있다면 로그인하거나 비밀번호를 재설정해 주세요.',
  'session_not_found': '로그인 정보가 만료되었어요. 다시 시도해 주세요.',
  // A provider consent screen that was cancelled or refused comes back as
  // error=access_denied. An expired recovery link carries the same coarse
  // value, which is why the specific error_code is consulted first below.
  'access_denied': '로그인이 취소되었어요.',
  // The provider is not switched on for this Supabase project yet. Reported as
  // a user-facing limit, never as a configuration hint.
  'provider_disabled': '지금은 이 방법으로 로그인할 수 없어요. 다른 방법을 사용해 주세요.',
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

/// Codes gotrue reports when a recovery link cannot be exchanged for a session.
///
/// A link opened from the email lands on `redirect_to` either with `code` (the
/// PKCE auth code) or with `error`/`error_code`. getSessionFromUrl turns the
/// latter into an AuthException whose `code` is `error` and whose `statusCode`
/// is `error_code`, so both fields are checked.
///
/// The coarse `access_denied` is deliberately absent: a cancelled social login
/// reports it too, and that must not send anyone to the recovery screen.
const _linkFailureCodes = <String>{
  'otp_expired',
  'flow_state_expired',
  'flow_state_not_found',
  'bad_code_verifier',
};

/// True when the failure is "this link cannot be used", not "the request
/// failed". The PKCE verifier is stored by the install that asked for the
/// reset, so a link opened elsewhere fails here too.
bool isRecoveryLinkFailure(Object? error) {
  if (error is! AuthException) return false;
  if (_linkFailureCodes.contains(error.code?.toLowerCase()) ||
      _linkFailureCodes.contains(error.statusCode?.toLowerCase())) {
    return true;
  }
  final message = error.message.toLowerCase();
  return message.contains('code verifier') ||
      message.contains('no code detected');
}

/// Never returns raw SDK text, a token, a URL or a status code.
String authErrorMessage(Object? error) {
  if (error is SocketException ||
      error is TimeoutException ||
      error is AuthRetryableFetchException) {
    return '인터넷 연결을 확인한 뒤 다시 시도해 주세요.';
  }
  if (error is! AuthException) return genericAuthFailure;
  // On a link or OAuth callback the specific value arrives as error_code, which
  // the SDK stores in statusCode, while code holds the coarse `error`. The
  // specific one therefore wins; an HTTP status such as '400' simply misses.
  final status = error.statusCode?.toLowerCase();
  if (status != null && _byCode.containsKey(status)) return _byCode[status]!;
  final code = error.code?.toLowerCase();
  if (code != null && _byCode.containsKey(code)) return _byCode[code]!;
  final message = error.message.toLowerCase();
  for (final key in _substringKeysLongestFirst) {
    if (message.contains(key)) return _bySubstring[key]!;
  }
  return genericAuthFailure;
}
