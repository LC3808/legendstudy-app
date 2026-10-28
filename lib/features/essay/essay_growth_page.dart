import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/shell_widgets.dart';
import 'evaluation_report.dart';
import 'growth_bars.dart';
import 'growth_timeline.dart';
import 'shared_history.dart';
import 'shared_history_page.dart';

/// 나의 논술 LAB 성장 분석.
///
/// Read-only view over the existing owner-scoped history. Growth is always the
/// real stored evaluation — the same comparison contract the result screen uses
/// ([compareEvaluationReports] / [GrowthBars]); scores from different
/// exams are never averaged and missing numbers are never invented.
class EssayGrowthPage extends ConsumerWidget {
  const EssayGrowthPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final owner = auth.isLoading || auth.hasError ? null : auth.value?.userId;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text('나의 논술랩'),
            SizedBox(width: AppTokens.space8),
            LabBetaBadge(),
          ],
        ),
      ),
      body: owner == null
          ? const Center(child: Text('로그인 상태를 확인해 주세요.'))
          : _GrowthBody(key: ValueKey(owner), owner: owner),
    );
  }
}

bool _completed(Map<String, dynamic> e) =>
    (e['state'] as String?)?.toUpperCase() == 'COMPLETED';

class _GrowthBody extends ConsumerStatefulWidget {
  const _GrowthBody({required this.owner, super.key});
  final String owner;
  @override
  ConsumerState<_GrowthBody> createState() => _GrowthBodyState();
}

class _GrowthBodyState extends ConsumerState<_GrowthBody> {
  // Render exams newest-first, five at a time; scrolling near the bottom loads
  // the next five. Owner history pages are read before numbering rounds.
  static const _page = 5;
  int visible = _page;
  int _groupCount = 0;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (visible < _groupCount &&
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 240) {
      setState(() => visible += _page);
    }
  }

  @override
  Widget build(BuildContext context) {
    final owner = widget.owner;
    final history = ref.watch(sharedEssayHistoryProvider(owner));
    return history.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(sharedEssayHistoryProvider(owner)),
          child: const Text('기록을 불러오지 못했어요. 다시 시도'),
        ),
      ),
      data: (rows) {
        // Presentation follows canonical learning identity, independently of billing.
        final groups = groupEssayHistory(rows)
            .where((g) => g.any((r) => r.evaluations.any(_completed)))
            .toList();
        _groupCount = groups.length;
        final shown = groups.take(visible).toList();
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(sharedEssayHistoryProvider(owner));
            await ref.read(sharedEssayHistoryProvider(owner).future);
          },
          child: ListView(
            controller: _scroll,
            padding: const EdgeInsets.all(AppTokens.pagePadding),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const Text('같은 문제·평가 기준으로 다시 첨삭받은 회차를 비교해 성장 변화를 보여드려요.'),
              const SizedBox(height: AppTokens.space8),
              Text(
                rows.any((r) => r.examData['_historyTruncated'] == true)
                    ? '서버 조회 확장이 필요해 최근 50회차만 표시합니다. 전체 회차 번호는 표시하지 않아요.'
                    : '시험별 성장 기록 · 서로 다른 시험의 점수는 평균하지 않아요.',
                style: AppTokens.caption,
              ),
              const SizedBox(height: AppTokens.space16),
              if (groups.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('아직 완료된 첨삭 기록이 없어요. 첨삭을 받으면 성장 변화를 볼 수 있어요.'),
                ),
              // Newest exam expanded, earlier exams collapsed.
              for (final (i, group) in shown.indexed) ...[
                _GrowthGroupCard(
                  key: ValueKey(group.first.id),
                  owner: owner,
                  group: group,
                  initiallyExpanded: i == 0,
                ),
                const SizedBox(height: AppTokens.space12),
              ],
              if (visible < groups.length)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppTokens.space16),
                  child: Center(
                    child: Text(
                      '아래로 내리면 이전 시험을 더 볼 수 있어요.',
                      style: AppTokens.caption,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GrowthGroupCard extends ConsumerStatefulWidget {
  const _GrowthGroupCard({
    required this.owner,
    required this.group,
    this.initiallyExpanded = false,
    super.key,
  });
  final String owner;
  final List<SharedEssayRecord> group;
  final bool initiallyExpanded;
  @override
  ConsumerState<_GrowthGroupCard> createState() => _GrowthGroupCardState();
}

class _GrowthGroupCardState extends ConsumerState<_GrowthGroupCard> {
  // Memoized so scrolling or a parent rebuild never re-fires the report read;
  // only loaded once the card is expanded.
  Future<Map<String, List<EvaluationReport?>>>? _report;

  Future<Map<String, List<EvaluationReport?>>> loadReports(
    SharedEssayHistory history,
    List<SharedEssayRecord> rounds,
  ) async {
    final result = <String, List<EvaluationReport?>>{};
    for (final row in rounds) {
      if (row.exam) {
        final values = await history.examRuns(row.id);
        if (values.length != 1) throw StateError('HISTORY_UNAVAILABLE');
        for (final q in row.examData['question_ids'] as List) {
          final key = q as String;
          EvaluationReport? report;
          try {
            report = examEvaluationReport(values.single, key);
          } on FormatException {
            /* Missing score stays missing. */
          }
          result.putIfAbsent(key, () => []).add(report);
        }
      } else {
        final e = row.evaluations.firstWhere(_completed);
        final report = await history.evaluationReport(
          row.math,
          e['id'] as String,
        );
        result.putIfAbsent('legacy', () => []).add(report.report);
      }
    }
    return result;
  }

  @override
  void didUpdateWidget(covariant _GrowthGroupCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    String fingerprint(List<SharedEssayRecord> rows) => rows.map((r) =>
      '${r.id}:${r.examData['state']}:${r.examData['completed_at']}').join('|');
    if (fingerprint(oldWidget.group) != fingerprint(widget.group)) _report = null;
  }

  late bool expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final owner = widget.owner;
    final group = widget.group;
    // group is chronological (oldest first); the latest completed round carries
    // the most recent before→after comparison.
    final completedRounds = group
        .where((r) => r.evaluations.any(_completed))
        .toList();
    final latest = completedRounds.last;
    final client = ref.read(supabaseClientProvider);
    if (expanded) {
      _report ??= client == null
          ? null
          : loadReports(SharedEssayHistory(client, owner), completedRounds);
    }
    final title = latest.examLabel.isEmpty
        ? latest.title
        : '${latest.title} · ${latest.examLabel}';
    return LsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Collapsed header: 대학명 · 시험명 + 회차 수.
          InkWell(
            onTap: () => setState(() => expanded = !expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTokens.space4),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: AppTokens.cardTitle)),
                  const SizedBox(width: AppTokens.space8),
                  Text('${completedRounds.length}회차', style: AppTokens.caption),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTokens.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: AppTokens.space12),
            if (_report == null)
              const Text('서버 연결을 준비하고 있어요.', style: AppTokens.caption)
            else
              FutureBuilder<Map<String, List<EvaluationReport?>>>(
                future: _report,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 3),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Text(
                      '성장 기록을 불러오지 못했어요. 각 회차 결과는 아래에서 확인할 수 있어요.',
                      style: AppTokens.caption,
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in snapshot.data!.entries) ...[
                        Text(
                          latest.exam
                              ? essayExamQuestionLabel(completedRounds.firstWhere((r) => (r.examData['question_ids'] as List? ?? []).contains(entry.key)), entry.key)
                              : '성장 요약',
                          style: AppTokens.cardTitle,
                        ),
                        const SizedBox(height: 8),
                        if (entry.value.length == 1 &&
                            entry.value.single != null)
                          _SingleRoundLevels(report: entry.value.single!)
                        else if (entry.value.length == 2 &&
                            entry.value.every((r) => r != null))
                          GrowthBars(
                            before: entry.value.first!,
                            after: entry.value.last!,
                            learning: true,
                          )
                        else
                          GrowthTimeline(reports: entry.value),
                        const SizedBox(height: 16),
                      ],
                    ],
                  );
                },
              ),
            const SizedBox(height: AppTokens.space8),
            _RoundList(owner: owner, group: group),
          ],
        ],
      ),
    );
  }
}

