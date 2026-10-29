import 'dart:convert';
import 'dart:async';

import 'exam_session_status.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../credits/credit_balance.dart';
import 'exam_submission.dart';
import 'math_gateway.dart';
import 'math_exam_session.dart';
import 'shared_history.dart';
import 'source_draft.dart';

class RoundHistoryActions extends ConsumerStatefulWidget {
  const RoundHistoryActions({
    required this.owner,
    required this.record,
    super.key,
  });
  final String owner;
  final SharedEssayRecord record;
  @override
  ConsumerState<RoundHistoryActions> createState() =>
      _RoundHistoryActionsState();
}

class _RoundHistoryActionsState extends ConsumerState<RoundHistoryActions>
    with WidgetsBindingObserver {
  Timer? refreshTimer;
  bool foreground = true;
  @override
  void dispose() {
    refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    refreshTimer?.cancel();
    if (foreground) unawaited(work(false));
  }

  Map<String, dynamic>? status;
  bool busy = false;
  String? notice;
  bool get current =>
      mounted && ref.read(authStateProvider).value?.userId == widget.owner;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => work(false));
  }

  Future<void> work(bool retry, {bool manual = false}) async {
    if (busy || !current) return;
    refreshTimer?.cancel();
    final before = jsonEncode(status);
    setState(() => busy = true);
    try {
      final client = ref.read(supabaseClientProvider)!;
      final history = SharedEssayHistory(client, widget.owner);
      history.checkOwner();
      final store = SourceDraftGateway(
        widget.owner,
        'round-retry:${widget.record.id}',
      );
      if (retry && !widget.record.math) {
        final api = ref.read(examSubmissionGatewayProvider(widget.owner));
        if (api == null) throw StateError('로그인 상태를 확인해 주세요.');
        await retryExistingExam(
          client: client,
          gateway: api,
          owner: widget.owner,
          run: widget.record.id,
          exam: widget.record.examData['exam_id'] as String,
        );
      }
      if (retry && widget.record.math) {
        final saved = await store.loadDraft();
        final key = saved.body.isEmpty
            ? mathRequestId()
            : (jsonDecode(saved.body) as Map)['key'] as String;
        if (saved.body.isEmpty) {
          await store.saveLocalDraft(jsonEncode({'key': key}), saved.revision);
        }
        if (widget.record.math) {
          final gateway = ref.read(mathGatewayProvider(widget.owner))!;
          await gateway.session('math_session_retry', {
            'p_run': widget.record.id,
            'p_key': key,
          });
          final run = parseMathSession(
            await gateway.session('math_session_read', {
              'p_run': widget.record.id,
            }),
          );
          for (final q in run['questions'] as List) {
            if (q['state'] == 'REQUESTED') {
              try {
                await gateway.evaluate(q['evaluation_id'] as String);
              } catch (_) {
                gateway.checkOwner();
              }
            }
          }
        }
        history.checkOwner();
        final latest = await store.loadDraft();
        await store.saveLocalDraft('', latest.revision);
      }
      final data = widget.record.math
          ? await client
                .rpc<dynamic>(
                  'math_session_read',
                  params: {'p_run': widget.record.id},
                )
                .timeout(const Duration(seconds: 10))
          : (await readExamSessionStatus(
              client,
              widget.owner,
              widget.record.id,
            )).data;
      history.checkOwner();
      if (data is! Map ||
          data['version'] !=
              (widget.record.math ? 'math-session-v1' : 'exam-session-v1') ||
          data['questions'] is! List) {
        throw const FormatException('STATUS');
      }
      if (current) {
        setState(() {
          status = Map<String, dynamic>.from(data);
          if (retry) {
            notice = '실패 문항 재처리가 접수됐어요. 완료된 문항은 보존됩니다.';
          } else if (data['state'] == 'completed') {
            notice = '첨삭이 완료됐어요. 저장된 결과를 확인하세요.';
          } else if (manual) {
            notice = before == jsonEncode(data)
                ? '아직 처리 상태에 변화가 없습니다.'
                : '최신 처리 상태를 확인했어요.';
          }
        });
      }
      if (retry ||
          (before != jsonEncode(data) && data['state'] == 'completed')) {
        ref.invalidate(sharedEssayHistoryProvider(widget.owner));
        ref.invalidate(creditBalanceProvider);
      }
    } catch (_) {
      if (current) {
        setState(() {
          status = null;
          notice = retry
              ? '재처리 접수를 확인하지 못했어요. 상태를 새로고침해 주세요. 기존 답안과 결과는 보존됩니다.'
              : '처리 상태를 확인하지 못했어요. 연결을 확인하고 다시 시도해 주세요.';
        });
      }
    } finally {
      if (current) {
        setState(() => busy = false);
        if (foreground &&
            ![
              'completed',
              'failed',
            ].contains(status?['state']?.toString().toLowerCase())) {
          refreshTimer = Timer(const Duration(seconds: 10), () => work(false));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      if (next.value?.userId == widget.owner && status == null && !busy) {
        unawaited(work(false));
      }
    });
    if (ref.watch(authStateProvider).value?.userId != widget.owner) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (status != null)
          for (final q in status!['questions'] as List)
            Text(
              '${essayExamQuestionLabel(widget.record, q['question_id'] as String)} · ${const {'completed': '완료', 'failed': '재처리 필요', 'processing': '진행 중', 'waiting': '대기 중', 'requested': '대기 중', 'reconciling': '처리 확인 중'}['${q['state']}'.toLowerCase()] ?? '처리 확인 중'}',
            ),
        TextButton(
          onPressed: busy ? null : () => work(false, manual: true),
          child: const Text('회차 처리 상태 확인'),
        ),
        if (status != null &&
            (widget.record.math
                ? mathSessionRetryable(status!)
                : ExamSessionStatus(status!).canRetry))
          OutlinedButton(
            onPressed: busy ? null : () => work(true),
            child: const Text('실패 문항만 재처리 · 0 크레딧'),
          ),
        if (!widget.record.math &&
            status != null &&
            ExamSessionStatus(status!).hasFailure) ...[
          if (!ExamSessionStatus(status!).canRetry)
            const OutlinedButton(onPressed: null, child: Text('실패한 문항 다시 처리')),
          Text(ExamSessionStatus(status!).retryExplanation),
        ],
        if (notice != null) Text(notice!),
      ],
    );
  }
}
