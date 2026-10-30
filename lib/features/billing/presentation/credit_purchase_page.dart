import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../analytics/analytics_guard.dart';
import '../../analytics/analytics_providers.dart';
import '../../analytics/domain/analytics_events.dart';
import '../../credits/credit_balance.dart';
import '../billing_providers.dart';
import '../credit_product.dart';
import '../iap_controller.dart';
import 'purchase_history.dart';

/// 논술 크레딧 구매 — Apple IAP / Google Play Billing (consumable).
///
/// The screen only *starts* a store purchase and shows its state; Credit is
/// granted server-side and the balance is re-read from `credit_summary`. On a
/// platform without store billing it shows an unavailable state and never
/// offers an external (Toss) purchase as a workaround.
class CreditPurchasePage extends ConsumerStatefulWidget {
  const CreditPurchasePage({super.key});
  @override
  ConsumerState<CreditPurchasePage> createState() => _CreditPurchasePageState();
}

class _CreditPurchasePageState extends ConsumerState<CreditPurchasePage> {
  IapController? _controller;
  bool _showHistory = false;
  BillingPhase? _lastPhase;

  @override
  void initState() {
    super.initState();
    // Behaviour event: viewing the credit pricing screen (GA4). Not a purchase.
    ref
        .read(analyticsServiceProvider)
        .logEventOnce('credit_pricing_view', AnalyticsEvents.creditPricingView);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final authed =
        !auth.isLoading &&
        !auth.hasError &&
        auth.value?.isAuthenticated == true;
    final controller = ref.watch(iapControllerProvider);
    // Behaviour signal only; the server ledger remains the official record of a
    // completed purchase and revenue, never this GA4 event.
    if (controller != null && controller.phase != _lastPhase) {
      _lastPhase = controller.phase;
      final analytics = ref.read(analyticsServiceProvider);
      if (controller.phase == BillingPhase.success) {
        analytics.logEvent(AnalyticsEvents.creditPurchaseSuccess);
      } else if (controller.phase == BillingPhase.error) {
        analytics.logEvent(AnalyticsEvents.creditPurchaseFailed);
      }
    }
    if (!identical(controller, _controller)) {
      _controller = controller;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(controller, _controller)) controller?.init();
      });
    }
    if (!authed) {
      return ShellPage(
        children: [
          const SectionHeader('크레딧 구매'),
          const Text('크레딧은 계정에 적립돼요. 먼저 로그인해 주세요.'),
          const SizedBox(height: AppTokens.space16),
          GuestAccountPrompt(onLogin: () => context.push('/auth')),
        ],
      );
    }

    final tabs = Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('충전'),
          selected: !_showHistory,
          onSelected: (_) => setState(() => _showHistory = false),
        ),
        ChoiceChip(
          label: const Text('구매내역'),
          selected: _showHistory,
          onSelected: (_) => setState(() => _showHistory = true),
        ),
      ],
    );
    if (_showHistory) {
      return PopScope<Object?>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && mounted) setState(() => _showHistory = false);
        },
        child: ShellPage(
          children: [
            const SectionHeader('크레딧 구매'),
            tabs,
            const SizedBox(height: AppTokens.space12),
            const PurchaseHistory(),
          ],
        ),
      );
    }
    if (controller == null) {
      return ShellPage(
        children: [
          const SectionHeader('크레딧 구매'),
          tabs,
          const Text('지금은 크레딧 구매을 사용할 수 없어요. 잠시 후 다시 시도해 주세요.'),
        ],
      );
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ShellPage(
          children: [
            const SectionHeader('크레딧 구매'),
            tabs,
            const CreditBalanceCard(),
            const SizedBox(height: AppTokens.space12),
            if (controller.loadingProducts)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppTokens.space16),
                child: LinearProgressIndicator(semanticsLabel: '상품 불러오는 중'),
              )
            else if (!controller.available)
              const LsCard(
                child: Text(
                  '현재 이 기기에서는 크레딧 구매을 사용할 수 없어요. '
                  '스토어 결제가 가능한 기기에서 다시 시도해 주세요.',
                ),
              )
            else ...[
              if (controller.message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTokens.space12),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      controller.message!,
                      style: TextStyle(
                        color: controller.phase == BillingPhase.error
                            ? Theme.of(context).colorScheme.error
                            : AppTokens.textSecondary,
                      ),
                    ),
                  ),
                ),
              for (final product in creditProducts) ...[
                _ProductCard(
                  product: product,
                  // Prefer the store's localized price; fall back to approved KRW.
                  priceLabel:
                      controller.storeProducts[product.id]?.price ??
                      formatKrw(product.approvedKrw),
                  purchasable:
                      controller.storeProducts.containsKey(product.id) &&
                      controller.phase != BillingPhase.purchasing &&
                      controller.phase != BillingPhase.pending,
                  onBuy: () {
                    ref.read(analyticsServiceProvider).log(
                      AnalyticsEvents.creditPurchaseStart,
                      params: {AnalyticsParamKeys.productId: product.id},
                    );
                    controller.buy(product);
                  },
                ),
                const SizedBox(height: AppTokens.space12),
              ],
              const Text(
                '결제 후 크레딧은 서버 확인을 거쳐 자동으로 충전돼요. 충전이 지연되면 '
                '잠시 기다리거나 문의·건의로 알려주세요.',
                style: TextStyle(color: AppTokens.textSecondary, fontSize: 12),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.priceLabel,
    required this.purchasable,
    required this.onBuy,
  });
  final CreditProduct product;
  final String priceLabel;
  final bool purchasable;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    return LsCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${product.credits} 크레딧', style: AppTokens.cardTitle),
                const SizedBox(height: 2),
                Text(product.answerSummary, style: AppTokens.secondary),
                const SizedBox(height: 2),
                Text(priceLabel, style: AppTokens.body),
              ],
            ),
          ),
          const SizedBox(width: AppTokens.space12),
          // Purchase is a strong final action → filled (CTA hierarchy).
          FilledButton(
            onPressed: purchasable ? onBuy : null,
            child: const Text('구매'),
          ),
        ],
      ),
    );
  }
}
