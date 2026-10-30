import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

/// Canonical analytics `platform` value for the current target.
String analyticsPlatform() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return 'ios';
    case TargetPlatform.android:
      return 'android';
    default:
      return 'other';
  }
}

/// Canonical GA4 event names (Owner directive §3). Web/App share names; the
/// platform is a parameter. These are behaviour events — official completion,
/// credit and revenue counts come from PostgreSQL, not from these.
abstract final class AnalyticsEvents {
  // App / auth
  static const appOpen = 'app_open';
  static const signUp = 'sign_up';
  static const login = 'login';
  static const onboardingComplete = 'onboarding_complete';
  // 논술 LAB
  static const essayLabView = 'essay_lab_view';
  static const universitySelect = 'university_select';
  static const examSelect = 'exam_select';
  static const questionSelect = 'question_select';
  static const essayEditorOpen = 'essay_editor_open';
  static const essayDraftSave = 'essay_draft_save';
  // OCR
  static const essayOcrStart = 'essay_ocr_start';
  static const essayOcrSuccess = 'essay_ocr_success';
  static const essayOcrFailure = 'essay_ocr_failure';
  static const essayOcrApply = 'essay_ocr_apply';
  // 첨삭
  static const essaySubmitStart = 'essay_submit_start';
  static const essaySubmitAccepted = 'essay_submit_accepted';
  static const essaySubmitRejected = 'essay_submit_rejected';
  static const essayProcessingView = 'essay_processing_view';
  static const essayCompleted = 'essay_completed';
  static const essayFailed = 'essay_failed';
  static const essayRetryRequested = 'essay_retry_requested';
  static const essayResultView = 'essay_result_view';
  // 재첨삭
  static const essayRewriteStart = 'essay_rewrite_start';
  static const essayRewriteSubmit = 'essay_rewrite_submit';
  static const essayRewriteCompleted = 'essay_rewrite_completed';
  // 결제
  static const creditPricingView = 'credit_pricing_view';
  static const creditPurchaseStart = 'credit_purchase_start';
  static const creditPurchaseSuccess = 'credit_purchase_success';
  static const creditPurchaseFailed = 'credit_purchase_failed';
  // 성장 분석
  static const essayGrowthView = 'essay_growth_view';
  static const essayGrowthDetailView = 'essay_growth_detail_view';
}

/// Analytics parameter keys. Collection policy (Owner directive §4): only
/// non-identifying categorical/metric context. Anything outside this set is
/// dropped before sending. No answer body, evaluation text, name, email,
/// phone, token, API key, payment instrument or student PII.
abstract final class AnalyticsParamKeys {
  static const platform = 'platform';
  static const appVersion = 'app_version';
  static const screen = 'screen';
  static const examCode = 'exam_code'; // non-identifying exam code, never PII
  static const universityCode = 'university_code';
  static const questionCount = 'question_count';
  static const attemptNo = 'attempt_no';
  static const isFree = 'is_free';
  static const durationMs = 'duration_ms';
  static const status = 'status';
  static const errorType = 'error_type';
  static const productId = 'product_id';
  static const creditCount = 'credit_count';
  static const source = 'source';

  static const allowed = <String>{
    platform,
    appVersion,
    screen,
    examCode,
    universityCode,
    questionCount,
    attemptNo,
    isFree,
    durationMs,
    status,
    errorType,
    productId,
    creditCount,
    source,
  };

  /// Keys that must never reach analytics even if a caller passes them.
  static const forbidden = <String>{
    'user_id',
    'email',
    'phone',
    'name',
    'display_name',
    'token',
    'access_token',
    'api_key',
    'answer',
    'body',
    'text',
    'content',
    'feedback',
    'evaluation',
  };
}

/// Drop any key not in the allowlist (or in the forbidden set), and any value
/// that is not a small primitive. This is a defensive backstop; call sites
/// should already pass only allowed params.
Map<String, Object> sanitizeAnalyticsParams(Map<String, Object?>? params) {
  final out = <String, Object>{};
  if (params == null) return out;
  for (final entry in params.entries) {
    final key = entry.key;
    if (AnalyticsParamKeys.forbidden.contains(key)) continue;
    if (!AnalyticsParamKeys.allowed.contains(key)) continue;
    final value = entry.value;
    if (value == null) continue;
    if (value is bool) {
      out[key] = value ? 1 : 0;
    } else if (value is num && value.isFinite) {
      out[key] = value;
    } else if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      // Cap length so no long free text (e.g. an accidental body) leaks.
      out[key] = trimmed.length > 100 ? trimmed.substring(0, 100) : trimmed;
    }
    // Lists/maps/objects are intentionally dropped.
  }
  return out;
}

/// Convenience typed logging so call sites stay terse and consistent.
extension AnalyticsLogging on AnalyticsService {
  void log(String name, {Map<String, Object?>? params}) =>
      logEvent(name, params);
}
