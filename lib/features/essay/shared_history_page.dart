import 'approved_result_adapter.dart';
import 'essay_pages.dart';
import 'essay_models.dart';
import 'source_catalog_page.dart';

import 'package:go_router/go_router.dart';

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

class _HistoryBody extends ConsumerWidget {
  const _HistoryBody({required this.owner, super.key});
  final String owner;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(sharedEssayHistoryProvider(owner));
    return history.when(
      skipLoadingOnRefresh: false,
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
            const Text('논술·수리논술 각각 최근 답안 50개'),
            if (rows.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('아직 첨삭 기록이 없습니다.'),
              ),
            for (final group in groupEssayHistory(rows)) ...[
              for (final row in group)
                ListTile(
                  title: Text(
                    '${row.title} · ${row.rewrite ? '재첨삭' : '최초 첨삭'}',
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (row.exam) Text(row.examLabel),
                      Text(
                        '평가 ${((DateTime.tryParse(row.examData['completed_at'] as String? ?? '') ?? row.at).toLocal()).toString().substring(0, 16)}',
                      ),
                      if (row.examData['parent_id'] != null)
                        const Text('최초 첨삭에 이어진 재첨삭'),
                      if (row.evaluations.isEmpty) const Text('평가 요청 전'),
                      if (row.math)
                        for (final e in row.evaluations)
                          TextButton(
                            onPressed: () => context.push(
                              '/lab/essay/math?evaluation=${Uri.encodeQueryComponent(e['id'] as String)}',
                            ),
                            child: const Text('처리 상태 · 재첨삭 확인'),
                          ),
                      for (final e in row.evaluations)
                        e['state'] == 'COMPLETED'
                            ? TextButton(
                                onPressed: () async {
                                  final client = ref.read(
                                    supabaseClientProvider,
                                  );
                                  if (client == null) return;
                                  try {
                                    final result =
                                        await SharedEssayHistory(
                                          client,
                                          owner,
                                        ).evaluationReport(
                                          row.math,
                                          e['id'] as String,
                                          exam: row.exam,
                                        );
                                    if (!context.mounted ||
                                        ref
                                                .read(authStateProvider)
                                                .value
                                                ?.userId !=
                                            owner) {
                                      return;
                                    }
                                    // Detail stays on this owner-keyed page; account switch removes it.
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => _Result(
                                          owner: owner,
                                          report: result.report,
                                          before: result.before,
                                          record: row,
                                          questionId: (e['id'] as String)
                                              .split('/')
                                              .last,
                                        ),
                                      ),
                                    );
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                            const SnackBar(
                                              content: Text('평가를 불러오지 못했어요.'),
                                            ),
                                          );
                                    }
                                  }
                                },
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
              const Divider(),
            ],
          ],
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
    final auth = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('첨삭 결과')),
      body: !auth.isLoading && !auth.hasError && auth.value?.userId == owner
          ? record.math
                ? EvaluationReportView(report: report, before: before)
                : EssayResultView(
                    isPreview: false,
                    collapsedDetails: true,
                    evaluation: approvedEssayEvaluation(report, before),
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
                    header: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(record.examLabel),
                        Text(
                          (record.examData['questions'] as List? ?? [])
                                      .cast<Map<String, dynamic>>()
                                      .where(
                                        (q) => q['dbQuestionId'] == questionId,
                                      )
                                      .firstOrNull?['label']
                                  as String? ??
                              '문항 정보 확인 중',
                        ),
                        Text(
                          '${record.rewrite ? '재첨삭' : '최초 첨삭'} · ${(DateTime.tryParse(record.examData['completed_at'] as String? ?? '') ?? record.at).toLocal().toString().substring(0, 16)}',
                        ),
                        ExpansionTile(
                          title: const Text('제출 답안'),
                          children: [SelectableText(report.answer)],
                        ),
                        if (before != null)
                          ExpansionTile(
                            title: const Text('최초 답안'),
                            children: [SelectableText(before!.answer)],
                          ),
                      ],
                    ),
                    onRewrite: record.exam
                        ? () async {
                            final client = ref.read(supabaseClientProvider);
                            if (client == null) return;
                            try {
                              final rows =
                                  await SharedEssayHistory(
                                    client,
                                    owner,
                                  ).examRuns(
                                    record.examData['parent_id'] as String? ??
                                        record.id,
                                  );
                              if (!context.mounted ||
                                  ref.read(authStateProvider).value?.userId !=
                                      owner ||
                                  rows.length != 1) {
                                return;
                              }
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => SourceCatalogPage(
                                    rewriteRun: rows.single,
                                  ),
                                ),
                              );
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '기존 답안을 불러오지 못했어요. 다시 시도해 주세요.',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                  )
          : const Center(child: Text('로그인 상태가 변경되었습니다.')),
    );
  }
}
