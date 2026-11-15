import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_providers.dart';
import 'domain/analytics_service.dart';
import 'domain/analytics_events.dart';

final usageActionsProvider = Provider<UsageActions>(
  (ref) => UsageActions(ref.watch(analyticsServiceProvider)),
);

/// Behaviour only. No user identity, search text, answers or URLs are sent.
class UsageActions {
  const UsageActions(this.analytics);
  final AnalyticsService analytics;
  static const features = {
    AnalyticsEvents.materialSearch,
    AnalyticsEvents.pdfView,
    AnalyticsEvents.bookmarkAdd,
    AnalyticsEvents.bookmarkRemove,
    AnalyticsEvents.studyTimerStart,
    AnalyticsEvents.studyTimerComplete,
  };
  void feature(String event, {int? durationMs}) {
    if (!features.contains(event)) return;
    _send(event, {
      AnalyticsParamKeys.schemaVersion: 2,
      if (durationMs != null && durationMs >= 0)
        AnalyticsParamKeys.durationMs: durationMs,
    });
  }

  void menuClick(int index) {
    const menus = ['home', 'materials', 'study', 'lab', 'my'];
    if (index < 0 || index >= menus.length) return;
    _send(AnalyticsEvents.menuClick, {
      AnalyticsParamKeys.menuId: menus[index],
      AnalyticsParamKeys.schemaVersion: 2,
    });
  }

  void _send(String event, Map<String, Object?> params) {
    try {
      analytics.logEvent(event, params);
    } catch (_) {
      /* Analytics cannot interrupt a user action. */
    }
  }
}
