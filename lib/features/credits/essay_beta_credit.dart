import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';
import 'credit_balance.dart';

class EssayBetaCredit {
  const EssayBetaCredit(
    this.available,
    this.expiresAt, {
    this.ended = false,
    this.dailyLimit = 1,
    this.endsAt,
    this.campaignId,
    this.policyVersion,
    this.noticeId,
    this.noticeSeen = true,
  });
  final int available;
  final int dailyLimit;
  final DateTime expiresAt;
  final bool ended;
  final DateTime? endsAt;
  final String? campaignId, policyVersion, noticeId;
  final bool noticeSeen;
  static EssayBetaCredit? parse(Map<String, dynamic> data) {
    if (data['version'] != 'essay-beta-credit-v2') {
      throw const FormatException('Unknown beta credit contract');
    }
    if (data['active'] == false && data['status'] == 'inactive') return null;
    final end = DateTime.tryParse(data['ends_at']?.toString() ?? '');
    if (data['active'] == false && data['status'] == 'ended' && end != null) {
      return EssayBetaCredit(0, end, ended: true, endsAt: end);
    }
    final count = data['available'];
    final limit = data['daily_limit'] ?? 1;
    final expiry = DateTime.tryParse(data['expires_at']?.toString() ?? '');
    if (data['active'] != true ||
        data['status'] != 'active' ||
        count is! int ||
        count < 0 ||
        limit is! int ||
        limit < 1 ||
        limit > 100 ||
        count > limit ||
        expiry == null ||
        end == null ||
        data['campaign_id'] is! String ||
        data['policy_version'] is! String ||
        data['notice_seen'] is! bool) {
      throw const FormatException('Invalid beta credit balance');
    }
    return EssayBetaCredit(
      count,
      expiry,
      dailyLimit: limit,
      endsAt: end,
      campaignId: data['campaign_id'] as String,
      policyVersion: data['policy_version'] as String,
      noticeId: data['notice_id'] as String?,
      noticeSeen: data['notice_seen'] as bool,
    );
  }
}

String betaEndDate(DateTime end) {
  final lastDay = end
      .toUtc()
      .add(const Duration(hours: 9))
      .subtract(const Duration(milliseconds: 1));
  if (lastDay.hour != 23 || lastDay.minute != 59) {
    final exact = end.toUtc().add(const Duration(hours: 9));
    return '${exact.year}년 ${exact.month}월 ${exact.day}일 ${exact.hour.toString().padLeft(2, '0')}:${exact.minute.toString().padLeft(2, '0')} KST';
  }
  return '${lastDay.year}년 ${lastDay.month}월 ${lastDay.day}일 23:59';
}

String betaPolicyText(DateTime end, [int limit = 1]) =>
    '인문논술 서비스를 매일 무료 첨삭 $limit회 이용할 수 있어요.\n\n'
    '매일 0시(자정, 한국 시간)에 무료 첨삭 이용 횟수가 갱신되며 미사용분은 소멸돼요.\n\n'
    '베타 서비스는 ${betaEndDate(end)}까지 운영돼요. '
    '베타 무료 첨삭권과 무료 재첨삭은 베타 서비스 기간 동안만 이용할 수 있어요.\n\n'
    '가입 축하 무료 크레딧(3개)과 구매 크레딧은 기존 정책대로 이용할 수 있어요.\n\n'
    '사용 중 불편한 점은 MY 설정의 문의·건의사항으로 알려주세요. '
    '공지사항에서 안내를 다시 확인할 수 있어요.';

