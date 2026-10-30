import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/analytics/analytics_guard.dart';
import 'package:legendstudy_app/features/analytics/data/noop_analytics_service.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_dashboard.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_events.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_service.dart';

class _Recording implements AnalyticsService {
  final events = <String>[];
  @override
  void logEvent(String name, [Map<String, Object?>? params]) =>
      events.add(name);
  @override
  void setScreen(String screenName) {}
  @override
  void setUserId(String? pseudonymousUserId) {}
}

void main() {
  group('sanitizeAnalyticsParams', () {
    test('keeps allowlisted primitive values', () {
      final out = sanitizeAnalyticsParams({
        AnalyticsParamKeys.platform: 'ios',
        AnalyticsParamKeys.questionCount: 3,
        AnalyticsParamKeys.isFree: true,
      });
      expect(out, {
        AnalyticsParamKeys.platform: 'ios',
        AnalyticsParamKeys.questionCount: 3,
        AnalyticsParamKeys.isFree: true,
      });
    });

    test('drops keys outside the allowlist', () {
      final out = sanitizeAnalyticsParams({'random_key': 'x'});
      expect(out, isEmpty);
    });

    test('drops forbidden PII keys even if present', () {
      final out = sanitizeAnalyticsParams({
        'email': 'a@b.com',
        'user_id': 'u-123',
        'answer': '학생 답안 원문',
        'token': 'secret',
      });
      expect(out, isEmpty);
    });

    test('drops non-primitive values', () {
      final out = sanitizeAnalyticsParams({
        AnalyticsParamKeys.source: ['a', 'b'],
      });
      expect(out, isEmpty);
    });

    test('caps long strings so no free text leaks', () {
      final long = 'x' * 500;
      final out = sanitizeAnalyticsParams({AnalyticsParamKeys.source: long});
      expect((out[AnalyticsParamKeys.source]! as String).length, 100);
    });

    test('null and empty values are dropped', () {
      final out = sanitizeAnalyticsParams({
        AnalyticsParamKeys.status: null,
        AnalyticsParamKeys.errorType: '  ',
      });
      expect(out, isEmpty);
    });
  });

  group('logEventOnce', () {
    test('fires only once per key per session', () {
      resetAnalyticsOnce();
      final svc = _Recording();
      svc.logEventOnce('k', AnalyticsEvents.essayLabView);
      svc.logEventOnce('k', AnalyticsEvents.essayLabView);
      svc.logEventOnce('other', AnalyticsEvents.essayLabView);
      expect(svc.events.length, 2);
    });
  });

  test('NoopAnalyticsService never throws', () {
    const svc = NoopAnalyticsService();
    expect(() {
      svc.logEvent('e', {'x': 1});
      svc.setScreen('s');
      svc.setUserId('u');
    }, returnsNormally);
  });

  group('AnalyticsPeriod', () {
    final now = DateTime(2026, 10, 30, 15, 0);

    test('today starts at local midnight', () {
      final p = AnalyticsPeriod.preset(AnalyticsRange.today, now: now);
      expect(p.from, DateTime(2026, 10, 30).toUtc());
      expect(p.to, now.toUtc());
    });

    test('last7 spans seven days of day-boundaries', () {
      final p = AnalyticsPeriod.preset(AnalyticsRange.last7, now: now);
      final expectedFrom = DateTime(2026, 10, 31).subtract(const Duration(days: 7));
      expect(p.from, expectedFrom.toUtc());
    });

    test('rpcArgs are ISO-8601 UTC', () {
      final p = AnalyticsPeriod.preset(AnalyticsRange.last30, now: now);
      expect(p.rpcArgs['p_from'], p.from.toIso8601String());
      expect(p.rpcArgs['p_to'], p.to.toIso8601String());
      expect(p.rpcArgs['p_from']!.endsWith('Z'), isTrue);
    });

    test('custom window is half-open [from, to+1day)', () {
      final base = AnalyticsPeriod.preset(AnalyticsRange.last7, now: now);
      final p = base.custom(DateTime(2026, 10, 1), DateTime(2026, 10, 10));
      expect(p.range, AnalyticsRange.custom);
      expect(p.from, DateTime(2026, 10, 1).toUtc());
      expect(p.to, DateTime(2026, 10, 11).toUtc());
    });

    test('value equality', () {
      final a = AnalyticsPeriod.preset(AnalyticsRange.last7, now: now);
      final b = AnalyticsPeriod.preset(AnalyticsRange.last7, now: now);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
