import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';
import '../credits/credit_balance.dart';
import 'math_gateway.dart';
import 'shared_history.dart';
import 'evaluation_report_view.dart';
import 'evaluation_report.dart';

class MathWorkspacePage extends ConsumerWidget {
  const MathWorkspacePage({this.evaluationId, super.key});
  final String? evaluationId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final owner = auth.isLoading || auth.hasError ? null : auth.value?.userId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('수리논술'),
        actions: [
          IconButton(
            tooltip: '나의 첨삭 기록',
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/lab/essay/history'),
          ),
        ],
      ),
      body: owner == null
          ? Center(
              child: TextButton(
                onPressed: () => context.push('/auth'),
                child: const Text('로그인 후 내 답안을 작성하세요.'),
              ),
            )
          : _MathWorkspace(
              key: ValueKey('$owner/$evaluationId'),
              owner: owner,
              evaluationId: evaluationId,
            ),
    );
  }
}

class _MathWorkspace extends ConsumerStatefulWidget {
  const _MathWorkspace({super.key, required this.owner, this.evaluationId});
  final String owner;
  final String? evaluationId;
  @override
  ConsumerState<_MathWorkspace> createState() => _MathWorkspaceState();
}

class _MathWorkspaceState extends ConsumerState<_MathWorkspace> {
  final answer = TextEditingController();
  String? leaf, attempt, evaluation, notice;
  String submissionKey = mathRequestId(), evaluationKey = mathRequestId();
  bool busy = false, frozen = false;
  Map<String, dynamic>? state, prior;
  ({EvaluationReport report, EvaluationReport? before})? report;
  MathGateway get gateway => ref.read(mathGatewayProvider(widget.owner))!;
  bool get current =>
      mounted && ref.read(authStateProvider).value?.userId == widget.owner;
  @override
  void initState() {
    super.initState();
    evaluation = widget.evaluationId;
    if (evaluation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) run(refresh);
      });
    }
  }

  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() work) async {
    if (busy) {
      return;
    }
    setState(() {
      busy = true;
      notice = null;
    });
    try {
      await work();
    } catch (error) {
      if (current) {
        setState(
          () => notice = error is PostgrestException && error.code == 'PT402'
              ? '사용 가능한 Credit 또는 포함 재첨삭 조건을 확인해 주세요.'
              : '처리 결과를 확인하지 못했어요. 같은 요청으로 다시 확인해 주세요. 새 답안의 첨삭을 중복 요청하지 마세요.',
        );
      }
    } finally {
      if (current) {
        ref.invalidate(creditBalanceProvider);
        ref.invalidate(sharedEssayHistoryProvider(widget.owner));
        setState(() => busy = false);
      }
    }
  }

  Future<void> refresh() async {
    final id = evaluation;
    if (id == null) return;
    final next = await gateway.call('math_learning', 'read_learning_state', {
      'evaluation_id': id,
    });
    if (!current) return;
    setState(() {
      state = next;
      leaf = next['leaf_id'] as String? ?? leaf;
    });
    if (next['valid_evaluation_available'] == true) {
      final data = await SharedEssayHistory(
        gateway.client,
        widget.owner,
      ).evaluationReport(true, id);
      if (current) setState(() => report = data);
    } else if (current) {
      setState(
        () => notice = next['evaluation_state'] == 'FAILED'
            ? '첨삭이 완료되지 않았어요. Credit 잔액과 기록을 확인해 주세요.'
            : '첨삭 처리 중이거나 결과 확인이 필요해요. 잠시 후 다시 확인해 주세요.',
      );
    }
  }

  Future<void> submit() async {
    if (!await gateway.available()) throw StateError('UNAVAILABLE');
    if (!current) return;
    if (evaluation != null) {
      await resumeEvaluation();
      return;
    }
    if (leaf == null || answer.text.trim().isEmpty) return;
    if (!await gateway.available()) throw StateError('CLOSED');
    if (!current) return;
    // Freeze before the first request: a lost response must retry identical payload/key.
    setState(() => frozen = true);
    if (attempt == null) {
      final data = await gateway.call(
        prior == null ? 'math_input' : 'math_learning',
        prior == null ? 'create_attempt' : 'create_resolve_attempt',
        {
          'client_submission_id': submissionKey,
          'leaf_id': leaf,
          'kind': prior == null
              ? 'INITIAL'
              : prior!['response_format'] == 'SHORT_ANSWER'
              ? 'SHORT_ANSWER_RESOLVE'
              : 'FULL_RESOLVE',
          'input_kind': 'TYPED',
          'typed_answer': answer.text,
          if (prior != null) ...{
            'predecessor_id': prior!['attempt_id'],
            'prior_evaluation_id': prior!['evaluation_id'],
          },
        },
      );
      if (!current) return;
      setState(() => attempt = data['attempt_id'] as String);
    }
    final input = await gateway.call('math_input', 'read_input', {
      'attempt_id': attempt,
    });
    if (input['can_request_evaluation'] != true) throw StateError('NOT_READY');
    if (evaluation == null) {
      final data = await gateway.call(
        prior == null ? 'math_input' : 'math_learning',
        prior == null ? 'request_evaluation' : 'request_reevaluation',
        {'attempt_id': attempt, 'client_submission_id': evaluationKey},
      );
      if (!current) return;
      setState(() => evaluation = data['evaluation_id'] as String);
    }
    try {
      await gateway.evaluate(evaluation!);
    } finally {
      if (current) await refresh();
    }
  }

  Future<void> resumeEvaluation() async {
    await refresh();
    if (current && state?['evaluation_state'] == 'REQUESTED') {
      try {
        await gateway.evaluate(evaluation!);
      } finally {
        if (current) await refresh();
      }
    }
  }

  void rewrite() {
    final old = state;
    if (old?['valid_evaluation_available'] != true ||
        (old?['included_reevaluation'] as Map?)?['eligible'] != true) {
      return;
    }
    setState(() {
      prior = old;
      state = null;
      attempt = null;
      evaluation = null;
      report = null;
      submissionKey = mathRequestId();
      evaluationKey = mathRequestId();
      frozen = false;
      answer.clear();
      notice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(mathCatalogProvider(widget.owner));
    final canEvaluate =
        ref.watch(mathEvaluationAvailableProvider(widget.owner)).value == true;
    return catalog.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(mathCatalogProvider(widget.owner)),
          child: const Text('문항 다시 불러오기'),
        ),
      ),
      data: (rows) {
        final selected =
            leaf ?? (rows.isEmpty ? null : rows.first['leaf_id'] as String);
        final match = rows.where((r) => r['leaf_id'] == selected);
        final question = match.isEmpty ? null : match.first;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const CreditBalanceCard(),
            const Text(
              '1 Credit으로 최초 첨삭 1회와 14일 이내 같은 답안의 재첨삭 1회를 이용할 수 있어요. ',
            ),
            if (!canEvaluate) const Text('문항을 확인할 수 있어요. 현재 첨삭은 이용할 수 없습니다.'),
            if (notice != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(notice!, semanticsLabel: notice),
              ),
            if (rows.isEmpty) const Text('현재 이용 가능한 첨삭 문항이 없습니다.'),
            if (rows.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: selected,
                key: ValueKey(selected),
                isExpanded: true,
                decoration: const InputDecoration(labelText: '문제 선택'),
                items: [
                  for (final q in rows)
                    DropdownMenuItem(
                      value: q['leaf_id'] as String,
                      child: Text(q['label'] as String),
                    ),
                ],
                onChanged: busy || frozen || prior != null || evaluation != null
                    ? null
                    : (v) => setState(() => leaf = v),
              ),
              if (question != null) ...[
                SelectableText(question['problem_statement'] as String? ?? ''),
                SelectableText(question['statement'] as String? ?? ''),
              ],
              if (report == null &&
                  (widget.evaluationId == null || prior != null)) ...[
                TextField(
                  controller: answer,
                  enabled: !busy && !frozen,
                  minLines: 6,
                  maxLines: 12,
                  maxLength: 30000,
                  decoration: InputDecoration(
                    labelText: prior == null ? '내 답안' : '다시 작성한 답안',
                  ),
                ),
                FilledButton(
                  onPressed: busy || !canEvaluate
                      ? null
                      : () {
                          leaf = selected;
                          run(submit);
                        },
                  child: Text(
                    busy
                        ? '첨삭을 확인하고 있어요…'
                        : frozen
                        ? '같은 요청 다시 확인'
                        : prior == null
                        ? '첨삭 진행'
                        : '재첨삭',
                  ),
                ),
              ],
            ],
            if (evaluation != null)
              OutlinedButton(
                onPressed: busy ? null : () => run(refresh),
                child: const Text('결과·Credit 다시 확인'),
              ),
            if (evaluation != null && state?['evaluation_state'] == 'REQUESTED')
              OutlinedButton(
                onPressed: busy || !canEvaluate
                    ? null
                    : () => run(resumeEvaluation),
                child: const Text('같은 첨삭 처리 다시 요청'),
              ),
            if (report != null) ...[
              OutlinedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('첨삭 결과')),
                      body: _OwnerReport(owner: widget.owner, report: report!),
                    ),
                  ),
                ),
                child: const Text('첨삭 결과 · 성장 분석 보기'),
              ),
              if ((state?['included_reevaluation'] as Map?)?['eligible'] ==
                      true &&
                  rows.isNotEmpty)
                FilledButton(
                  onPressed: busy ? null : rewrite,
                  child: const Text('다시 작성하기 · 포함 재첨삭'),
                ),
            ],
            TextButton(
              onPressed: () => context.push('/lab/essay/history'),
              child: const Text('나의 첨삭 기록'),
            ),
          ],
        );
      },
    );
  }
}

class _OwnerReport extends ConsumerWidget {
  const _OwnerReport({required this.owner, required this.report});
  final String owner;
  final ({EvaluationReport report, EvaluationReport? before}) report;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return !auth.isLoading && !auth.hasError && auth.value?.userId == owner
        ? EvaluationReportView(report: report.report, before: report.before)
        : const Center(child: Text('로그인 상태가 변경되었습니다.'));
  }
}
