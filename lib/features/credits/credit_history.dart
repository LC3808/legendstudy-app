import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';

/// Calendar dates follow the Korean Credit policy, regardless of device zone.
String creditDate(String value) {
  final date = DateTime.parse(value).toUtc().add(const Duration(hours: 9));
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}.${two(date.month)}.${two(date.day)}';
}

final creditHistoryProvider =
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
      // Existing composite FK and owner RLS; no new balance or payment RPC.
      final rows = await client
          .from('credit_transactions')
          .select(
            'created_at,transaction_type,balance_delta,reserved_delta,credit_grants!credit_transactions_grant_id_account_id_fkey(expires_at)',
          )
          .eq('account_id', account['id'] as String)
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(50);
      if (!ref.mounted || ref.read(authStateProvider).value?.userId != owner) {
        return [];
      }
      return rows;
    });

class CreditHistory extends ConsumerWidget {
  const CreditHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(creditHistoryProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('충전·지급·사용 내역 · 최근 50건'),
        const Text('만료일은 한국시간 기준이에요.'),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: history.isLoading
                ? null
                : () => ref.invalidate(creditHistoryProvider),
            icon: const Icon(Icons.refresh),
            label: const Text('새로고침'),
          ),
        ),
        history.when(
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const Text('크레딧 내역을 불러오지 못했어요. 새로고침해 주세요.'),
          data: (rows) => rows.isEmpty
              ? const Text('크레딧 내역이 없어요.')
              : Column(children: [for (final row in rows) _entry(row)]),
        ),
      ],
    );
  }

  Widget _entry(Map<String, dynamic> row) {
    final type = row['transaction_type'];
    final label = switch (type) {
      'purchase' => '구매 충전',
      'signup_bonus' => '가입 무료 지급',
      'reserve' => '사용 대기',
      'release' => '사용 대기 해제',
      'consume' => '사용',
      'refund' => '사용 취소',
      'expiration' => '만료',
      'adjustment' => (row['balance_delta'] as num) < 0 ? '차감 조정' : '추가 지급',
      _ => '지급',
    };
    final reserved = type == 'reserve' || type == 'release';
    final amount = (row[reserved ? 'reserved_delta' : 'balance_delta'] as num)
        .abs();
    final grant = row['credit_grants'] as Map<String, dynamic>?;
    final expiry = grant?['expires_at'] as String?;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$label · 크레딧 $amount개'),
      subtitle: Text(
        '${creditDate(row['created_at'] as String)}\n'
        '${grant == null
            ? '만료 정보 확인 불가'
            : expiry == null
            ? '만료 없음'
            : '만료일 ${creditDate(expiry)}'}',
      ),
      isThreeLine: true,
    );
  }
}
