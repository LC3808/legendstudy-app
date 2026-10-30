import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/analytics_dashboard.dart';

/// Reads the admin-gated analytics RPCs. Never writes; never triggers an
/// evaluation. Admin enforcement is server-side (security definer +
/// admin_operator); this is the client view.
class SupabaseAnalyticsRepository implements AnalyticsRepository {
  SupabaseAnalyticsRepository(this.client);
  final SupabaseClient? client;

  SupabaseClient get _backend {
    final backend = client;
    if (backend == null) throw const AnalyticsUnavailable('서버가 준비되지 않았어요.');
    return backend;
  }

  @override
  Future<bool> isAdmin() async {
    try {
      final result = await _backend.rpc<dynamic>('analytics_admin_check');
      return result == true;
    } on PostgrestException {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>> fetch(
    AnalyticsSection section,
    AnalyticsPeriod period,
  ) async {
    try {
      final result = await _backend.rpc<dynamic>(
        section.rpc,
        params: period.rpcArgs,
      );
      if (result is Map) return Map<String, dynamic>.from(result);
      throw const AnalyticsUnavailable();
    } on PostgrestException catch (error) {
      if (error.code == 'PT403' ||
          error.message.contains('OPERATOR_REQUIRED')) {
        throw const AnalyticsForbidden();
      }
      throw const AnalyticsUnavailable();
    }
  }
}
