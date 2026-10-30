import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/analytics/analytics_bootstrap.dart';
import 'package:legendstudy_app/features/analytics/data/noop_analytics_service.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_service.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_events.dart';

void main() {
  test('disabled bootstrap never initializes Firebase', () async {
    final service = await initializeAnalytics(
      enabled: false,
      initialize: () => throw StateError('must not run'),
    );
    expect(service, isA<NoopAnalyticsService>());
    service.logEvent(AnalyticsEvents.essaySubmitStart);
  });
  test('missing native configuration fails open to Noop', () async {
    final service = await initializeAnalytics(
      enabled: true,
      initialize: () async => throw StateError('missing config'),
    );
    expect(service, isA<NoopAnalyticsService>());
  });
  test('stalled Firebase cannot block app startup', () async {
    final service = await initializeAnalytics(
      enabled: true,
      initialize: () => Completer<AnalyticsService>().future,
      timeout: const Duration(milliseconds: 1),
    );
    expect(service, isA<NoopAnalyticsService>());
  });
  test('boolean parameters are supported numeric GA4 values', () {
    expect(
      sanitizeAnalyticsParams({
        'is_free': false,
        'duration_ms': double.nan,
        'answer': 'private',
      }),
      {'is_free': 0},
    );
  });
  test('candidate RPCs deny null admin and all non-authenticated roles', () {
    final sql = File(
      'supabase/candidates/analytics_admin_reporting_20261030/apply.sql',
    ).readAsStringSync();
    expect(
      'if public.analytics_admin_check() is not true then'
          .allMatches(sql)
          .length,
      7,
    );
    expect("security definer set search_path=''".allMatches(sql).length, 8);
    expect(sql, contains('from public, anon, authenticated, service_role'));
    expect(sql, contains('auth.uid() is not null'));
  });
}
