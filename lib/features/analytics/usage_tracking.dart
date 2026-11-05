import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_providers.dart';
import 'domain/analytics_events.dart';
import 'domain/analytics_service.dart';

final usageTrackerProvider = Provider<UsageTracker>(
  (ref) => UsageTracker(ref.watch(analyticsServiceProvider)),
);

/// Finite taxonomy: raw routes, query strings and user input never leave the app.
const usageMenus = <String, String>{
  '/home': 'home',
  '/materials': 'materials',
  '/study': 'study',
  '/lab': 'lab',
  '/lab/essay': 'essay',
  '/lab/essay/math': 'math_essay',
  '/lab/essay/history': 'essay_history',
  '/lab/essay/growth': 'essay_growth',
  '/my': 'my',
  '/my/saved': 'bookmarks',
  '/my/recent': 'recent',
  '/my/trends': 'study_trends',
  '/my/aspirations': 'aspirations',
  '/my/school': 'school',
  '/my/settings': 'settings',
  '/my/feedback': 'feedback',
  '/notices': 'notices',
  '/notifications': 'notifications',
  '/lab/scores': 'scores',
  '/lab/school-scores': 'school_scores',
};

class UsageTracker {
  UsageTracker(this.analytics);
  final AnalyticsService analytics;
  String? _path;
  String _source = 'direct';
  String materialSource = 'direct';

  /// Committed transitions only: rebuilds, query edits and resumes do not count.
  void routeChanged(Uri uri) {
    final path = uri.path;
    if (_path == path) return;
    _path = path;
    final menu = usageMenus[path];
    if (menu != null) {
      _source = menu;
      analytics.setScreen(menu);
      analytics.logEvent(AnalyticsEvents.menuView, {
        AnalyticsParamKeys.menuId: menu,
        AnalyticsParamKeys.schemaVersion: 1,
      });
    } else if (RegExp(r'^/materials/[^/]+$').hasMatch(path)) {
      materialSource = _source;
      analytics.setScreen('material_detail');
      _source = 'material_detail';
    } else {
      _source = 'other';
    }
  }
}

/// One successful detail per navigation instance, not per data refresh.
class MaterialViewTracker {
  MaterialViewTracker(this.analytics, this.source);
  final AnalyticsService analytics;
  final String source;
  final _seen = <String>{};
  void loaded(String id) {
    if (!RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        ).hasMatch(id) ||
        !_seen.add(id)) {
      return;
    }
    analytics.logEvent(AnalyticsEvents.materialOpen, {
      AnalyticsParamKeys.contentItemId: id.toLowerCase(),
      AnalyticsParamKeys.entrySource: source,
      AnalyticsParamKeys.schemaVersion: 1,
    });
  }
}

/// Observe the committed configuration rather than redirects or widget builds.
VoidCallback bindUsageTracking(GoRouter router, UsageTracker usage) {
  void record() {
    if (router.routerDelegate.currentConfiguration.isNotEmpty) {
      usage.routeChanged(router.state.uri);
    }
  }
  router.routerDelegate.addListener(record);
  return () => router.routerDelegate.removeListener(record);
}
