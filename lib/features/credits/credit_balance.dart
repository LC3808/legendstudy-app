import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';

/// Read-only canonical ledger snapshot shared with LAB credit-v1.
class CreditBalance {
  CreditBalance.fromJson(Map<String, dynamic> json)
    : spendable = json['spendable'] as int,
      paid = json['paid'] as int,
      free = json['free'] as int,
      other = json['other'] as int,
      nextExpiry = json['next_expiry'] as String? {
    if (json['dto_version'] != 'credit-v1' ||
        [spendable, paid, free, other].any((v) => v < 0) ||
        spendable != paid + free + other) {
      throw const FormatException('Invalid credit summary');
    }
  }
  final int spendable, paid, free, other;
  final String? nextExpiry;
}

final creditBalanceProvider = FutureProvider.autoDispose<CreditBalance?>((
  ref,
) async {
  final owner = ref.watch(authStateProvider).value?.userId;
  final client = ref.watch(supabaseClientProvider);
  if (owner == null || client == null) return null;
  final data = await client.rpc<Map<String, dynamic>>('credit_summary');
  if (!ref.mounted || ref.read(authStateProvider).value?.userId != owner) return null;
  return CreditBalance.fromJson(data);
});

class CreditBalanceCard extends ConsumerWidget {
  const CreditBalanceCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(creditBalanceProvider)
        .when(
          loading: () => const ListTile(title: Text('Credit 조회 중')),
          error: (_, _) => ListTile(
            title: const Text('Credit을 확인하지 못했어요.'),
            trailing: IconButton(
              onPressed: () => ref.invalidate(creditBalanceProvider),
              icon: const Icon(Icons.refresh),
            ),
          ),
          data: (balance) => balance == null
              ? const SizedBox.shrink()
              : ListTile(
                  title: Text('사용 가능 ${balance.spendable} Credits'),
                  subtitle: Text(
                    '구매 ${balance.paid} · 가입 무료 ${balance.free} · 기타 ${balance.other}'
                    '${balance.nextExpiry == null ? '' : '\n가장 가까운 만료: ${DateTime.parse(balance.nextExpiry!).toLocal()}'}',
                  ),
                  trailing: IconButton(
                    onPressed: () => ref.invalidate(creditBalanceProvider),
                    icon: const Icon(Icons.refresh),
                  ),
                ),
        );
  }
}
