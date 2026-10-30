import 'package:go_router/go_router.dart';

import 'result_pdf.dart';
import 'round_history_actions.dart';
import 'growth_bars.dart';
import 'result_disclosure.dart';

import 'dart:async';

import 'essay_voice.dart';
import '../../core/theme/app_theme.dart';
import 'approved_result_adapter.dart';
import 'essay_pages.dart';
import 'essay_models.dart';
import 'source_catalog_page.dart';

import 'math_workspace_page.dart';

import 'evaluation_report.dart';
import 'evaluation_report_view.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import 'shared_history.dart';

class SharedEssayHistoryPage extends ConsumerWidget {
  const SharedEssayHistoryPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final owner = auth.isLoading || auth.hasError ? null : auth.value?.userId;
    return Scaffold(
      appBar: AppBar(title: const Text('나의 첨삭 기록')),
      body: owner == null
          ? const Center(child: Text('로그인 상태를 확인해 주세요.'))
          : _HistoryBody(key: ValueKey(owner), owner: owner),
    );
  }
}

class _HistoryBody extends ConsumerStatefulWidget {
  const _HistoryBody({required this.owner, super.key});
  final String owner;
  @override
  ConsumerState<_HistoryBody> createState() => _HistoryBodyState();
}

class _HistoryBodyState extends ConsumerState<_HistoryBody>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed &&
          ModalRoute.of(context)?.isCurrent == true) {
        _refresh();
      }
    });
  }

  void _refresh() {
    if (mounted && ref.read(authStateProvider).value?.userId == owner) {
      ref.invalidate(sharedEssayHistoryProvider(owner));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool byExam = false;
  String kind = 'all';
  String get owner => widget.owner;
  Future<void> openResult(SharedEssayRecord row, Map<String, dynamic> e) async {
    await openSharedEssayResult(context, ref, owner, row, e);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(sharedEssayHistoryProvider(owner));
    return history.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: false,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(sharedEssayHistoryProvider(owner)),
          child: const Text('기록을 불러오지 못했어요. 다시 시도'),
        ),
      ),
      data: (rows) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(sharedEssayHistoryProvider(owner));
          await ref.read(sharedEssayHistoryProvider(owner).future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SegmentedButton<bool>(
              style: EssayDesign.segmentStyle,
              segments: const [
                ButtonSegment(value: false, label: Text('최신순')),
                ButtonSegment(value: true, label: Text('시험별')),
              ],
              selected: {byExam},
              onSelectionChanged: (v) => setState(() => byExam = v.single),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: kind,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('전체 기록')),
                DropdownMenuItem(value: 'initial', child: Text('최초 첨삭')),
                DropdownMenuItem(value: 'rewrite', child: Text('재첨삭')),
              ],
              onChanged: (v) => setState(() => kind = v ?? 'all'),
            ),
            const SizedBox(height: 16),
            if (rows.isNotEmpty &&
                !rows.any((r) => essayHistoryMatchesKind(r, kind)))
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('해당 분류의 첨삭 기록이 없어요.'),
              ),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('아직 첨삭 기록이 없습니다.'),
              ),
            for (final group in sortedEssayHistory(
              rows.where((r) => essayHistoryMatchesKind(r, kind)).toList(),
              byExam,
            )) ...[
              for (final row in group)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: EssaySurface(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      onTap:
                          row.evaluations.any((e) => e['state'] == 'COMPLETED')
                          ? () => openResult(
                              row,
                              orderedEssayEvaluations(row)
                                  .firstWhere((e) => e['state'] == 'COMPLETED'),
                            )
                          : null,
                      title: Text(
                        row.title,
                        style: AppTokens.cardTitle.copyWith(fontSize: 19),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (row.exam || row.examData['mathSession'] != null)
                            Text(row.examLabel, style: AppTokens.secondary),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                EssayHistoryBadge(record: row),
                                Text(
                                  essayShortDate(row),
                                  style: AppTokens.caption,
                                ),
                              ],
                            ),
                          ),
                          if (row.examData['parent_id'] != null)
                            const Text('최초 첨삭에 이어진 재첨삭'),
                          if (row.evaluations.isEmpty) const Text('평가 요청 전'),
                          if ((row.exam ||
                                  row.examData['mathSession'] != null) &&
                              row.examData['state'] == 'reserved')
                            RoundHistoryActions(
                              key: ValueKey(row.id),
                              owner: owner,
                              record: row,
                            ),
                          if (row.math && row.examData['mathSession'] == null)
                            for (final e in row.evaluations)
                              TextButton(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => MathWorkspacePage(
                                      evaluationId: e['id'] as String,
                                    ),
                                  ),
                                ),
                                child: const Text('처리 상태 · 재첨삭 확인'),
                              ),
                          for (final e in orderedEssayEvaluations(row).where(
                            (e) =>
                                !(row.exam &&
                                    row.examData['state'] == 'reserved'),
                          ))
                            e['state'] == 'COMPLETED'
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: OutlinedButton(
                                      style: OutlinedButton.styleFrom(
                                        minimumSize: const Size.fromHeight(48),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                      ),
                                      onPressed: () => openResult(row, e),
                                      child: Text(
                                        row.exam
                                            ? '${essayExamQuestionLabel(row, (e['id'] as String).split('/').last)} · 첨삭 결과 보기'
                                            : '첨삭 결과 보기',
                                      ),
                                    ),
                                  )
                                : Text(
                                    switch (e['state']) {
                                      'PROCESSING' => '첨삭 중',
                                      'QUEUED' => '대기 중',
                                      'FAILED' => '첨삭 실패',
                                      'INVALIDATED' => '평가 확인 필요',
                                      _ => '상태 확인 필요',
                                    },
                                    style: AppTokens.secondary.copyWith(
                                      color: e['state'] == 'FAILED'
                                          ? AppTokens.dangerInk
                                          : AppTokens.textSecondary,
                                    ),
                                  ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Opens a stored evaluation result on the current navigator. Shared by the
/// history list and the growth-analysis screen so both use one owner-scoped
/// read path and the same `_Result` detail view.
Future<void> openSharedEssayResult(
  BuildContext context,
  WidgetRef ref,
  String owner,
  SharedEssayRecord row,
  Map<String, dynamic> e,
) async {
  final client = ref.read(supabaseClientProvider);
  if (client == null) return;
  try {
    final result = await SharedEssayHistory(
      client,
      owner,
    ).evaluationReport(row.math, e['id'] as String, exam: row.exam);
    if (!context.mounted ||
        ref.read(authStateProvider).value?.userId != owner) {
      return;
    }
    // Detail stays owner-scoped; an account switch removes the caller's page.
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _Result(
          owner: owner,
          report: result.report,
          before: result.before,
          record: row,
          questionId: (e['id'] as String).split('/').last,
        ),
      ),
    );
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('평가를 불러오지 못했어요.')));
    }
  }
}

