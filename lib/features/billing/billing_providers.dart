import '../../core/network/review_read_only_client.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/config/app_config.dart';
import '../credits/credit_balance.dart';
import 'iap_controller.dart';
import 'presentation/purchase_history.dart';
import 'purchase_verification.dart';

/// Server verifier (null when there is no Supabase client, e.g. a misconfigured
/// build). Default implementation calls the `verify-iap-purchase` Edge Function.
final purchaseVerifierProvider = Provider<PurchaseVerifier?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null
      ? null
      : SupabaseFunctionPurchaseVerifier(
          client,
          testSessionOnly: ref.watch(appConfigProvider).environment == 'test',
        );
});

/// IAP controller for the Credit purchase screen. Null when verification is
/// unavailable. After a settled purchase it invalidates [creditBalanceProvider]
/// so the balance is re-read from the canonical ledger.
final iapControllerProvider = Provider.autoDispose<IapController?>((ref) {
  if (reviewReadOnly ||
      !const bool.fromEnvironment(
        'IAP_TRANSACTIONS_ENABLED',
        defaultValue: true,
      )) {
    return null; // No native Store subscription/restore/purchase.
  }
  final auth = ref.watch(authStateProvider);
  final owner = auth.isLoading || auth.hasError ? null : auth.value?.userId;
  final verifier = ref.watch(purchaseVerifierProvider);
  if (verifier == null || owner == null) return null;
  final controller = IapController(
    verifier: verifier,
    accountId: owner,
    onBalanceChanged: () {
      ref.invalidate(creditBalanceProvider);
      ref.invalidate(purchaseHistoryProvider);
    },
  );
  ref.onDispose(controller.dispose);
  return controller;
});
