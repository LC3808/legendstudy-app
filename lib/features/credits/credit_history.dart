import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';

/// Calendar dates follow the Korean Credit policy, regardless of device zone.
String creditDate(String value) {
  final date = DateTime.parse(value).toUtc().add(const Duration(hours: 9));
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}.${two(date.month)}.${two(date.day)}';
}

/// User-facing projection only; never used to calculate the wallet balance.
List<Map<String, dynamic>> userCreditHistory(List<Map<String, dynamic>> rows) {
  final visible = <Map<String, dynamic>>[];
  final consumes = <String, Map<String, dynamic>>{};
  for (final row in rows) {
    final type = row['transaction_type'];
    if (type == 'reserve' || type == 'release') continue;
    final decision = row['decision_id'] as String?;
    if (type == 'consume' && decision != null) {
      final existing = consumes[decision];
      if (existing == null) {
        consumes[decision] = Map<String, dynamic>.from(row);
      } else {
        existing['balance_delta'] =
            (existing['balance_delta'] as num) + (row['balance_delta'] as num);
      }
    } else {
      visible.add(row);
    }
  }
  return [...visible, ...consumes.values]..sort(
    (a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String),
  );
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
            'id,decision_id,created_at,transaction_type,balance_delta,credit_grants!credit_transactions_grant_id_account_id_fkey(expires_at)',
          )
          .eq('account_id', account['id'] as String)
          .not('transaction_type', 'in', '(reserve,release)')
          .order('created_at', ascending: false)
          .order('id', ascending: false)
          .limit(50);
      if (!ref.mounted || ref.read(authStateProvider).value?.userId != owner) {
        return [];
      }
      // Include all grant postings for each selected charge before grouping.
      final ids = rows
          .where(
            (r) =>
                r['transaction_type'] == 'consume' && r['decision_id'] != null,
          )
          .map((r) => r['decision_id'] as String)
          .toSet()
          .toList();
      final complete = ids.isEmpty
          ? <Map<String, dynamic>>[]
          : await client
                .from('credit_transactions')
                .select(
                  'id,decision_id,created_at,transaction_type,balance_delta',
                )
                .eq('account_id', account['id'] as String)
                .eq('transaction_type', 'consume')
                .inFilter('decision_id', ids)
                .limit(1000);
      if (complete.length == 1000) throw StateError('HISTORY_LIMIT');
      if (!ref.mounted || ref.read(authStateProvider).value?.userId != owner) {
        return [];
      }
      return userCreditHistory([
        ...rows.where(
          (r) => r['transaction_type'] != 'consume' || r['decision_id'] == null,
        ),
        ...complete,
      ]).take(50).toList();
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
          data: (rows) => userCreditHistory(rows).isEmpty
              ? const Text('크레딧 내역이 없어요.')
              : Column(
                  children: [
                    for (final row in userCreditHistory(rows)) _entry(row),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _entry(Map<String, dynamic> row) {
    final type = row['transaction_type'];
    final label = switch (type) {
      'purchase' => '크레딧 구매',
      'signup_bonus' => '신규가입 무료',
      'consume' => '논술 첨삭',
      'refund' => '환불',
      'expiration' => '만료',
      'adjustment' => (row['balance_delta'] as num) < 0 ? '크레딧 회수' : '크레딧 지급',
      _ => '크레딧 지급',
    };
    final amount = row['balance_delta'] as num;
    final grant = row['credit_grants'] as Map<String, dynamic>?;
    final expiry = grant?['expires_at'] as String?;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$label · ${amount > 0 ? '+' : ''}$amount 크레딧'),
      subtitle: type == 'consume'
          ? Text(creditDate(row['created_at'] as String))
          : Text(
              '${creditDate(row['created_at'] as String)}\n'
              '${grant == null
                  ? '만료 정보 확인 불가'
                  : expiry == null
                  ? '만료 없음'
                  : '만료일 ${creditDate(expiry)}'}',
            ),
      isThreeLine: type != 'consume',
    );
  }
}
