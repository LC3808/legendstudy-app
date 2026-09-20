import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legendstudy_app/features/profile/presentation/profile_page.dart';
import 'package:legendstudy_app/shared/widgets/legendstudy_lab_entry.dart';

import '../test/core_ux_test.dart' as preview;
import '../test/lab_entry_test.dart' as journey;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  journey.nativeCapture = (name) async {
    await binding.takeScreenshot(name);
    if (const bool.fromEnvironment('LAB_SYSTEM_CAPTURE')) {
      debugPrint('LAB_CAPTURE_READY $name');
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  };
  journey.main();
  // Opt-in public web launch only; no Supabase or real authenticated account.
  // After LAB_BROWSER_OPEN, the operator/host must return to the app within
  // 12 seconds. Inspect the browser render separately; launcher success alone
  // does not prove that the remote page loaded.
  if (const bool.fromEnvironment('LAB_LIVE_BROWSER')) {
    testWidgets('native LAB external browser launch and app return', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(child: preview.app(const ProfilePage())),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(LegendStudyLabEntry));
      await tester.tap(find.text('LAB 살펴보기'));
      await tester.pumpAndSettle();
      debugPrint('LAB_BROWSER_OPEN');
      await Future<void>.delayed(const Duration(seconds: 12));
      await tester.pumpAndSettle();
      expect(binding.lifecycleState, AppLifecycleState.resumed);
      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('외부 링크를 열지 못했어요. 다시 시도해 주세요.'), findsNothing);
      expect(find.widgetWithText(TextButton, 'LAB 살펴보기'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, 'LAB 살펴보기'))
            .onPressed,
        isNotNull,
      );
      await journey.nativeCapture!('lab-browser-return');
      await tester.pumpWidget(const SizedBox());
    });
  }
}
