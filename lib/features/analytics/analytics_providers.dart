import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/noop_analytics_service.dart';
import 'domain/analytics_service.dart';

/// Behavioural analytics service. Defaults to a no-op; the app bootstrap
/// overrides this with a Firebase-backed implementation only when analytics is
/// configured and Firebase initialises successfully (see `main.dart`).
final analyticsServiceProvider = Provider<AnalyticsService>(
  (ref) => const NoopAnalyticsService(),
);