/// Labels rely on the existing exam contract, not attempt numbering or color alone.
class EssayHistoryBadge extends StatelessWidget {
  const EssayHistoryBadge({super.key, required this.record});
  final SharedEssayRecord record;
  @override
  Widget build(BuildContext context) {
    final included = record.exam && record.examData['parent_id'] != null;
    final label = essayHistoryType(record);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: included
            ? Color.alphaBlend(
                Colors.black.withValues(alpha: 0.2),
                AppTokens.success,
              )
            : AppTokens.textPrimary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _Result extends ConsumerWidget {
  const _Result({
    required this.owner,
    required this.report,
    this.before,
    required this.record,
    required this.questionId,
  });
  final SharedEssayRecord record;
  final String questionId;
  final String owner;
  final EvaluationReport report;
  final EvaluationReport? before;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> openWriter(bool additional) async {
      await EssayVoice.stopActive?.call();
      final client = ref.read(supabaseClientProvider);
      if (client == null) return;
      try {
        final rows = await SharedEssayHistory(
          client,
          owner,
        ).examRuns(record.id);
        if (!context.mounted ||
            ref.read(authStateProvider).value?.userId != owner ||
            rows.length != 1) {
          return;
        }
        if (rows.single['state'] != 'completed') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('현재 회차의 처리가 끝난 뒤 다시 작성할 수 있어요.')),
          );
          return;
        }
        // Prefer the current server entitlement over a stale paid-action label.
        if (rows.single['free_rewrite_available'] == true) additional = false;
        if (!additional && rows.single['free_rewrite_available'] != true) {
          final paid = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('무료 재첨삭을 사용할 수 없어요'),
              content: const Text(
                '무료 기간이 지났거나 이미 사용한 기록입니다. 추가 첨삭은 기존 정책에 따라 1 Credit을 사용합니다. 답안을 다시 작성할까요?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('돌아가기'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('추가 첨삭 답안 작성'),
                ),
              ],
            ),
          );
          if (paid != true ||
              !context.mounted ||
              ref.read(authStateProvider).value?.userId != owner) {
            return;
          }
          additional =
              true; // Explicit choice only; never silently spend Credit.
        }
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SourceCatalogPage(
              rewriteOwner: owner,
              rewriteRun: {
                ...rows.single,
                'answers': rows.single['answers'],
                if (additional) '_additional': true,
              },
            ),
          ),
        );
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('기존 답안을 불러오지 못했어요. 다시 시도해 주세요.')),
          );
        }
      }
    }

    final auth = ref.watch(authStateProvider);
    final displayRecord =
        (!auth.isLoading && !auth.hasError && auth.value?.userId == owner
            ? ref
                  .watch(sharedEssayHistoryProvider(owner))
                  .value
                  ?.where((r) => r.id == record.id)
                  .firstOrNull
            : null) ??
        record;
    return Scaffold(
      appBar: AppBar(
        title: const Text('첨삭 결과'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(
            MediaQuery.textScalerOf(context).scale(16) + 32,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => goToEssayHistory(context),
              icon: const Icon(Icons.history),
              label: const Text('나의 첨삭 기록'),
            ),
          ),
        ),
      ),
      body: !auth.isLoading && !auth.hasError && auth.value?.userId == owner
          ? record.math
                ? EvaluationReportView(report: report, before: before)
                : EssayResultView(
                    isPreview: false,
                    growthChart: before == null
                        ? null
                        : GrowthBars(before: before!, after: report),
                    summaryActions: Column(
                      children: [
                        EssayVoice(report: report, before: before),
                        ResultPdfButton(report: report),
                      ],
                    ),
                    collapsedDetails: true,
                    evaluation: approvedEssayEvaluation(report, before),
                    evidenceLabels: report.evidenceLabels,
                    question: EssayQuestion(
                      id: questionId,
                      university: record.title,
                      exam: record.examLabel,
                      title: '',
                      prompt: '',
                      passages: const [],
                      origin: CriteriaOrigin.officialExam,
                    ),
                    comparison: before != null,
                    submittedAnswer: report.answer,
                    sentenceReview: report.sentenceReview,
                    evaluationId: report.id,
                    attemptId: record.id,
                    header: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        EssayResultHeader(
                          record: displayRecord,
                          questionId: questionId,
                        ),
                        EssayFollowupAction(
                          run: record.examData,
                          onOpen: openWriter,
                        ),

                        const SizedBox(height: 16),
                        ResultAccordion(
                          title: essayAnswerVersion(record).startsWith('수정')
                              ? '수정 제출 답안'
                              : '최초 제출 답안',
                          child: SelectableText(
                            report.answer,
                            textAlign: TextAlign.left,
                          ),
                        ),
                        if (before != null)
                          ResultAccordion(
                            title: '비교 대상 · 이전 제출 답안',
                            child: SelectableText(
                              before!.answer,
                              textAlign: TextAlign.left,
                            ),
                          ),
                      ],
                    ),
                    onRewrite:
                        record.exam && record.examData['state'] == 'completed'
                        ? () => openWriter(false)
                        : null,
                  )
          : const Center(child: Text('로그인 상태가 변경되었습니다.')),
    );
  }
}

