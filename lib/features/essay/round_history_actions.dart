import 'dart:convert';

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

class _RoundHistoryActionsState extends ConsumerState<RoundHistoryActions> {
  Map<String, dynamic>? status;
  bool busy = false;
  String? notice;
  bool get current =>
      mounted && ref.read(authStateProvider).value?.userId == widget.owner;
  @override
  void initState() {
    super.initState();
    Future.microtask(() => work(false));
  }

  Future<void> work(bool retry) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final client = ref.read(supabaseClientProvider)!;
      final history = SharedEssayHistory(client, widget.owner);
      history.checkOwner();
      final store = SourceDraftGateway(
        widget.owner,
        'round-retry:${widget.record.id}',
      );
      if (retry) {
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
        } else {
          await ExamSubmissionGateway(client, widget.owner).request({
            'action': 'retry',
            'examId': widget.record.examData['exam_id'],
            'runId': widget.record.id,
            'key': key,
          });
        }
        history.checkOwner();
        final latest = await store.loadDraft();
        await store.saveLocalDraft('', latest.revision);
      }
      final data = await client.rpc<dynamic>(
        widget.record.math ? 'math_session_read' : 'essay_exam_session_status',
        params: {'p_run': widget.record.id},
      );
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
          notice = null;
        });
      }
      if (retry) {
        ref.invalidate(sharedEssayHistoryProvider(widget.owner));
        ref.invalidate(creditBalanceProvider);
      }
    } catch (_) {
      if (current) setState(() => notice = '회차 상태를 확인하지 못했어요. 기존 결과는 보존됩니다.');
    } finally {
      if (current) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (status != null)
        for (final q in status!['questions'] as List)
          Text(
            '${essayExamQuestionLabel(widget.record, q['question_id'] as String)} · ${const {'completed': '완료', 'failed': '재처리 필요', 'processing': '진행 중', 'waiting': '대기 중', 'requested': '대기 중', 'reconciling': '처리 확인 중'}['${q['state']}'.toLowerCase()] ?? '처리 확인 중'}',
          ),
      TextButton(
        onPressed: busy ? null : () => work(false),
        child: const Text('회차 처리 상태 확인'),
      ),
      if (status != null &&
          (widget.record.math
              ? mathSessionRetryable(status!)
              : status!['retry_allowed'] == true))
        OutlinedButton(
          onPressed: busy ? null : () => work(true),
          child: const Text('실패 문항만 재처리 · 0 크레딧'),
        ),
      if (notice != null) Text(notice!),
    ],
  );
}
