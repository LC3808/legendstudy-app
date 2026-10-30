import 'package:firebase_analytics/firebase_analytics.dart';

import '../domain/analytics_events.dart';
import '../domain/analytics_service.dart';

/// Firebase Analytics (GA4) implementation. Only constructed by the app
/// bootstrap after `Firebase.initializeApp()` succeeds and `ANALYTICS_ENABLED`
/// is set. Every call is fire-and-forget and swallows its own errors so a
/// transport failure can never block essay submission or any user flow.
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService([FirebaseAnalytics? analytics])
    : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  void _fire(Future<void> Function() op) {
    try {
      op().catchError((_) {});
    } catch (_) {
      // Never surface analytics errors to the caller.
    }
  }

  @override
  void logEvent(String name, [Map<String, Object?>? params]) {
    final sanitized = sanitizeAnalyticsParams({
      'platform': analyticsPlatform(),
      ...?params,
    });
    _fire(() async {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.logEvent(
        name: name,
        parameters: sanitized.isEmpty ? null : sanitized,
      );
    });
  }

  @override
  void setScreen(String screenName) {
    _fire(() => _analytics.logScreenView(screenName: screenName));
  }

  @override
  void setUserId(String? pseudonymousUserId) {
    _fire(() => _analytics.setUserId(id: pseudonymousUserId));
  }
}
