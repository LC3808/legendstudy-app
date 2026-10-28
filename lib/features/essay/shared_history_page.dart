import 'result_pdf.dart';
import 'round_history_actions.dart';
import 'growth_bars.dart';
import 'growth_share.dart';

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
  String query = '', kind = 'all';
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
              segments: const [
                ButtonSegment(value: false, label: Text('최신순')),
                ButtonSegment(value: true, label: Text('시험별')),
              ],
              selected: {byExam},
              onSelectionChanged: (v) => setState(() => byExam = v.single),
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: '대학·시험 검색',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => query = v.trim()),
            ),
            DropdownButtonFormField<String>(
              initialValue: kind,
              items: const [
                DropdownMenuItem(value: 'all', child: Text('전체 기록')),
                DropdownMenuItem(value: 'initial', child: Text('최초 첨삭')),
                DropdownMenuItem(value: 'rewrite', child: Text('재첨삭')),
              ],
              onChanged: (v) => setState(() => kind = v ?? 'all'),
            ),
            const Text('최근 조회한 논술·수리논술 회차와 기존 답안 기록'),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('아직 첨삭 기록이 없습니다.'),
              ),
            for (final group in sortedEssayHistory(
              rows
                  .where(
                    (r) =>
                        (query.isEmpty ||
                            '${r.title} ${r.examLabel}'.contains(query)) &&
                        (kind == 'all' || (kind == 'rewrite') == r.rewrite),
                  )
                  .toList(),
              byExam,
            )) ...[
              for (final row in group)
                ListTile(
                  onTap: row.evaluations.any((e) => e['state'] == 'COMPLETED')
                      ? () => openResult(
                          row,
                          row.evaluations.firstWhere(
                            (e) => e['state'] == 'COMPLETED',
                          ),
                        )
                      : null,
                  title: Text(
                    row.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (row.exam || row.examData['mathSession'] != null)
                        Text(row.examLabel),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: EssayHistoryBadge(record: row),
                      ),
                      Text(
                        '평가 ${((DateTime.tryParse(row.examData['completed_at'] as String? ?? '') ?? row.at).toLocal()).toString().substring(0, 16)}',
                      ),
                      if (row.examData['parent_id'] != null)
                        const Text('최초 첨삭에 이어진 재첨삭'),
                      if (row.evaluations.isEmpty) const Text('평가 요청 전'),
                      if ((row.exam || row.examData['mathSession'] != null) &&
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
                      for (final e in row.evaluations)
                        e['state'] == 'COMPLETED'
                            ? TextButton(
                                onPressed: () => openResult(row, e),
                                child: Text(
                                  row.exam
                                      ? '${(row.examData['questions'] as List? ?? []).cast<Map<String, dynamic>>().where((q) => q['dbQuestionId'] == (e['id'] as String).split('/').last).firstOrNull?['label'] ?? '문항'} · 첨삭 결과 보기'
                                      : '첨삭 결과 보기',
                                ),
                              )
                            : Text(switch (e['state']) {
                                'PROCESSING' => '첨삭 중',
                                'QUEUED' => '대기 중',
                                'FAILED' => '첨삭 실패',
                                'INVALIDATED' => '평가 확인 필요',
                                _ => '상태 확인 필요',
                              }),
                    ],
                  ),
                ),
              const Divider(color: Color(0xFF636363), thickness: 1),
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
    if (!context.mounted || ref.read(authStateProvider).value?.userId != owner) {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('평가를 불러오지 못했어요.')));
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
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => SourceCatalogPage(
              rewriteRun: {
                ...rows.single,
                'answers': record.examData['answers'] ?? rows.single['answers'],
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
    return Scaffold(
      appBar: AppBar(title: const Text('첨삭 결과')),
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
                        OutlinedButton(
                          onPressed: () => showGrowthShare(
                            context,
                            completed: 1,
                            rewrites: before == null ? 0 : 1,
                            report: report,
                            before: before,
                          ),
                          child: const Text('성장 기록 공유'),
                        ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          record.examLabel.split(' · ').first,
                          style: const TextStyle(
                            color: AppTokens.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        EssayExamBadges(
                          data: record.examData,
                          questionLabel:
                              (record.examData['questions'] as List? ?? [])
                                      .cast<Map<String, dynamic>>()
                                      .where(
                                        (q) => q['dbQuestionId'] == questionId,
                                      )
                                      .firstOrNull?['label']
                                  as String? ??
                              '문항 정보 확인 중',
                        ),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            EssayHistoryBadge(record: record),
                            Text(
                              essayCompletedAt(record)
                                  .toLocal()
                                  .toString()
                                  .substring(0, 16),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        if (record.examData['continuous_cycles_supported'] ==
                            true)
                          OutlinedButton(
                            onPressed: () => openWriter(true),
                            child: const Text('추가 첨삭 · 1 Credit'),
                          ),

                        ExpansionTile(
                          title: Text(essayAnswerVersion(record)),
                          children: [SelectableText(report.answer)],
                        ),
                        if (before != null)
                          ExpansionTile(
                            title: const Text('비교 대상 · 이전 제출 답안'),
                            children: [SelectableText(before!.answer)],
                          ),
                      ],
                    ),
                    onRewrite: record.exam ? () => openWriter(false) : null,
                  )
          : const Center(child: Text('로그인 상태가 변경되었습니다.')),
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
