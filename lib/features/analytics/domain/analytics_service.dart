/// Behavioural analytics surface (GA4 / Firebase Analytics).
///
/// Role split (wiki/analytics-p0-launch-contract.md, Owner 2026-10-30):
/// GA4 carries behaviour and funnel-intent events only. Official counts of
/// evaluation completion, credit usage and revenue stay in PostgreSQL and are
/// never derived from these events. A fired event is an action, not a confirmed
/// server result.
///
/// Every method is fire-and-forget: a transport failure must never block essay
/// submission or any user flow. Implementations swallow their own errors.
abstract class AnalyticsService {
  /// Log a behavioural event. Params are sanitised against an allowlist; no
  /// answer text, evaluation text, name, email, phone, token or API key.
  void logEvent(String name, [Map<String, Object?>? params]);

  /// Record the current screen for funnel context.
  void setScreen(String screenName);

  /// Associate a pseudonymous Supabase user id. Never an email/phone/name.
  /// Null clears it (sign-out). Google Signals stays OFF (Owner console).
  void setUserId(String? pseudonymousUserId);
}
