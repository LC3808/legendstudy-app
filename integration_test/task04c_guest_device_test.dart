// Physical-device Guest smoke. Uses the real app and local device storage.
// Never logs in, changes production records, or constructs synthetic Auth users.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/features/home/customization/home_configuration.dart';
import 'package:legendstudy_app/features/home/customization/home_editor.dart';
import 'package:legendstudy_app/features/home/presentation/home_page.dart';
import 'package:legendstudy_app/features/onboarding/device_intro.dart';
import 'package:legendstudy_app/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('task04c real device guest home interactions', (t) async {
    final checks = <String, bool>{};
    Future<void> waitFor(bool Function() condition) async {
      for (var i = 0; i < 150; i++) {
        await t.pump(const Duration(milliseconds: 200));
        if (condition()) return;
      }
      throw StateError('Device UI did not reach expected state');
    }

    await DeviceIntroStore().complete();
    app.main();
    await waitFor(() => find.byType(HomePage).evaluate().isNotEmpty);
    final client = Supabase.instance.client;
    expect(
      client.auth.currentUser,
      isNull,
      reason: 'Guest smoke must not write an account',
    );
    final container = ProviderScope.containerOf(
      t.element(find.byType(HomePage)),
    );
    await waitFor(
      () =>
          container.read(homeConfigurationProvider).asData?.value.confirmed ==
          true,
    );
    final initial = container.read(homeConfigurationProvider).asData!.value;
    checks['real_app_guest_boot'] = true;
    final edit = t.getRect(find.byTooltip('홈 편집'));
    final bell = t.getRect(find.byTooltip('알림'));
    expect(edit.center.dy, closeTo(bell.center.dy, 1));
    expect(edit.right, lessThanOrEqualTo(bell.left));
    checks['edit_left_of_notification'] = true;
    final shown = initial.configuration.cards.where((c) => c.visible).toList();
    for (var i = 1; i < shown.length; i++) {
      final a = t.getRect(find.byKey(ValueKey(shown[i - 1].id)));
      final b = t.getRect(find.byKey(ValueKey(shown[i].id)));
      expect(b.top - a.bottom, closeTo(16, 1));
    }
    checks['spacing_16dp'] = true;
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await t.pump();
    }
    await binding.takeScreenshot('task04c-guest-home');
    await t.tap(find.byTooltip('홈 편집'));
    await waitFor(() => find.byType(Checkbox).evaluate().isNotEmpty);
    await t.tap(find.text('기본 구성으로 초기화'));
    await t.pump();
    await t.tap(find.byType(Checkbox).first);
    final handle = find.byType(ReorderableDragStartListener).first;
    final drag = await t.startGesture(t.getCenter(handle));
    await t.pump(const Duration(milliseconds: 100));
    await drag.moveBy(const Offset(0, 170));
    await t.pump(const Duration(milliseconds: 500));
    await drag.up();
    await t.pump(const Duration(milliseconds: 500));
    await t.tap(find.text('저장'));
    await waitFor(() => find.byType(HomeEditor).evaluate().isEmpty);
    await waitFor(
      () =>
          container.read(homeConfigurationProvider).asData?.value.confirmed ==
          true,
    );
    final saved = container.read(homeConfigurationProvider).asData!.value;
    expect(saved.configuration.cards.first.id, isNot('dday'));
    expect(
      saved.configuration.cards.singleWhere((c) => c.id == 'dday').visible,
      false,
    );
    checks['touch_hide_drag_save'] = true;
    final disk = await DeviceHomeCache().read('guest');
    expect(
      HomeConfiguration.fromJson(jsonDecode(disk!)).toJson(),
      saved.configuration.toJson(),
    );
    checks['native_storage_readback'] = true;
    await t.tap(find.byTooltip('홈 편집'));
    await waitFor(() => find.text('기본 구성으로 초기화').evaluate().isNotEmpty);
    await t.tap(find.text('기본 구성으로 초기화'));
    await t.tap(find.text('저장'));
    await waitFor(() => find.byType(HomeEditor).evaluate().isEmpty);
    await waitFor(
      () =>
          container.read(homeConfigurationProvider).asData?.value.confirmed ==
          true,
    );
    expect(
      container
          .read(homeConfigurationProvider)
          .asData!
          .value
          .configuration
          .toJson(),
      HomeConfiguration.defaults().toJson(),
    );
    checks['reset_defaults'] = true;
    await binding.takeScreenshot('task04c-guest-reset');
    final router = container.read(routerProvider);
    for (final route in [
      '/lab',
      '/lab/csat-mock',
      '/lab/essay',
      '/study',
      '/study/schools',
      '/my',
    ]) {
      router.go(route);
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
      expect(router.routeInformationProvider.value.uri.path, route);
      checks['route_$route'] = true;
    }
    router.go('/home');
    await t.pump(const Duration(seconds: 2));
    expect(find.text('D-DAY'), findsWidgets);
    expect(find.text('나의 공부 시간'), findsWidgets);
    checks['dday_study_home_return'] = true;
    // Leave the isolated guest app with its original configuration, never an account write.
    await container
        .read(homeConfigurationRepositoryProvider)!
        .save(
          initial.configuration,
          container.read(homeConfigurationProvider).asData!.value.revision,
        );
    binding.reportData = {
      'scope': 'real-device-guest-only',
      'checks': checks,
      'production_account_writes': 0,
    };
  }, timeout: const Timeout(Duration(minutes: 5)));
}
