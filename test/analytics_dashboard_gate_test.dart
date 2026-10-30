import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/analytics/admin_analytics_providers.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_dashboard.dart';

/// Repo that fails the test if it is ever consulted — proves the admin gate
/// short-circuits before any data read for a non-admin.
class _ForbiddenIfCalledRepo implements AnalyticsRepository {
  @override
  Future<bool> isAdmin() async => false;
  @override
  Future<Map<String, dynamic>> fetch(
    AnalyticsSection section,
    AnalyticsPeriod period,
  ) async {
    fail('fetch must not run when caller is not an admin');
  }
}

void main() {
  final period = AnalyticsPeriod.preset(AnalyticsRange.last7);

  test('section provider refuses a non-admin before fetching', () async {
    final container = ProviderContainer(
      overrides: [
        analyticsAdminProvider.overrideWith((ref) => false),
        analyticsRepositoryProvider.overrideWithValue(_ForbiddenIfCalledRepo()),
      ],
    );
    addTearDown(container.dispose);

    final provider = analyticsSectionProvider((AnalyticsSection.kpiOverview, period));
    AsyncValue<Map<String, dynamic>>? latest;
    container.listen(provider, (_, next) => latest = next, fireImmediately: true);
    for (var i = 0; i < 10 && (latest == null || latest!.isLoading); i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(latest!.hasError, isTrue);
    expect(latest!.error, isA<AnalyticsForbidden>());
  });

  test('section provider fetches for an admin', () async {
    final container = ProviderContainer(
      overrides: [
        analyticsAdminProvider.overrideWith((ref) => true),
        analyticsRepositoryProvider.overrideWithValue(_AdminRepo()),
      ],
    );
    addTearDown(container.dispose);

    final provider = analyticsSectionProvider((AnalyticsSection.revenue, period));
    container.listen(provider, (_, _) {}, fireImmediately: true);
    final data = await container.read(provider.future);
    expect(data['version'], 'test');
  });
}

class _AdminRepo implements AnalyticsRepository {
  @override
  Future<bool> isAdmin() async => true;
  @override
  Future<Map<String, dynamic>> fetch(
    AnalyticsSection section,
    AnalyticsPeriod period,
  ) async => {'version': 'test', 'section': section.rpc};
}
