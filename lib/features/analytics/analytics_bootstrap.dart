import 'dart:async';

import 'data/noop_analytics_service.dart';
import 'domain/analytics_service.dart';

/// No configuration, plugin failure or stalled initialization may block startup.
Future<AnalyticsService> initializeAnalytics({
  required bool enabled,
  required Future<AnalyticsService> Function() initialize,
  Duration timeout = const Duration(seconds: 3),
}) async {
  if (!enabled) return const NoopAnalyticsService();
  try {
    return await initialize().timeout(timeout);
  } catch (_) {
    return const NoopAnalyticsService();
  }
}
