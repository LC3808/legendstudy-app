/// Admin analytics dashboard contracts. These read the official PostgreSQL
/// aggregates (admin-gated RPCs in
/// supabase/candidates/analytics_admin_reporting_20261030). PostgreSQL is the
/// Source of Truth for completion/credit/revenue; GA4 is behaviour only.
library;

class AnalyticsUnavailable implements Exception {
  const AnalyticsUnavailable([this.message = '분석 데이터를 불러올 수 없어요.']);
  final String message;
  @override
  String toString() => message;
}

class AnalyticsForbidden implements Exception {
  const AnalyticsForbidden([this.message = '관리자만 이용할 수 있어요.']);
  final String message;
  @override
  String toString() => message;
}

enum AnalyticsRange {
  today('오늘'),
  last7('최근 7일'),
  last30('최근 30일'),
  custom('기간 지정');

  const AnalyticsRange(this.label);
  final String label;
}

/// A half-open [from, to) window. Stored as UTC instants; the UI builds it from
/// the device's local day boundaries.
class AnalyticsPeriod {
  const AnalyticsPeriod(this.range, this.from, this.to);
  final AnalyticsRange range;
  final DateTime from;
  final DateTime to;

  factory AnalyticsPeriod.preset(AnalyticsRange range, {DateTime? now}) {
    final current = (now ?? DateTime.now()).toLocal();
    final endOfToday = DateTime(current.year, current.month, current.day)
        .add(const Duration(days: 1));
    switch (range) {
      case AnalyticsRange.today:
        final start = DateTime(current.year, current.month, current.day);
        return AnalyticsPeriod(range, start.toUtc(), current.toUtc());
      case AnalyticsRange.last7:
        return AnalyticsPeriod(
          range,
          endOfToday.subtract(const Duration(days: 7)).toUtc(),
          current.toUtc(),
        );
      case AnalyticsRange.last30:
        return AnalyticsPeriod(
          range,
          endOfToday.subtract(const Duration(days: 30)).toUtc(),
          current.toUtc(),
        );
      case AnalyticsRange.custom:
        return AnalyticsPeriod(
          range,
          endOfToday.subtract(const Duration(days: 7)).toUtc(),
          current.toUtc(),
        );
    }
  }

  AnalyticsPeriod custom(DateTime fromLocal, DateTime toLocal) => AnalyticsPeriod(
    AnalyticsRange.custom,
    DateTime(fromLocal.year, fromLocal.month, fromLocal.day).toUtc(),
    DateTime(toLocal.year, toLocal.month, toLocal.day)
        .add(const Duration(days: 1))
        .toUtc(),
  );

  Map<String, String> get rpcArgs => {
    'p_from': from.toIso8601String(),
    'p_to': to.toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is AnalyticsPeriod &&
      other.range == range &&
      other.from == from &&
      other.to == to;

  @override
  int get hashCode => Object.hash(range, from, to);
}

/// The reporting sections, each backed by one admin RPC.
enum AnalyticsSection {
  kpiOverview('analytics_kpi_overview'),
  funnel('analytics_funnel'),
  freeCredit('analytics_free_credit'),
  revenue('analytics_revenue'),
  reliability('analytics_reliability'),
  apiCost('analytics_api_cost'),
  universityUsage('analytics_university_usage');

  const AnalyticsSection(this.rpc);
  final String rpc;
}

abstract class AnalyticsRepository {
  /// Whether the current user is an operational admin (RPC analytics_admin_check).
  Future<bool> isAdmin();

  /// Fetch one section's aggregate JSON for [period]. Returns a map; callers
  /// render known keys defensively and show '데이터 없음' for absent values.
  Future<Map<String, dynamic>> fetch(AnalyticsSection section, AnalyticsPeriod period);
}
