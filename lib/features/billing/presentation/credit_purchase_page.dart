import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/shell_widgets.dart';
import '../../credits/credit_balance.dart';
import '../billing_providers.dart';
import '../credit_product.dart';
import '../iap_controller.dart';

/// 논술 Credit 충전 — Apple IAP / Google Play Billing (consumable).
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

  @override
  void initState() {
    super.initState();
    _controller = ref.read(iapControllerProvider);
    _controller?.init();
  }

  @override
  Widget build(BuildContext context) {
    final authed = ref.watch(authStateProvider).value?.isAuthenticated == true;
    if (!authed) {
      return ShellPage(
        children: [
          const SectionHeader('Credit 충전'),
          const Text('Credit은 계정에 적립돼요. 먼저 로그인해 주세요.'),
          const SizedBox(height: AppTokens.space16),
          GuestAccountPrompt(onLogin: () => context.push('/auth')),
        ],
      );
    }

    final controller = _controller;
    if (controller == null) {
      return const ShellPage(
        children: [
          SectionHeader('Credit 충전'),
          Text('지금은 Credit 충전을 사용할 수 없어요. 잠시 후 다시 시도해 주세요.'),
        ],
      );
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return ShellPage(
          children: [
            const SectionHeader('Credit 충전'),
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
                  '현재 이 기기에서는 Credit 충전을 사용할 수 없어요. '
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
                  purchasable: controller.storeProducts.containsKey(product.id) &&
                      controller.phase != BillingPhase.purchasing &&
                      controller.phase != BillingPhase.pending,
                  onBuy: () => controller.buy(product),
                ),
                const SizedBox(height: AppTokens.space12),
              ],
              const Text(
                '결제 후 Credit은 서버 확인을 거쳐 자동으로 충전돼요. 충전이 지연되면 '
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
                Text('${product.credits} Credit', style: AppTokens.cardTitle),
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
