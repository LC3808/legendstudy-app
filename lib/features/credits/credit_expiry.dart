import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import 'credit_history.dart';

Map<String, int> expiryQuantities(
  List<Map<String, dynamic>> grants,
  List<Map<String, dynamic>> transactions,
) {
  final balances = <String, int>{};
  for (final t in transactions) {
    final balance = t['balance_delta'], reserved = t['reserved_delta'];
    if (balance is! int || reserved is! int) {
      throw const FormatException('INVALID_LEDGER');
    }
    final id = t['grant_id'] as String;
    balances[id] = (balances[id] ?? 0) + balance - reserved;
  }
  final result = <String, int>{};
  for (final g in grants) {
    final n = balances[g['id']] ?? 0;
    if (n < 0) throw const FormatException('INVALID_LEDGER');
    if (n == 0) continue;
    final label = g['origin'] == 'purchase'
        ? '구매 크레딧'
        : g['origin'] == 'signup_bonus'
        ? '무료 크레딧'
        : '기타 지급 크레딧';
    result[label] = (result[label] ?? 0) + n;
  }
  return result;
}

final creditExpiryProvider = FutureProvider.autoDispose
    .family<Map<String, int>, String>((ref, at) async {
      final owner = ref.watch(authStateProvider).value?.userId,
          client = ref.watch(supabaseClientProvider);
      if (owner == null || client == null) throw const SignedOutException();
      final account = await client
          .from('credit_accounts')
          .select('id')
          .eq('user_id', owner)
          .single();
      final grants = await client
          .from('credit_grants')
          .select('id,origin,expires_at')
          .eq('account_id', account['id'] as String)
          .eq('expires_at', at)
          .limit(1000);
      if (grants.isEmpty || grants.length == 1000) {
        throw StateError('EXPIRY_UNAVAILABLE');
      }
      final tx = await client
          .from('credit_transactions')
          .select('grant_id,balance_delta,reserved_delta')
          .eq('account_id', account['id'] as String)
          .inFilter('grant_id', grants.map((g) => g['id'] as String).toList())
          .limit(1000);
      if (!ref.mounted || ref.read(authStateProvider).value?.userId != owner) {
        throw const SignedOutException();
      }
      if (tx.length == 1000) throw StateError('HISTORY_LIMIT');
      final groups = expiryQuantities(grants, tx);
      if (groups.isEmpty) throw StateError('EXPIRY_UNAVAILABLE');
      return groups;
    });

class CreditExpiry extends ConsumerWidget {
  const CreditExpiry({required this.at, super.key});
  final String at;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(creditExpiryProvider(at))
      .when(
        loading: () => const Text('만료 예정 크레딧 확인 중'),
        error: (_, _) => TextButton(
          onPressed: () => ref.invalidate(creditExpiryProvider(at)),
          child: const Text('만료 수량 다시 확인'),
        ),
        data: (groups) => Text(
          '${creditDate(at)}\n${groups.entries.map((e) => '${e.key} ${e.value}개 만료 예정').join('\n')}',
        ),
      );
}
