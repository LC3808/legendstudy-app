import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/config/app_config.dart';

void main() {
  testWidgets('boots and navigates through all four destinations', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LegendStudyApp()));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 공부, 여기서 시작해요'), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    await tester.ensureVisible(find.text('모의고사, 논술, 학습자료 검색'));
    await tester.tap(find.text('모의고사, 논술, 학습자료 검색'));
    await tester.pumpAndSettle();
    expect(find.text('나에게 필요한 학습 자료'), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );

    for (final entry in {
      '학습': '공부 타이머',
      'MY': '나의 학습 공간',
      '홈': '오늘의 공부, 여기서 시작해요',
    }.entries) {
      await tester.tap(find.text(entry.key));
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('direct routes select tabs and unknown routes recover', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final router = container.read(routerProvider);
    router.go('/saved');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LegendStudyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
    router.go('/missing');
    await tester.pumpAndSettle();
    expect(find.text('페이지를 찾을 수 없어요'), findsOneWidget);
    await tester.tap(find.text('홈으로 가기'));
    await tester.pumpAndSettle();
    expect(find.text('오늘의 공부, 여기서 시작해요'), findsOneWidget);
  });

  testWidgets('small display supports large text without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ProviderScope(child: LegendStudyApp()));
    await tester.pumpAndSettle();
    for (final label in ['자료', '학습', 'MY', '홈']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  test('configuration defaults to development and can be overridden', () {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(environment: 'test'),
        ),
      ],
    );
    addTearDown(container.dispose);
    expect(AppConfig.fromEnvironment().environment, 'development');
    expect(container.read(appConfigProvider).environment, 'test');
  });
}
