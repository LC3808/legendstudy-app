import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/billing/credit_product.dart';
import 'package:legendstudy_app/features/billing/iap_controller.dart';
import 'package:legendstudy_app/features/billing/presentation/credit_purchase_page.dart';
import 'package:legendstudy_app/features/billing/purchase_verification.dart';

class _FakeVerifier implements PurchaseVerifier {
  _FakeVerifier(this.outcome);
  VerificationOutcome outcome;
  int calls = 0;
  @override
  Future<VerificationOutcome> verify(IapVerificationRequest request) async {
    calls++;
    return outcome;
  }
}

PurchaseDetails _pd(
  PurchaseStatus status, {
  String product = 'com.legendstudy.essay.credit3',
  String? txid = 'tx-1',
  String source = 'app_store',
  bool pendingComplete = true,
}) {
  final d = PurchaseDetails(
    purchaseID: txid,
    productID: product,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server-data',
      source: source,
    ),
    transactionDate: null,
    status: status,
  );
  d.pendingCompletePurchase = pendingComplete;
  return d;
}

({IapController c, List<String> completed, _FakeVerifier v, int Function() refreshed})
    _harness(VerificationOutcome outcome) {
  final completed = <String>[];
  var refreshed = 0;
  final v = _FakeVerifier(outcome);
  final c = IapController(
    verifier: v,
    onBalanceChanged: () => refreshed++,
    complete: (d) async => completed.add(d.purchaseID ?? ''),
  );
  return (c: c, completed: completed, v: v, refreshed: () => refreshed);
}

