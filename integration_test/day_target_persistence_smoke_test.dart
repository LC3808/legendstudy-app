// Opt-in live Flutter smoke. Credentials arrive once from a loopback-only runner;
// no passwords/JWTs in Dart defines, assets, source, or test output.
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/home/day_target_providers.dart';
import 'package:legendstudy_app/features/personal/data/supabase_personal_repositories.dart';

void check(bool ok) {
  if (!ok) throw StateError('Runtime check failed');
}

void mark(String stage) => debugPrint('DDAY_RUNTIME PASS $stage');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('opt-in live D-Day persistence', (tester) async {
    final uri = Uri.parse(const String.fromEnvironment('SMOKE_CONFIG_URL'));
    check(uri.scheme == 'http' && uri.host == '127.0.0.1');
    final response = await http.get(uri).timeout(const Duration(seconds: 15));
    check(response.statusCode == 200);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final config = AppConfig(
      supabaseUrl: (data['SUPABASE_URL'] as String),
      supabasePublishableKey: (data['SUPABASE_PUBLISHABLE_KEY'] as String),
    );
    check(config.validationErrors.isEmpty);
    final clients = <SupabaseClient>[];
    final touched = <SupabaseClient>[];
    ProviderContainer? container;
    String stage = 'login_preflight';
    const projection =
        'id,display_name,grade_level,neis_office_code,neis_school_code,target_date,target_label';
    Future<List<Map<String, dynamic>>> rows(SupabaseClient client) => client
        .from('profiles')
        .select(projection)
        .eq('id', client.auth.currentUser!.id);
    Future<void> settle() => tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 45),
    );
    Future<void> mount(SupabaseClient client) async {
      await tester.pumpWidget(const SizedBox.shrink());
      container?.dispose();
      container = ProviderContainer(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          supabaseClientProvider.overrideWithValue(client),
          backendIssueProvider.overrideWithValue(null),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container!,
          child: const LegendStudyApp(),
        ),
      );
      await settle();
      await container!.read(dayTargetProvider.future);
      await settle();
    }

    Future<void> edit(String label) async {
      await tester.ensureVisible(find.widgetWithText(TextButton, '설정'));
      await tester.tap(find.widgetWithText(TextButton, '설정'));
      await settle();
      await tester.enterText(find.byType(TextFormField), label);
      await tester.tap(find.text('적용'));
      await settle();
      check(find.byType(AlertDialog).evaluate().isEmpty);
      check(find.text(label).evaluate().length == 1);
    }

    try {
      for (final label in ['A', 'B']) {
        check(
          (data['TEST_${label}_EMAIL'] as String) ==
              'legendstudy${label == 'A' ? '1' : '2'}@legendstudy.com',
        );
        final client = SupabaseClient(
          config.supabaseUrl,
          config.supabasePublishableKey,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        clients.add(client);
        await client.auth.signInWithPassword(
          email: (data['TEST_${label}_EMAIL'] as String),
          password: (data['TEST_${label}_PASSWORD'] as String),
        );
        check(client.auth.currentUser != null && (await rows(client)).isEmpty);
      }
      final a = clients[0], b = clients[1];
      check(a.auth.currentUser!.id != b.auth.currentUser!.id);
      mark(stage);
      stage = 'fixture_profile';
      touched.add(a);
      final profile = SupabaseProfileRepository(a);
      await profile.upsertCurrentProfile(
        displayName: 'D-Day runtime fixture',
        gradeLevel: 2,
      );
      await profile.updateSchoolSelection(
        officeCode: 'J10',
        schoolCode: '7530932',
      );
      final before = (await rows(a)).single;
      await mount(a);
      stage = 'home_save';
      await edit('런타임 중간고사');
      check((await rows(a)).single['target_label'] == '런타임 중간고사');
      mark(stage);
      stage = 'container_restore';
      await mount(a);
      check(find.text('런타임 중간고사').evaluate().length == 1);
      mark(stage);
      stage = 'home_edit';
      await edit('런타임 기말고사');
      check((await rows(a)).single['target_label'] == '런타임 기말고사');
      mark(stage);
      stage = 'account_switch';
      await a.auth.signOut(scope: SignOutScope.local);
      await settle();
      check(find.text('런타임 기말고사').evaluate().isEmpty);
      await mount(b);
      check(find.text('런타임 기말고사').evaluate().isEmpty);
      check(await container!.read(dayTargetProvider.future) == null);
      mark(stage);
      await a.auth.signInWithPassword(
        email: (data['TEST_A_EMAIL'] as String),
        password: (data['TEST_A_PASSWORD'] as String),
      );
      await mount(a);
      stage = 'home_clear';
      await tester.tap(find.widgetWithText(TextButton, '설정'));
      await settle();
      await tester.tap(find.text('해제'));
      await settle();
      check(find.byType(AlertDialog).evaluate().isEmpty);
      final after = (await rows(a)).single;
      check(after['target_date'] == null && after['target_label'] == null);
      for (final key in [
        'display_name',
        'grade_level',
        'neis_office_code',
        'neis_school_code',
      ]) {
        check(before[key] == after[key]);
      }
      mark(stage);
      mark('profile_school_preserved');
    } catch (_) {
      debugPrint('DDAY_RUNTIME FAIL $stage');
      throw StateError('Runtime smoke failed; sensitive details suppressed');
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      container?.dispose();
      var cleanupOk = true;
      for (final client in touched) {
        try {
          if (client.auth.currentUser == null) {
            await client.auth.signInWithPassword(
              email: (data['TEST_A_EMAIL'] as String),
              password: (data['TEST_A_PASSWORD'] as String),
            );
          }
          await client
              .from('profiles')
              .delete()
              .eq('id', client.auth.currentUser!.id);
          check((await rows(client)).isEmpty);
        } catch (_) {
          cleanupOk = false;
        }
      }
      debugPrint('DDAY_RUNTIME ${cleanupOk ? 'PASS' : 'FAIL'} fixture_cleanup');
      for (final client in clients) {
        try {
          await client.auth.signOut(scope: SignOutScope.local);
        } catch (_) {
          /* no user deletion */
        }
        await client.dispose();
      }
      check(cleanupOk);
      mark('auth_users_retained');
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}
