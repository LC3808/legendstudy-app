import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'credit_product.dart';
import 'purchase_verification.dart';

/// Where the purchase flow currently is, for the UI.
enum BillingPhase { idle, purchasing, pending, success, error }

/// Drives Apple IAP / Google Play Billing for consumable 논술 Credit.
///
/// The app NEVER grants Credit. On a store "purchased" event it asks the server
/// to verify + grant idempotently, then re-reads the canonical balance. A store
/// transaction is completed only after the server settles it (granted or
/// already-processed); a pending/failed verification leaves it open to retry.
///
/// Plugin calls (`isAvailable`, `queryProductDetails`, `buyConsumable`,
/// `completePurchase`, the purchase stream) are thin; the decision logic in
/// [handleOne] is injected with [verifier], [complete] and [onBalanceChanged]
/// so it is unit-testable without the store.
class IapController extends ChangeNotifier {
  IapController({
    required this.verifier,
    required this.onBalanceChanged,
    InAppPurchase? iap,
    this._complete,
  }) : _injectedIap = iap;

  final PurchaseVerifier verifier;

  /// Called after the server settles a purchase, so the balance is re-read from
  /// the canonical ledger (the app does not compute it locally).
  final void Function() onBalanceChanged;

  // Resolved lazily so unit tests that only exercise [handleOne] (with an
  // injected `complete`) never touch the platform singleton.
  final InAppPurchase? _injectedIap;
  InAppPurchase get _iap => _injectedIap ?? InAppPurchase.instance;
  final Future<void> Function(PurchaseDetails)? _complete;

  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool available = false;
  bool loadingProducts = false;
  BillingPhase phase = BillingPhase.idle;
  String? message;

  /// Store products keyed by product id (localized price lives here).
  final Map<String, ProductDetails> storeProducts = {};

  /// Transaction ids already settled this session — a local guard on top of the
  /// server's authoritative idempotency.
  final Set<String> _processed = {};

  Future<void> init() async {
    // Any plugin error (e.g. billing unavailable on a sideloaded build) resolves
    // to a deterministic unavailable state — never an unhandled async error.
    try {
      available = await _iap.isAvailable();
    } catch (_) {
      available = false;
    }
    if (!available) {
      notifyListeners();
      return;
    }
    try {
      _sub ??= _iap.purchaseStream.listen(
        handlePurchaseUpdate,
        onError: (_) {
          phase = BillingPhase.error;
          message = '구매 처리 중 문제가 발생했어요. 잠시 후 다시 시도해 주세요.';
          notifyListeners();
        },
      );
      await loadProducts();
    } catch (_) {
      available = false;
      notifyListeners();
    }
  }

  Future<void> loadProducts() async {
    loadingProducts = true;
    notifyListeners();
    try {
      final resp = await _iap.queryProductDetails(creditProductIds);
      storeProducts
        ..clear()
        ..addEntries(resp.productDetails.map((p) => MapEntry(p.id, p)));
    } catch (_) {
      // Leave storeProducts empty; the UI falls back to approved pricing and
      // shows an unavailable state.
    } finally {
      loadingProducts = false;
      notifyListeners();
    }
  }

  /// Start a consumable purchase. Returns false if the product is not available
  /// from the store.
  Future<bool> buy(CreditProduct product) async {
    final details = storeProducts[product.id];
    if (details == null) return false;
    phase = BillingPhase.purchasing;
    message = null;
    notifyListeners();
    return _iap.buyConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  @visibleForTesting
  Future<void> handlePurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      await handleOne(p);
    }
  }

  /// Testable decision core for a single store update.
  @visibleForTesting
  Future<void> handleOne(PurchaseDetails p) async {
    switch (p.status) {
      case PurchaseStatus.pending:
        phase = BillingPhase.pending;
        message = '결제를 확인하고 있어요.';
        notifyListeners();
        return;
      case PurchaseStatus.canceled:
        phase = BillingPhase.idle;
        message = null;
        await _finish(p);
        notifyListeners();
        return;
      case PurchaseStatus.error:
        phase = BillingPhase.error;
        message = '결제를 완료하지 못했어요. 금액이 청구되었다면 잠시 후 자동으로 반영돼요.';
        await _finish(p); // nothing granted; clear the stuck transaction
        notifyListeners();
        return;
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        await _verifyAndGrant(p);
        return;
    }
  }

  Future<void> _verifyAndGrant(PurchaseDetails p) async {
    final txId = p.purchaseID;
    final product = creditProductForId(p.productID);
    // Unknown product or missing transaction id: never grant; leave open.
    if (txId == null || txId.isEmpty || product == null) {
      phase = BillingPhase.pending;
      message = '구매 확인을 기다리고 있어요.';
      notifyListeners();
      return;
    }
    if (_processed.contains(txId)) {
      await _finish(p);
      onBalanceChanged();
      return;
    }
    phase = BillingPhase.pending;
    message = '구매를 확인하고 있어요.';
    notifyListeners();

    final outcome = await verifier.verify(
      IapVerificationRequest(
        platform: _platformOf(p),
        productId: p.productID,
        transactionId: txId,
        verificationData: p.verificationData.serverVerificationData,
      ),
    );

    switch (outcome.status) {
      case VerificationStatus.granted:
      case VerificationStatus.alreadyProcessed:
        _processed.add(txId);
        phase = BillingPhase.success;
        message = '${product.credits} Credit이 충전되었어요.';
        onBalanceChanged(); // re-read canonical ledger
        await _finish(p); // settle the store transaction
      case VerificationStatus.pending:
        phase = BillingPhase.pending;
        message = '구매가 확인되면 Credit이 자동으로 충전돼요.';
        // Do NOT complete — keep it open so the store re-delivers for retry.
      case VerificationStatus.rejected:
        phase = BillingPhase.error;
        message = '구매를 확인하지 못했어요. 금액이 청구되었다면 문의·건의로 알려주세요.';
        await _finish(p); // nothing granted; clear the transaction
    }
    notifyListeners();
  }

  String _platformOf(PurchaseDetails p) {
    final src = p.verificationData.source.toLowerCase();
    if (src.contains('google')) return 'google';
    if (src.contains('app_store') || src.contains('apple') || src.contains('ios')) {
      return 'apple';
    }
    return defaultTargetPlatform == TargetPlatform.android ? 'google' : 'apple';
  }

  Future<void> _finish(PurchaseDetails p) async {
    if (!p.pendingCompletePurchase) return;
    final fn = _complete ?? _iap.completePurchase;
    await fn(p);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
