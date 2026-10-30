import 'domain/analytics_service.dart';

/// Process-wide set of already-fired "once" keys. The app process approximates
/// a session for v1; this prevents duplicate funnel/entry events from inflating
/// user counts (Owner directive §5, §13). Reset in tests via [resetAnalyticsOnce].
final Set<String> _firedOnce = <String>{};

extension AnalyticsOnce on AnalyticsService {
  /// Log [name] only the first time this [onceKey] is seen in the process.
  /// Use for entry/funnel-step events that should count once per session.
  void logEventOnce(String onceKey, String name, [Map<String, Object?>? params]) {
    if (!_firedOnce.add(onceKey)) return;
    logEvent(name, params);
  }
}

/// Clear the once-guard. Tests only.
void resetAnalyticsOnce() => _firedOnce.clear();
