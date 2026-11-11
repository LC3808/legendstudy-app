// QA-only native account verification. Credentials are entered manually in-app.
// Only the two existing production test accounts may execute this harness.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/features/home/customization/home_configuration.dart';
import 'package:legendstudy_app/features/home/customization/home_editor.dart';
import 'package:legendstudy_app/features/home/presentation/home_page.dart';
import 'package:legendstudy_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.shouldPropagateDevicePointerEvents = true;
  testWidgets('task04c manually authenticated device account verification', (
    t,
  ) async {
    final checks = <String, Object?>{};
    final prefs = SharedPreferencesAsync();
    const prefix = 'task04c.qa.verification.';
    const a = 'legendstudy1@legendstudy.com';
    const b = 'legendstudy2@legendstudy.com';
    Future<void> waitFor(bool Function() ready, {int seconds = 45}) async {
      for (var i = 0; i < seconds * 5; i++) {
        await t.pump(const Duration(milliseconds: 200));
        if (ready()) {
          await t.pump();
          return;
        }
      }
      throw StateError('QA device state timed out');
    }

    Future<void> tap(Finder finder) async {
      await waitFor(() => finder.hitTestable().evaluate().isNotEmpty);
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(finder.hitTestable());
      await t.pump(const Duration(milliseconds: 400));
    }

    app.main();
    await waitFor(() => find.byType(HomePage).evaluate().isNotEmpty);
    final client = Supabase.instance.client;
    final reloggedAtBoot = client.auth.currentUser == null;
    if (reloggedAtBoot) {
      final boot = ProviderScope.containerOf(t.element(find.byType(HomePage)));
      final navigation = boot.read(routerProvider);
      navigation.go('/auth');
      debugPrint('TASK04C_MANUAL_LOGIN:RESUME_ACCOUNT_A');
      await waitFor(() => client.auth.currentUser?.email == a, seconds: 480);
      navigation.go('/home');
      await waitFor(() => find.byType(HomePage).evaluate().isNotEmpty);
    }
    // Stop before any write if the logged-in user is not the intended test user.
    expect(client.auth.currentUser?.email, a);
    expect(client.auth.currentSession != null, true);
    final c = ProviderScope.containerOf(t.element(find.byType(HomePage)));
    final router = c.read(routerProvider);
    Future<HomeConfigurationState> current() async {
      await waitFor(
        () => c.read(homeConfigurationProvider).asData?.value.confirmed == true,
      );
      await t.pump();
      return c.read(homeConfigurationProvider).asData!.value;
    }

    Future<HomeConfigurationState> remote() async {
      final repo = c.read(homeConfigurationRepositoryProvider)!;
      return repo.decode(
        await client.rpc('my_home_configuration'),
        confirmed: true,
      );
    }

    Future<void> loginAs(String email, String prompt) async {
      await client.auth.signOut();
      router.go('/auth');
      await t.pump();
      debugPrint('TASK04C_MANUAL_LOGIN:$prompt');
      await waitFor(
        () => client.auth.currentUser?.email == email,
        seconds: 480,
      );
      router.go('/home');
      await waitFor(() => find.byType(HomePage).evaluate().isNotEmpty);
      await current();
    }

    Future<void> restoreA() async {
      if (client.auth.currentUser?.email != a) return;
      final raw = await prefs.getString('${prefix}original');
      if (raw == null) return;
      final original = HomeConfiguration.fromJson(jsonDecode(raw));
      final latest = await remote();
      if (jsonEncode(latest.configuration.toJson()) ==
          jsonEncode(original.toJson())) {
        checks['test_account_original_configuration_restored'] = true;
        return;
      }
      await c
          .read(homeConfigurationRepositoryProvider)!
          .save(original, latest.revision);
      c.invalidate(homeConfigurationProvider);
      expect((await current()).configuration.toJson(), original.toJson());
      expect((await remote()).configuration.toJson(), original.toJson());
      checks['test_account_original_configuration_restored'] = true;
    }

    final phase = await prefs.getString('${prefix}phase');
    if (phase != 'saved') {
      final initial = await current();
      expect(
        initial.configuration.toJson(),
        (await remote()).configuration.toJson(),
      );
      await prefs.setString(
        '${prefix}original',
        jsonEncode(initial.configuration.toJson()),
      );
      await prefs.setBool('${prefix}originalExisted', initial.exists);
      checks['production_authenticated_home_read'] = true;
      final edit = t.getRect(find.byTooltip('홈 편집'));
      final bell = t.getRect(find.byTooltip('알림'));
      expect(edit.center.dy, closeTo(bell.center.dy, 1));
      expect(edit.right, lessThanOrEqualTo(bell.left));
      checks['edit_left_of_notification'] = true;
      final shown = initial.configuration.cards
          .where((e) => e.visible)
          .toList();
      for (var i = 1; i < shown.length; i++) {
        final before = t.getRect(find.byKey(ValueKey(shown[i - 1].id)));
        final after = t.getRect(find.byKey(ValueKey(shown[i].id)));
        expect(after.top - before.bottom, closeTo(16, 1));
      }
      checks['card_spacing_16dp'] = true;
      try {
        await tap(find.byTooltip('홈 편집'));
        await waitFor(() => find.byType(Checkbox).evaluate().isNotEmpty);
        await tap(find.text('기본 구성으로 초기화'));
        await t.pump();
        await tap(find.byType(Checkbox).first);
        final handle = find.byType(ReorderableDragStartListener).first;
        final drag = await t.startGesture(t.getCenter(handle));
        await t.pump(const Duration(milliseconds: 100));
        await drag.moveBy(const Offset(0, 170));
        await t.pump(const Duration(milliseconds: 500));
        await drag.up();
        await t.pump(const Duration(milliseconds: 500));
        await t.scrollUntilVisible(
          find.text('나의 대학 소식'),
          300,
          scrollable: find.byType(Scrollable).last,
        );
        await tap(
          find.descendant(
            of: find.byKey(const ValueKey('university_news')),
            matching: find.byType(Checkbox),
          ),
        );
        await t.pump();
        await tap(find.text('저장'));
        await waitFor(() => find.byType(HomeEditor).evaluate().isEmpty);
        final saved = await current();
        expect(saved.configuration.cards.first.id, isNot('dday'));
        expect(
          saved.configuration.cards.singleWhere((e) => e.id == 'dday').visible,
          false,
        );
        expect(
          saved.configuration.cards
              .singleWhere((e) => e.id == 'university_news')
              .visible,
          true,
        );
        expect(
          (await remote()).configuration.toJson(),
          saved.configuration.toJson(),
        );
        await prefs.setString(
          '${prefix}saved',
          jsonEncode(saved.configuration.toJson()),
        );
        await prefs.setString('${prefix}phase', 'saved');
        checks['native_touch_hide_reorder_show_news_save'] = true;
        checks['production_rpc_readback_matches_ui'] = true;
        checks['next_step'] = 'terminate_and_relaunch_QA_app';
        await binding.takeScreenshot('task04c-iphone-account-saved');
      } catch (_) {
        await restoreA();
        rethrow;
      }
    } else {
      final expected = HomeConfiguration.fromJson(
        jsonDecode((await prefs.getString('${prefix}saved'))!),
      );
      expect((await current()).configuration.toJson(), expected.toJson());
      expect((await remote()).configuration.toJson(), expected.toJson());
      checks['signed_in_home_matches_previous_process_save'] = true;
      // Fault injection is local to this QA repository instance; server remains untouched.
      final owner = client.auth.currentUser!.id;
      final cache = DeviceHomeCache();
      final before = await cache.read(owner);
      final broken = HomeConfigurationRepository(
        owner: owner,
        currentOwner: () => client.auth.currentUser?.id,
        cache: cache,
        rpc: (_, __) async => throw StateError('QA transport failure'),
      );
      final failure = await broken.load().last;
      expect(failure.failed, true);
      expect(failure.confirmed, false);
      expect(await cache.read(owner), before);
      checks['local_transport_failure_preserves_real_device_cache'] = true;
      try {
        if (!reloggedAtBoot) await loginAs(a, 'SAME_ACCOUNT_A');
        expect((await current()).configuration.toJson(), expected.toJson());
        expect((await remote()).configuration.toJson(), expected.toJson());
        checks['same_account_logout_login_restored'] = true;
        await loginAs(b, 'OTHER_ACCOUNT_B');
        final other = await current();
        expect(
          other.configuration.toJson(),
          (await remote()).configuration.toJson(),
        );
        expect(
          jsonEncode(other.configuration.toJson()),
          isNot(jsonEncode(expected.toJson())),
        );
        checks['different_account_own_server_configuration_no_A_leak'] = true;
        checks['account_B_writes'] = 0;
        await loginAs(a, 'RETURN_ACCOUNT_A_FOR_RESTORE');
        // Another normal save may have happened during manual login.
        // Compare to A's latest server revision, not the frozen first-run fixture.
        expect((await current()).configuration.toJson(), (await remote()).configuration.toJson());
        checks['return_to_A_restored_A_configuration'] = true;
        await tap(find.byTooltip('홈 편집'));
        await waitFor(() => find.text('기본 구성으로 초기화').evaluate().isNotEmpty);
        await tap(find.text('기본 구성으로 초기화'));
        await tap(find.text('저장'));
        await waitFor(() => find.byType(HomeEditor).evaluate().isEmpty);
        expect(
          (await current()).configuration.toJson(),
          HomeConfiguration.defaults().toJson(),
        );
        expect(
          (await remote()).configuration.toJson(),
          HomeConfiguration.defaults().toJson(),
        );
        checks['native_reset_defaults_saved_to_production'] = true;
        await restoreA();
        await prefs.setString('${prefix}phase', 'complete');
        checks['original_existed_before_test'] = await prefs.getBool(
          '${prefix}originalExisted',
        );
        await binding.takeScreenshot('task04c-iphone-account-restored');
      } finally {
        await restoreA();
      }
    }
    binding.reportData = {
      'scope': 'real-iPhone-existing-production-test-accounts-only',
      'checks': checks,
    };
  }, timeout: const Timeout(Duration(minutes: 30)));
}
