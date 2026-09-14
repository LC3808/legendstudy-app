import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/study/study_providers.dart';
import 'package:legendstudy_app/features/study/data/study_local.dart';
import 'package:legendstudy_app/features/study/focus/focus_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('iOS manual Focus guide, timer and native device preference', (
    tester,
  ) async {
    final service = NativeFocusService(), store = NativeStudyLocalStore();
    final original = await store.read(),
        preference = await service.readPreference();
    ProviderContainer? container;
    Future<void> mount() async {
      await tester.pumpWidget(const SizedBox.shrink());
      container?.dispose();
      container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus(null)),
          ),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container!,
          child: const LegendStudyApp(),
        ),
      );
      await tester.pumpAndSettle();
      for (
        var i = 0;
        i < 30 && !container!.read(studyControllerProvider).ready;
        i++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(container!.read(studyControllerProvider).ready, isTrue);
      await tester.tap(find.byType(NavigationDestination).at(2));
      await tester.pumpAndSettle();
    }

    try {
      expect((await service.status()).capability, FocusCapability.guideOnly);
      expect((await service.status()).permission, isFalse);
      await service.writePreference(FocusPreference.ask);
      await store.write({'version': 1, 'owners': <String, dynamic>{}});
      await mount();
      await tester.tap(find.text('공부 시작'));
      await tester.pumpAndSettle();
      expect(find.text('집중 모드 안내'), findsOneWidget);
      expect(find.text('항상 사용'), findsNothing);
      await tester.ensureVisible(find.text('안내 건너뛰고 시작'));
      await tester.tap(find.text('안내 건너뛰고 시작'));
      await tester.pumpAndSettle();
      expect(container!.read(studyControllerProvider).draft, isNotNull);
      debugPrint('FOCUS_IOS PASS guide_skip_timer_start');
      await tester.pump(const Duration(seconds: 2));
      await tester.tap(find.text('일시정지'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('계속하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('종료'));
      await tester.pumpAndSettle();
      expect(container!.read(studyControllerProvider).draft, isNull);
      expect(await service.activateForStudy('unused'), FocusResult.unsupported);
      debugPrint('FOCUS_IOS PASS no_system_activation');
      await tester.tap(find.text('집중 설정'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('안내하지 않음'));
      await tester.tap(find.text('안내하지 않음'));
      await tester.pumpAndSettle();
      expect(await service.readPreference(), FocusPreference.disabled);
      await mount();
      await tester.tap(find.text('공부 시작'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(container!.read(studyControllerProvider).draft, isNotNull);
      debugPrint('FOCUS_IOS PASS device_preference_restore');
      await tester.tap(find.text('종료'));
      await tester.pumpAndSettle();
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      container?.dispose();
      await service.writePreference(preference);
      await store.write(original);
      expect(await service.readPreference(), preference);
      expect(jsonEncode(await store.read()), jsonEncode(original));
      debugPrint('FOCUS_IOS PASS local_cleanup');
    }
  });
}
