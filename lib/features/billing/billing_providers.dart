import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../credits/credit_balance.dart';
import 'iap_controller.dart';
import 'purchase_verification.dart';

/// Server verifier (null when there is no Supabase client, e.g. a misconfigured
/// build). Default implementation calls the `verify-iap-purchase` Edge Function.
final purchaseVerifierProvider = Provider<PurchaseVerifier?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseFunctionPurchaseVerifier(client);
});

/// IAP controller for the Credit purchase screen. Null when verification is
/// unavailable. After a settled purchase it invalidates [creditBalanceProvider]
/// so the balance is re-read from the canonical ledger.
final iapControllerProvider = Provider.autoDispose<IapController?>((ref) {
  final verifier = ref.watch(purchaseVerifierProvider);
  if (verifier == null) return null;
  final controller = IapController(
    verifier: verifier,
    onBalanceChanged: () => ref.invalidate(creditBalanceProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