/// A single completed round shown as the stored 1~5 levels (no comparison yet).
/// Qualitative grades without a numeric level stay as their stored label.
class _SingleRoundLevels extends StatelessWidget {
  const _SingleRoundLevels({required this.report});
  final EvaluationReport report;
  @override
  Widget build(BuildContext context) {
    if (report.rubric.isEmpty) {
      return const Text('표시할 평가 항목이 없어요.', style: AppTokens.caption);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final c in report.rubric)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: c.rating == null
                ? Text('${c.name} · ${c.display}', style: AppTokens.body)
                : Semantics(
                    label: '${c.name} 5단계 중 ${c.rating}단계',
                    child: ExcludeSemantics(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(c.name)),
                              Text('${c.rating}/5단계', style: AppTokens.caption),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              minHeight: 6,
                              value: c.rating! / 5,
                              backgroundColor: AppTokens.primarySoft,
                              valueColor: const AlwaysStoppedAnimation(
                                AppTokens.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
      ],
    );
  }
}

/// Every round in the lineage, newest first; each completed round opens its
/// stored result. Paid first/additional feedback and free re-corrections stay
/// distinguished by the existing history badge.
class _RoundList extends ConsumerWidget {
  const _RoundList({required this.owner, required this.group});
  final String owner;
  final List<SharedEssayRecord> group;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rounds = [...group]
      ..sort((a, b) => essayCompletedAt(b).compareTo(essayCompletedAt(a)));
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text('회차별 결과 보기 (${rounds.length})'),
        children: [
          for (final row in rounds)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Row(
                children: [
                  EssayHistoryBadge(record: row),
                  const SizedBox(width: AppTokens.space8),
                  Expanded(
                    child: Text(
                      essayCompletedAt(row)
                          .toLocal()
                          .toString()
                          .substring(0, 16),
                      style: AppTokens.caption,
                    ),
                  ),
                ],
              ),
              subtitle: row.exam
                  ? Wrap(
                      children: [
                        Text(essayBillingType(row)),
                        for (final e in row.evaluations.where(_completed))
                          TextButton(
                            onPressed: () => openSharedEssayResult(
                              context,
                              ref,
                              owner,
                              row,
                              e,
                            ),
                            child: Text(
                              '${essayExamQuestionLabel(row, (e['id'] as String).split('/').last)} 결과',
                            ),
                          ),
                      ],
                    )
                  : null,
              trailing: row.evaluations.any(_completed)
                  ? const Icon(Icons.chevron_right, size: AppTokens.iconDense)
                  : Text(switch ((row.evaluations
                        .map((e) => (e['state'] as String?)?.toUpperCase())
                        .firstOrNull)) {
                      'PROCESSING' => '첨삭 중',
                      'QUEUED' => '대기 중',
                      'FAILED' => '첨삭 실패',
                      _ => '진행 중',
                    }, style: AppTokens.caption),
              onTap: row.evaluations.any(_completed)
                  ? () => openSharedEssayResult(
                      context,
                      ref,
                      owner,
                      row,
                      row.evaluations.firstWhere(_completed),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}
