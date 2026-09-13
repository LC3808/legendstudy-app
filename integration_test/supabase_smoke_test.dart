import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/content/data/supabase_content_repository.dart';
import 'package:legendstudy_app/features/personal/data/supabase_personal_repositories.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('LegendStudy anonymous empty-database smoke', (tester) async {
    final config = AppConfig.fromEnvironment();
    expect(
      config.validationErrors,
      isEmpty,
      reason: 'Inject local public configuration; never credentials in source.',
    );
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
    );
    final client = Supabase.instance.client;
    addTearDown(() => Supabase.instance.dispose());
    expect(client.auth.currentSession, isNull);
    final rows = await SupabaseContentRepository(client).fetchRecentContent();
    expect(
      rows,
      isEmpty,
      reason:
          'Day 3 fixtures were cleaned up; no seed is inserted by this test.',
    );
    expect(
      await SupabaseProfileRepository(client).fetchCurrentProfile(),
      isNull,
    );
    await expectLater(
      SupabaseRecentViewRepository(client).touchRecentView('not-sent'),
      throwsA(isA<SignedOutException>()),
    );
  });
}
