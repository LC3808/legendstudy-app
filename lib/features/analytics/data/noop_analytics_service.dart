import '../domain/analytics_service.dart';

/// Default implementation when analytics is not configured (no Firebase
/// project / `ANALYTICS_ENABLED` off). The app builds and ships normally; every
/// call is ignored.
class NoopAnalyticsService implements AnalyticsService {
  const NoopAnalyticsService();

  @override
  void logEvent(String name, [Map<String, Object?>? params]) {}

  @override
  void setScreen(String screenName) {}

  @override
  void setUserId(String? pseudonymousUserId) {}
}
