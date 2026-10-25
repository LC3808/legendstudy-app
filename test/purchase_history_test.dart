import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/billing/presentation/purchase_history.dart';

void main() {
  testWidgets('empty paid history does not claim no store purchase exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [purchaseHistoryProvider.overrideWith((ref) async => [])],
        child: const MaterialApp(home: Scaffold(body: PurchaseHistory())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('지급 완료된 구매 내역이 없어요.'), findsOneWidget);
    expect(find.textContaining('취소된 스토어 주문'), findsOneWidget);
  });

  testWidgets('paid record and refresh remain readable at 360px / 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var reads = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          purchaseHistoryProvider.overrideWith((ref) async {
            reads++;
            return [
              {
                'created_at': '2026-10-16T04:00:00Z',
                'balance_delta': 1,
                'reason_code': 'iap_google_v1',
              },
            ];
          }),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(child: PurchaseHistory()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1 크레딧 구매'), findsOneWidget);
    expect(find.textContaining('Google Play'), findsOneWidget);
    await tester.tap(find.text('새로고침'));
    await tester.pumpAndSettle();
    expect(reads, 2);
    expect(tester.takeException(), isNull);
  });
}