void main() {
  group('credit product catalog', () {
    test('four launch products, correct credit mapping', () {
      expect(creditProducts.length, 4);
      expect(creditProductForId('com.legendstudy.essay.credit1')!.credits, 1);
      expect(creditProductForId('com.legendstudy.essay.credit10')!.credits, 10);
      expect(creditProductForId('com.legendstudy.essay.credit3')!.approvedKrw, 11900);
      expect(creditProductForId('unknown.product'), isNull);
      expect(creditProductIds.length, 4);
    });
    test('KRW formatting', () {
      expect(formatKrw(4900), '4,900원');
      expect(formatKrw(29900), '29,900원');
    });
  });

  group('verification outcome mapping', () {
    VerificationStatus s(Object? data) =>
        VerificationOutcome.fromResponse(data).status;
    test('server statuses map correctly', () {
      expect(s({'status': 'granted', 'spendable': 7}), VerificationStatus.granted);
      expect(s({'status': 'already_processed'}), VerificationStatus.alreadyProcessed);
      expect(s({'status': 'duplicate'}), VerificationStatus.alreadyProcessed);
      expect(s({'status': 'rejected'}), VerificationStatus.rejected);
      expect(s({'status': 'refunded'}), VerificationStatus.rejected);
      expect(s({'status': 'pending'}), VerificationStatus.pending);
    });
    test('unknown/missing/non-map never implies a grant', () {
      expect(s({'status': 'weird'}), VerificationStatus.pending);
      expect(s(<String, dynamic>{}), VerificationStatus.pending);
      expect(s(null), VerificationStatus.pending);
      expect(s('oops'), VerificationStatus.pending);
    });
    test('granted carries spendable', () {
      final o = VerificationOutcome.fromResponse({'status': 'granted', 'spendable': 7});
      expect(o.spendable, 7);
      expect(o.isSettled, isTrue);
    });
  });

  group('IapController.handleOne — the app never self-grants', () {
    test('granted → success, balance refreshed, transaction completed', () async {
      final h = _harness(const VerificationOutcome(VerificationStatus.granted));
      await h.c.handleOne(_pd(PurchaseStatus.purchased));
      expect(h.c.phase, BillingPhase.success);
      expect(h.refreshed(), 1);
      expect(h.completed, ['tx-1']);
      expect(h.v.calls, 1);
    });

    test('pending verification → pending, NOT completed, NOT refreshed', () async {
      final h = _harness(const VerificationOutcome(VerificationStatus.pending));
      await h.c.handleOne(_pd(PurchaseStatus.purchased));
      expect(h.c.phase, BillingPhase.pending);
      expect(h.refreshed(), 0);
      expect(h.completed, isEmpty); // kept open for store re-delivery
    });

    test('rejected → error, no grant, transaction cleared', () async {
      final h = _harness(const VerificationOutcome(VerificationStatus.rejected));
      await h.c.handleOne(_pd(PurchaseStatus.purchased));
      expect(h.c.phase, BillingPhase.error);
      expect(h.refreshed(), 0);
      expect(h.completed, ['tx-1']);
    });

    test('duplicate transaction verifies once, then completes + refreshes', () async {
      final h = _harness(const VerificationOutcome(VerificationStatus.granted));
      await h.c.handleOne(_pd(PurchaseStatus.purchased));
      await h.c.handleOne(_pd(PurchaseStatus.purchased)); // same tx-1
      expect(h.v.calls, 1); // not re-verified
      expect(h.refreshed(), 2); // balance re-read both times
      expect(h.completed, ['tx-1', 'tx-1']);
    });

    test('unknown product id → never granted, left pending', () async {
      final h = _harness(const VerificationOutcome(VerificationStatus.granted));
      await h.c.handleOne(_pd(PurchaseStatus.purchased, product: 'com.other.x'));
      expect(h.v.calls, 0);
      expect(h.c.phase, BillingPhase.pending);
      expect(h.completed, isEmpty);
    });

    test('missing transaction id → never granted', () async {
      final h = _harness(const VerificationOutcome(VerificationStatus.granted));
      await h.c.handleOne(_pd(PurchaseStatus.purchased, txid: null));
      expect(h.v.calls, 0);
      expect(h.c.phase, BillingPhase.pending);
    });

    test('pending status → shows pending, no verify', () async {
      final h = _harness(const VerificationOutcome(VerificationStatus.granted));
      await h.c.handleOne(_pd(PurchaseStatus.pending));
      expect(h.c.phase, BillingPhase.pending);
      expect(h.v.calls, 0);
    });

    test('canceled → idle, transaction cleared', () async {
      final h = _harness(const VerificationOutcome(VerificationStatus.granted));
      await h.c.handleOne(_pd(PurchaseStatus.canceled));
      expect(h.c.phase, BillingPhase.idle);
      expect(h.completed, ['tx-1']);
      expect(h.v.calls, 0);
    });

    test('error → error phase, transaction cleared', () async {
      final h = _harness(const VerificationOutcome(VerificationStatus.granted));
      await h.c.handleOne(_pd(PurchaseStatus.error));
      expect(h.c.phase, BillingPhase.error);
      expect(h.completed, ['tx-1']);
    });

    test('platform derived from source (google → google)', () async {
      final v = _FakeVerifier(const VerificationOutcome(VerificationStatus.granted));
      IapVerificationRequest? seen;
      final c = IapController(
        verifier: _CapturingVerifier((r) => seen = r, v.outcome),
        onBalanceChanged: () {},
        complete: (_) async {},
      );
      await c.handleOne(_pd(PurchaseStatus.purchased, source: 'google_play'));
      expect(seen!.platform, 'google');
    });
  });

  testWidgets('purchase page: guest sees a login prompt, no crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus(null)),
          ),
          supabaseClientProvider.overrideWithValue(null),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const CreditPurchasePage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Credit은 계정에 적립돼요. 먼저 로그인해 주세요.'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _CapturingVerifier implements PurchaseVerifier {
  _CapturingVerifier(this.onReq, this.outcome);
  final void Function(IapVerificationRequest) onReq;
  final VerificationOutcome outcome;
  @override
  Future<VerificationOutcome> verify(IapVerificationRequest request) async {
    onReq(request);
    return outcome;
  }
}
