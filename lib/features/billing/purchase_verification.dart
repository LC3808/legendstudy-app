import 'package:supabase_flutter/supabase_flutter.dart';

/// Server verification outcome. The **server** is the sole authority: the app
/// never grants Credit from a store "purchased" event — it submits the purchase
/// for server-side verification (Apple App Store Server API / Google Play
/// Developer API) and an idempotent ledger grant.
enum VerificationStatus {
  /// Verified and newly granted to the canonical ledger.
  granted,

  /// This transaction was already processed — idempotent no-op (safe to
  /// complete the store transaction and refresh the balance).
  alreadyProcessed,

  /// Not yet decided (server busy / Apple-Google pending / network). Keep the
  /// store transaction OPEN and retry; show a pending state; never grant.
  pending,

  /// Verification failed or was refused. Do not grant; surface an error.
  rejected,
}

class VerificationOutcome {
  const VerificationOutcome(this.status, {this.spendable, this.message});
  final VerificationStatus status;

  /// New spendable balance if the server returned it (otherwise re-read
  /// `credit_summary`).
  final int? spendable;
  final String? message;

  bool get isSettled =>
      status == VerificationStatus.granted ||
      status == VerificationStatus.alreadyProcessed;

  /// Map a server JSON response to an outcome. Unknown/missing status is treated
  /// as [VerificationStatus.pending] (retryable) — never an implicit grant.
  factory VerificationOutcome.fromResponse(Object? data) {
    if (data is! Map) return const VerificationOutcome(VerificationStatus.pending);
    final raw = (data['status'] as String?)?.toLowerCase();
    final spendable = data['spendable'] is int ? data['spendable'] as int : null;
    final message = data['message'] as String?;
    final status = switch (raw) {
      'granted' => VerificationStatus.granted,
      'already_processed' || 'duplicate' => VerificationStatus.alreadyProcessed,
      'rejected' || 'invalid' || 'refunded' || 'revoked' =>
        VerificationStatus.rejected,
      _ => VerificationStatus.pending,
    };
    return VerificationOutcome(status, spendable: spendable, message: message);
  }
}

/// What the client sends to the server for one store purchase.
class IapVerificationRequest {
  const IapVerificationRequest({
    required this.platform,
    required this.productId,
    required this.transactionId,
    required this.verificationData,
  });

  /// 'apple' or 'google'.
  final String platform;
  final String productId;

  /// Apple: StoreKit transaction id (JWS tx id) · Google: orderId.
  final String transactionId;

  /// `in_app_purchase` serverVerificationData — Apple: JWS/receipt · Google:
  /// purchaseToken. The server re-verifies this with the store's API.
  final String verificationData;

  Map<String, dynamic> toJson() => {
    'platform': platform,
    'product_id': productId,
    'transaction_id': transactionId,
    'verification_data': verificationData,
  };
}

/// Interface so the server endpoint is swappable (Edge Function vs RPC) and the
/// purchase flow is unit-testable with a fake.
abstract interface class PurchaseVerifier {
  Future<VerificationOutcome> verify(IapVerificationRequest request);
}

/// Default: a Supabase **Edge Function** `verify-iap-purchase` that performs the
/// Apple/Google verification (secrets live server-side, never in the app) and
/// posts an idempotent grant to the canonical ledger keyed by `transaction_id`,
/// with provider `APPLE_IAP` / `GOOGLE_PLAY`.
///
/// CODEX/SERVER CONTRACT (this endpoint does not exist yet — IAP verification is
/// future work per the payment foundation):
///   request : { platform, product_id, transaction_id, verification_data }
///   response: { status: granted|already_processed|pending|rejected, spendable? }
/// Codex may instead expose this as `rpc('payment_redeem_iap', ...)`; only this
/// class changes.
class SupabaseFunctionPurchaseVerifier implements PurchaseVerifier {
  const SupabaseFunctionPurchaseVerifier(this._client, {this.functionName = 'verify-iap-purchase'});
  final SupabaseClient _client;
  final String functionName;

  @override
  Future<VerificationOutcome> verify(IapVerificationRequest request) async {
    try {
      final res = await _client.functions.invoke(functionName, body: request.toJson());
      // 2xx → parse body; anything else is retryable (pending), not a grant.
      if (res.status >= 200 && res.status < 300) {
        return VerificationOutcome.fromResponse(res.data);
      }
      if (res.status == 409) {
        return const VerificationOutcome(VerificationStatus.alreadyProcessed);
      }
      if (res.status == 422 || res.status == 400) {
        return const VerificationOutcome(VerificationStatus.rejected);
      }
      return const VerificationOutcome(VerificationStatus.pending);
    } catch (_) {
      // Never expose SDK/transport detail; a thrown error is retryable.
      return const VerificationOutcome(VerificationStatus.pending);
    }
  }
}
