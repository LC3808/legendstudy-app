import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/billing/billing_providers.dart';
import 'package:legendstudy_app/features/billing/credit_product.dart';
import 'package:legendstudy_app/features/billing/presentation/purchase_history.dart';
import 'package:legendstudy_app/features/billing/iap_controller.dart';
import 'package:legendstudy_app/features/billing/purchase_verification.dart';
import 'package:legendstudy_app/features/billing/presentation/credit_purchase_page.dart';
import 'package:legendstudy_app/features/credits/credit_balance.dart';

class _Verifier implements PurchaseVerifier {
  @override
  Future<VerificationOutcome> verify(IapVerificationRequest request) async =>
      const VerificationOutcome(VerificationStatus.pending);
}

class _Controller extends IapController {
  _Controller(String id)
    : super(verifier: _Verifier(), onBalanceChanged: () {}, accountId: id);
  int starts = 0;
  bool closed = false;
  final bought = <String>[];
  @override
  Future<void> init() async {
    starts++;
  }

  @override
  Future<bool> buy(CreditProduct product) async {
    bought.add(product.id);
    return true;
  }

  @override
  void dispose() {
    closed = true;
    super.dispose();
  }
}

void main() {
  testWidgets('products precede policy links and keep the same purchase IDs', (
    tester,
  ) async {
    final controller = _Controller('A')..available = true;
    addTearDown(controller.dispose);
    for (final product in creditProducts) {
      controller.storeProducts[product.id] = ProductDetails(
        id: product.id,
        title: 'Store title',
        description: 'Store description',
        price: '스토어 가격',
        rawPrice: product.approvedKrw.toDouble(),
        currencyCode: 'KRW',
      );
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('A')),
          ),
          iapControllerProvider.overrideWith((ref) => controller),
          creditBalanceProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: CreditPurchasePage()),
      ),
    );
    await tester.pumpAndSettle();
    for (final count in [1, 3, 5, 10]) {
      expect(find.text('이용권 $count개'), findsOneWidget);
    }
    expect(find.text('스토어 가격'), findsNWidgets(4));
    expect(controller.bought, isEmpty);
    final buttons = find.widgetWithText(FilledButton, '구매');
    final policy = find.text('구매 전 이용약관과 환불 조건을 확인해 주세요.');
    expect(
      tester.getTopLeft(policy).dy,
      greaterThan(tester.getBottomRight(buttons.last).dy),
    );
    await tester.ensureVisible(find.text('환불 조건'));
    await tester.pumpAndSettle();
    expect(find.text('환불 조건').hitTestable(), findsOneWidget);
    expect(find.text('이용약관').hitTestable(), findsOneWidget);
    expect(controller.bought, isEmpty);
    await tester.ensureVisible(buttons.first);
    await tester.pumpAndSettle();
    await tester.tap(buttons.first);
    expect(controller.bought, ['com.legendstudy.essay.credit1']);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history back returns to top-up before leaving the page', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('A')),
          ),
          iapControllerProvider.overrideWith((ref) => null),
          purchaseHistoryProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('이용권 구매')),
                      body: const CreditPurchasePage(),
                    ),
                  ),
                ),
                child: const Text('논술랩'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('논술랩'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('구매내역'));
    await tester.pumpAndSettle();
    expect(find.text('지급 완료된 구매 내역이 없어요.'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(CreditPurchasePage), findsOneWidget);
    expect(find.text('지급 완료된 구매 내역이 없어요.'), findsNothing);
    await tester.tap(find.text('구매내역'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(CreditPurchasePage), findsOneWidget);
    expect(find.text('지급 완료된 구매 내역이 없어요.'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(CreditPurchasePage), findsNothing);
    expect(find.text('논술랩'), findsOneWidget);
  });

  testWidgets(
    'purchase page keeps listener alive and replaces it on account switch',
    (tester) async {
      final auth = StreamController<AuthStatus>();
      addTearDown(auth.close);
      final created = <_Controller>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            purchaseHistoryProvider.overrideWith((ref) async => []),
            authStateProvider.overrideWith((ref) => auth.stream),
            iapControllerProvider.overrideWith((ref) {
              final value = ref.watch(authStateProvider);
              final id = value.value?.userId;
              if (value.isLoading || id == null) return null;
              final c = _Controller(id);
              created.add(c);
              ref.onDispose(c.dispose);
              return c;
            }),
          ],
          child: const MaterialApp(home: CreditPurchasePage()),
        ),
      );
      auth.add(const AuthStatus('A'));
      await tester.pumpAndSettle();
      expect(find.text('이용약관'), findsOneWidget);
      expect(find.text('환불 조건'), findsOneWidget);
      expect(created.single.starts, 1);
      expect(created.single.closed, false);
      await tester.tap(find.text('구매내역'));
      await tester.pumpAndSettle();
      expect(find.text('지급 완료된 구매 내역이 없어요.'), findsOneWidget);
      expect(created.single.starts, 1);
      expect(created.single.closed, false);
      await tester.tap(find.text('구매'));
      await tester.pumpAndSettle();
      expect(created.single.starts, 1);
      auth.add(const AuthStatus('B'));
      await tester.pumpAndSettle();
      expect(created.first.closed, true);
      expect(created.last.accountId, 'B');
      expect(created.last.starts, 1);
      auth.add(const AuthStatus(null));
      await tester.pumpAndSettle();
      expect(created.last.closed, true);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
