import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';
import 'credit_balance.dart';

class EssayBetaCredit {
  const EssayBetaCredit(this.available, this.expiresAt);
  final int available;
  final DateTime expiresAt;
  static EssayBetaCredit? parse(Map<String, dynamic> data) {
    if (data['version'] != 'essay-beta-credit-v1') {
      throw const FormatException('Unknown beta credit contract');
    }
    if (data['active'] == false) return null;
    final count = data['available'];
    final expiry = DateTime.tryParse(data['expires_at']?.toString() ?? '');
    if (data['active'] != true ||
        count is! int ||
        count < 0 ||
        count > 2 ||
        expiry == null) {
      throw const FormatException('Invalid beta credit balance');
    }
    return EssayBetaCredit(count, expiry);
  }
}

final essayBetaCreditProvider = FutureProvider.autoDispose<EssayBetaCredit?>((
  ref,
) async {
  final owner = ref.watch(authStateProvider).value?.userId;
  final client = ref.watch(supabaseClientProvider);
  if (owner == null || client == null) return null;
  try {
    final data = await client.rpc<Map<String, dynamic>>(
      'essay_beta_daily_claim',
    );
    if (!ref.mounted || ref.read(authStateProvider).value?.userId != owner) {
      return null;
    }
    final result = EssayBetaCredit.parse(data);
    if (result != null) {
      ref.invalidate(creditBalanceProvider);
      final wait = result.expiresAt.difference(DateTime.now());
      final timer = Timer(
        wait.isNegative
            ? const Duration(seconds: 1)
            : wait + const Duration(milliseconds: 100),
        () {
          ref.invalidateSelf();
        },
      );
      ref.onDispose(timer.cancel);
    }
    return result;
  } on PostgrestException catch (error) {
    // Additive RPC can be staged before its separate Production SQL approval.
    if (error.code == 'PGRST202') return null;
    rethrow;
  }
}, retry: (_, _) => null);

/// Mounted only inside LAB; no grant calls from login, MY or app startup.
class EssayBetaCreditEntry extends ConsumerStatefulWidget {
  const EssayBetaCreditEntry({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<EssayBetaCreditEntry> createState() =>
      _EssayBetaCreditEntryState();
}

class _EssayBetaCreditEntryState extends ConsumerState<EssayBetaCreditEntry>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(essayBetaCreditProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(creditBalanceProvider, (previous, next) {
      final before = previous?.value;
      final after = next.value;
      if (before != null &&
          after != null &&
          before.spendable != after.spendable) {
        ref.invalidate(essayBetaCreditProvider);
      }
    });
    final state = ref.watch(essayBetaCreditProvider);
    final value = state.value;
    return Column(
      children: [
        if (state.hasError)
          Material(
            child: SafeArea(
              bottom: false,
              child: ListTile(
                title: const Text('베타 첨삭권을 확인하지 못했어요.'),
                trailing: TextButton(
                  onPressed: () => ref.invalidate(essayBetaCreditProvider),
                  child: const Text('다시 확인'),
                ),
              ),
            ),
          )
        else if (value != null && value.expiresAt.isAfter(DateTime.now()))
          Material(
            child: SafeArea(
              bottom: false,
              child: ListTile(
                title: Text('오늘 남은 베타 첨삭권 ${value.available}개'),
                subtitle: const Text(
                  '매일 첫 접속 시 2개 지급 · 자정 만료 · 베타 대상 시험 전용',
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
