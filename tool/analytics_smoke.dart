// Isolated debug-only Firebase transport check; no Supabase or user operations.
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:legendstudy_app/features/analytics/firebase_usage_options.dart';
import 'package:legendstudy_app/features/analytics/data/firebase_analytics_service.dart';
import 'package:legendstudy_app/features/analytics/usage_tracking.dart';

Future<void> main() async {
  if (!kDebugMode) throw StateError('Analytics smoke is debug only');
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: usageFirebaseOptions());
  await FirebaseAnalytics.instance.setDefaultEventParameters({'debug_mode': 1});
  await FirebaseAnalyticsService.enableCollection();
  final analytics = FirebaseAnalyticsService();
  final usage = UsageTracker(analytics);
  usage.routeChanged(Uri.parse('/home'));
  usage.routeChanged(Uri.parse('/materials'));
  MaterialViewTracker(
    analytics,
    'materials',
  ).loaded('00000000-0000-4000-8000-000000000001');
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Analytics TEST · DebugView 확인\n계정·평가·결제 작업 없음'),
        ),
      ),
    ),
  );
}
