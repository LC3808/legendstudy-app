import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import 'data/supabase_analytics_repository.dart';
import 'domain/analytics_dashboard.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => SupabaseAnalyticsRepository(ref.watch(supabaseClientProvider)),
);

/// Operational-admin check for the dashboard entry gate. Mirrors the server
/// gate (admin_operator via analytics_admin_check) so the UI and the data RPCs
/// agree on who may see analytics.
final analyticsAdminProvider = FutureProvider.autoDispose<bool>((ref) async {
  final auth = ref.watch(authStateProvider);
  if (auth.isLoading) return false;
  if (auth.hasError) return false;
  if (auth.value?.userId == null) return false;
  if (ref.read(supabaseClientProvider) == null) return false;
  return ref.read(analyticsRepositoryProvider).isAdmin();
});

/// Currently selected reporting window. The page updates this; sections watch it.
class AnalyticsPeriodController extends Notifier<AnalyticsPeriod> {
  @override
  AnalyticsPeriod build() => AnalyticsPeriod.preset(AnalyticsRange.last7);
  void select(AnalyticsPeriod period) => state = period;
}

final analyticsPeriodProvider =
    NotifierProvider<AnalyticsPeriodController, AnalyticsPeriod>(
      AnalyticsPeriodController.new,
    );

/// One section's aggregate for a given (section, period). Gated on admin.
final analyticsSectionProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, (AnalyticsSection, AnalyticsPeriod)>((
      ref,
      key,
    ) async {
      final admin = await ref.watch(analyticsAdminProvider.future);
      if (!admin) throw const AnalyticsForbidden();
      return ref.read(analyticsRepositoryProvider).fetch(key.$1, key.$2);
    });
