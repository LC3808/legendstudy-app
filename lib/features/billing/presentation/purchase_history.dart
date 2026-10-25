import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';

/// Existing owner-only ledger reads. Never invokes billing or grant RPCs.
final purchaseHistoryProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
      final auth = ref.watch(authStateProvider);
      final owner = auth.isLoading || auth.hasError ? null : auth.value?.userId;
      final client = ref.watch(supabaseClientProvider);
      if (owner == null || client == null) throw const SignedOutException();
      final account = await client
          .from('credit_accounts')
          .select('id')
          .eq('user_id', owner)
          .maybeSingle();
      if (account == null) return [];
      final rows = await client
          .from('credit_transactions')
          .select('created_at,balance_delta,reason_code')
          .eq('account_id', account['id'] as String)
          .eq('transaction_type', 'purchase')
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(50);
      if (!ref.mounted || ref.read(authStateProvider).value?.userId != owner) {
        return [];
      }
      return rows;
    });

class PurchaseHistory extends ConsumerWidget {
  const PurchaseHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(purchaseHistoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('크레딧 지급이 완료된 구매 내역 · 최근 50건'),
        const Text('무료 지급은 포함하지 않아요. 검증 중이거나 취소된 스토어 주문은 여기에 표시되지 않아요.'),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: history.isLoading
                ? null
                : () => ref.invalidate(purchaseHistoryProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('새로고침'),
          ),
        ),
        history.when(
          loading: () =>
              const LinearProgressIndicator(semanticsLabel: '구매내역 조회 중'),
          error: (_, _) => const Text('구매내역을 불러오지 못했어요. 새로고침해 주세요.'),
          data: (rows) => rows.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('지급 완료된 구매 내역이 없어요.'),
                )
              : Column(
                  children: [
                    for (final row in rows) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${row['balance_delta']} 크레딧 구매'),
                        subtitle: Text(
                          '${switch (row['reason_code']) {
                            'iap_google_v1' => 'Google Play',
                            'iap_apple_v1' => 'App Store',
                            _ => '크레딧 구매',
                          }} · ${_date(row['created_at'] as String)}',
                        ),
                      ),
                      const Divider(),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  String _date(String value) {
    final d = DateTime.parse(value).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}.${two(d.month)}.${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}