final essayBetaCreditProvider = FutureProvider.autoDispose<EssayBetaCredit?>((
  ref,
) async {
  final owner = ref.watch(authStateProvider).value?.userId;
  final client = ref.watch(supabaseClientProvider);
  if (owner == null || client == null) return null;
  try {
    final data = await client.rpc<Map<String, dynamic>>(
      'essay_beta_daily_status_v2',
    );
    if (!ref.mounted || ref.read(authStateProvider).value?.userId != owner) {
      return null;
    }
    final result = EssayBetaCredit.parse(data);
    if (result != null && !result.ended) {
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

/// Read-only status on entry/start. Allocation is confined to submission.
class EssayBetaCreditEntry extends ConsumerStatefulWidget {
  const EssayBetaCreditEntry({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<EssayBetaCreditEntry> createState() =>
      _EssayBetaCreditEntryState();
}

class _EssayBetaCreditEntryState extends ConsumerState<EssayBetaCreditEntry>
    with WidgetsBindingObserver {
  final Set<String> _shown = {};
  Future<void> _showPolicy(EssayBetaCredit value, String owner) async {
    final key =
        'beta-onboarding:$owner:${value.campaignId}:${value.policyVersion}';
    if (value.ended || !_shown.add(key)) return;
    final preferences = await SharedPreferences.getInstance();
    if (!mounted ||
        preferences.getBool(key) == true ||
        (ref.read(authStateProvider).value?.userId ?? 'guest') != owner) {
      return;
    }
    var hide = false;
    var busy = false;
    String? message;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: const Text('논술 LAB 베타 서비스 안내'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(betaPolicyText(value.endsAt!, value.dailyLimit)),
              CheckboxListTile(
                value: hide,
                onChanged: busy ? null : (v) => update(() => hide = v ?? false),
                title: const Text('다음부터 보지 않기'),
              ),
              if (message != null) Text(message!),
            ],
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(context),
              child: const Text('확인/닫기'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      update(() => busy = true);
                      try {
                        if (owner == 'guest' ||
                            ref.read(authStateProvider).value?.userId !=
                                owner) {
                          if (context.mounted) Navigator.pop(context);
                          if (mounted) {
                            await this.context.push('/auth', extra: true);
                          }
                          return;
                        }
                        final latest = await ref.refresh(
                          essayBetaCreditProvider.future,
                        );
                        if (!context.mounted) return;
                        if (latest == null ||
                            latest.ended ||
                            latest.available == 0) {
                          update(() {
                            busy = false;
                            message = latest?.ended == true
                                ? '베타 무료 첨삭 제공이 종료되었습니다.'
                                : latest == null
                                ? '베타 무료 이용 활성화를 준비 중입니다.'
                                : '오늘의 무료 첨삭을 모두 사용했습니다.';
                          });
                          return;
                        }
                        if (hide) await preferences.setBool(key, true);
                        if (context.mounted) Navigator.pop(context);
                      } catch (_) {
                        if (context.mounted) {
                          update(() {
                            busy = false;
                            message = '이용 가능 여부를 확인하지 못했어요. 다시 시도해 주세요.';
                          });
                        }
                      }
                    },
              child: Text(busy ? '확인 중…' : '무료 첨삭 이용하러 가기'),
            ),
          ],
        ),
      ),
    );
    if (hide) await preferences.setBool(key, true);
  }

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
    final owner = ref.watch(authStateProvider).value?.userId;
    final introduction =
        value ??
        EssayBetaCredit(
          0,
          DateTime.utc(2026, 11, 10, 15),
          endsAt: DateTime.utc(2026, 11, 10, 15),
          campaignId: 'beta-202611',
          policyVersion: 'daily-v2',
        );
    if (!state.isLoading &&
        !introduction.ended &&
        introduction.endsAt!.isAfter(DateTime.now())) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ref.read(authStateProvider).value?.userId == owner) {
          unawaited(_showPolicy(introduction, owner ?? 'guest'));
        }
      });
    }
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
        else if (value != null &&
            (value.ended || value.expiresAt.isAfter(DateTime.now())))
          Material(
            child: SafeArea(
              bottom: false,
              child: ListTile(
                title: Text(
                  value.ended
                      ? '베타 무료 첨삭 제공이 종료되었습니다.'
                      : value.available > 0
                      ? '오늘의 무료 첨삭 · ${value.available}회 남음'
                      : '오늘의 무료 첨삭을 모두 사용했습니다.',
                ),
                subtitle: Text(
                  value.ended
                      ? '가입·구매 Credit은 기존 정책대로 이용할 수 있어요.'
                      : '매일 00시(자정, 한국 시간) 갱신 · 이월 없음\n${value.available == 0 && value.expiresAt.isBefore(value.endsAt!) ? '다음 이용: 내일 00:00 KST · ' : ''}${betaEndDate(value.endsAt!)}까지',
                ),
                trailing: TextButton(
                  onPressed: () => context.push(
                    value.noticeId == null
                        ? '/notices'
                        : '/notices/${value.noticeId}',
                  ),
                  child: const Text('공지'),
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