/// Server eligibility takes precedence over the optional paid-cycle action.
class EssayFollowupAction extends StatelessWidget {
  const EssayFollowupAction({
    super.key,
    required this.run,
    required this.onOpen,
  });
  final Map<String, dynamic> run;
  final Future<void> Function(bool additional) onOpen;
  @override
  Widget build(BuildContext context) {
    if (run['state'] != 'completed') return const SizedBox.shrink();
    final included = run['free_rewrite_available'] == true;
    if (!included && run['continuous_cycles_supported'] != true) {
      return const SizedBox.shrink();
    }
    return OutlinedButton(
      onPressed: () => onOpen(!included),
      child: Text(included ? '다시 써보기 · 무료 재첨삭' : '추가 첨삭 · 1 Credit'),
    );
  }
}

/// Registry fields stay separate; never parse track/session from a display label.
class EssayExamBadges extends StatelessWidget {
  const EssayExamBadges({super.key, required this.data, this.questionLabel});
  final Map<String, dynamic> data;
  final String? questionLabel;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 6,
    children: [
      for (final label in [
        data['track'] as String?,
        data['session'] as String?,
        questionLabel,
      ])
        if ((label ?? '').trim().isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTokens.textPrimary.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label!, style: Theme.of(context).textTheme.bodyMedium),
          ),
    ],
  );
}

class EssayResultHeader extends StatelessWidget {
  const EssayResultHeader({
    super.key,
    required this.record,
    required this.questionId,
  });
  final SharedEssayRecord record;
  final String questionId;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          record.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTokens.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          record.examLabel,
          textAlign: TextAlign.left,
          style: AppTokens.body,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              label: Text(
                record.exam ? essayExamQuestionLabel(record, questionId) : '문항',
              ),
            ),
            EssayHistoryBadge(record: record),
            Text(essayShortDate(record), style: AppTokens.caption),
          ],
        ),
      ],
    ),
  );
}

/// Clear imperative detail/writer routes before selecting the canonical list.
void goToEssayHistory(BuildContext context) {
  final router = GoRouter.of(context);
  Navigator.of(context).popUntil((route) => route.isFirst);
  router.go('/lab/essay/history');
}
