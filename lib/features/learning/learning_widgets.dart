import 'invite_page.dart' show InviteShareButton;
import '../../core/theme/app_theme.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase/supabase_providers.dart';
import '../../shared/widgets/shell_widgets.dart';
import '../school/school_providers.dart';
import '../study/study_providers.dart';
import 'learning_repository.dart';
import 'school_rank_feed.dart';
import 'study_percentile.dart';

class LearningError extends StatelessWidget {
  const LearningError({super.key, required this.retry});
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('정보를 불러오지 못했어요. 연결을 확인하고 다시 시도해 주세요.'),
      TextButton(onPressed: retry, child: const Text('다시 시도')),
    ],
  );
}

class ConfirmedStudySummary extends ConsumerWidget {
  const ConfirmedStudySummary({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) return const LinearProgressIndicator();
    if (auth.hasError) {
      return LearningError(retry: () => ref.invalidate(authStateProvider));
    }
    if (auth.value?.isAuthenticated != true) return const SizedBox.shrink();
    ref.listen(
      studyControllerProvider.select(
        (s) => s.records.where((r) => r.synced).map((r) => r.id).join(','),
      ),
      (_, _) {
        ref.invalidate(learningSummaryProvider);
        ref.invalidate(studyPercentileProvider);
        ref.invalidate(schoolRanksProvider);
        ref.invalidate(schoolRankFeedProvider);
      },
    );
    ref.listen(studyControllerProvider.select((s) => s.nowMs ~/ 60000), (_, _) {
      // Keep day/week current; lifetime percentile refreshes on sync or explicit retry.
      ref.invalidate(learningSummaryProvider);
    });
    final summary = ref.watch(learningSummaryProvider);
    return LearningCard(
      child: summary.when(
        skipLoadingOnRefresh: false,
        data: (s) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudySummaryMetrics(
              today: s.today,
              allTime: s.allTime,
              week: s.week,
            ),
            const SizedBox(height: 16),
            StudyPercentileCard(allTime: s.allTime),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  ref.invalidate(learningSummaryProvider);
                  ref.invalidate(studyPercentileProvider);
                },
                child: const Text('학습 현황 새로고침'),
              ),
            ),
          ],
        ),
        error: (_, _) =>
            LearningError(retry: () => ref.invalidate(learningSummaryProvider)),
        loading: () => const LinearProgressIndicator(),
      ),
    );
  }
}

/// Uses existing server totals; this widget does no aggregation.
class StudySummaryMetrics extends StatelessWidget {
  const StudySummaryMetrics({
    super.key,
    required this.today,
    required this.allTime,
    required this.week,
  });
  final int today, week;
  final int? allTime;
  @override
  Widget build(BuildContext context) {
    final values = [
      _Stat('오늘 공부시간', learningDuration(today), AppTokens.info),
      _Stat('이번 주 공부시간', learningDuration(week), const Color(0xFF176B4A)),
      _Stat(
        '누적 공부시간',
        allTime == null ? '조회 미연결' : learningDuration(allTime!),
        AppTokens.primaryInk,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(13) > 18) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final value in values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: value,
                ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < values.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: values[i]),
            ],
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
    decoration: BoxDecoration(
      border: Border(left: BorderSide(color: color, width: 3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class LearningHomeExtras extends ConsumerWidget {
  const LearningHomeExtras({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LearningSectionHeader('우리 학교 공부 순위'),
        const LearningCard(child: OwnSchoolRank()),
        const LearningSectionHeader('친구와 함께 공부하기'),
        LearningCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('친구를 초대하고 함께 공부 기록을 쌓아 보세요.'),
              const SizedBox(height: 20),
              const InviteShareButton(),
            ],
          ),
        ),
      ],
    );
  }
}

class OwnSchoolRank extends ConsumerWidget {
  const OwnSchoolRank({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    if (auth.isLoading) return const LinearProgressIndicator();
    if (auth.hasError) {
      return LearningError(retry: () => ref.invalidate(authStateProvider));
    }
    if (auth.value?.isAuthenticated != true) {
      return TextButton(
        onPressed: () => context.push('/auth'),
        child: const Text('로그인하고 학교 순위 보기'),
      );
    }
    return ref
        .watch(schoolSelectionProvider)
        .when(
          skipLoadingOnRefresh: false,
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => LearningError(
            retry: () => ref.invalidate(schoolSelectionProvider),
          ),
          data: (school) => school == null
              ? const SchoolRequired()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      school.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),

                    ref
                        .watch(schoolRanksProvider(defaultRankQuery))
                        .when(
                          skipLoadingOnRefresh: false,
                          data: (r) => r.mine == null
                              ? const Text('아직 총 공부시간 순위가 없어요.')
                              : Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  child: Wrap(
                                    spacing: 24,
                                    runSpacing: 12,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Semantics(
                                        label:
                                            '전체 기간 총 공부시간 순위 ${r.mine!.rank}위',
                                        child: Text(
                                          '${r.mine!.rank}위',
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '참여 ${r.mine!.active?.toString() ?? '**'}명',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            r.mine!.ms == null
                                                ? '총 공부시간 비공개'
                                                : '총 공부시간 ${learningDuration(r.mine!.ms!)}',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => LearningError(
                            retry: () => ref.invalidate(schoolRanksProvider),
                          ),
                        ),
                    TextButton(
                      onPressed: () => context.push('/study/schools'),
                      child: const Text('학교별 순위 보기'),
                    ),
                  ],
                ),
        );
  }
}

class SchoolRequired extends StatelessWidget {
  const SchoolRequired({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('학교를 등록하면 우리 학교 공부 순위를 확인할 수 있어요.'),
      TextButton(
        onPressed: () => context.push('/my/school'),
        child: const Text('학교 등록하기'),
      ),
    ],
  );
}

/// Scoped selection treatment. Other chips retain the existing design system.
class RankingChoiceChip extends StatelessWidget {
  const RankingChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
  });
  final Widget label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ChoiceChip(
      label: label,
      selected: selected,
      onSelected: onSelected,
      showCheckmark: true,
      selectedColor: dark ? const Color(0xff334155) : const Color(0xffe6e9ee),
      backgroundColor: dark
          ? Theme.of(context).colorScheme.surface
          : Colors.white,
      side: BorderSide(
        color: selected
            ? (dark ? const Color(0xffcbd5e1) : const Color(0xff1f2937))
            : Theme.of(context).colorScheme.outlineVariant,
        width: selected ? 1.75 : 1,
      ),
      elevation: selected ? 2 : 0,
      shadowColor: const Color(0x200d1b2a),
    );
  }
}

class HomeSchoolRankCard extends ConsumerWidget {
  const HomeSchoolRankCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String? rankLabel;
    final auth = ref.watch(authStateProvider);
    if (!auth.isLoading &&
        !auth.hasError &&
        auth.value?.isAuthenticated == true) {
      final school = ref.watch(schoolSelectionProvider);
      if (!school.isLoading && !school.hasError && school.value != null) {
        final rank = ref.watch(schoolRankFeedProvider(defaultRankQuery));
        if (!rank.isLoading &&
            !rank.hasError &&
            rank.hasValue &&
            !rank.value!.refreshFailed) {
          rankLabel = rank.value!.page.mine == null
              ? '순위권 밖'
              : '${rank.value!.page.mine!.rank}위';
        }
      }
    }
    return LearningCard(
      child: InkWell(
        onTap: () => context.push('/study/schools'),
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text(
                      '학교별 공부 순위',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (rankLabel != null)
                      Semantics(
                        label: '우리 학교 전체 기간 총 공부시간 $rankLabel',
                        child: ExcludeSemantics(
                          child: Text(
                            rankLabel,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xff5eead4)
                                  : const Color(0xff0f766e),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class SchoolRankingPage extends ConsumerStatefulWidget {
  const SchoolRankingPage({super.key});
  @override
  ConsumerState<SchoolRankingPage> createState() => _SchoolRankingPageState();
}

class _SchoolRankingPageState extends ConsumerState<SchoolRankingPage> {
  RankQuery query = defaultRankQuery;
  void selectQuery(RankQuery next) {
    if (next == query) return;
    ref.invalidate(schoolRankFeedProvider(next));
    setState(() => query = next);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('학교별 공부 순위')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (auth.isLoading)
              const LinearProgressIndicator()
            else if (auth.hasError)
              LearningError(retry: () => ref.invalidate(authStateProvider))
            else if (auth.value?.isAuthenticated != true)
              TextButton(
                onPressed: () => context.push('/auth'),
                child: const Text('로그인하고 학교 순위 보기'),
              )
            else
              ref
                  .watch(schoolSelectionProvider)
                  .when(
                    skipLoadingOnRefresh: false,
                    loading: () => const LinearProgressIndicator(),
                    error: (_, _) => LearningError(
                      retry: () => ref.invalidate(schoolSelectionProvider),
                    ),
                    data: (school) => school == null
                        ? const SchoolRequired()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('우리 학교 · ${school.name}'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final m in RankMetric.values)
                                    RankingChoiceChip(
                                      label: Text(m.label),
                                      selected: query.metric == m,
                                      onSelected: (_) => selectQuery((
                                        period: query.period,
                                        metric: m,
                                      )),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final p in RankPeriod.values)
                                    RankingChoiceChip(
                                      label: Text(p.label),
                                      selected: query.period == p,
                                      onSelected: (_) => selectQuery((
                                        period: p,
                                        metric: query.metric,
                                      )),
                                    ),
                                ],
                              ),
                              _SchoolRankResults(
                                query: query,
                                ownIdentity: school.identity,
                              ),
                            ],
                          ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _SchoolRankResults extends ConsumerWidget {
  const _SchoolRankResults({required this.query, required this.ownIdentity});
  final RankQuery query;
  final String ownIdentity;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = schoolRankFeedProvider(query);
    return ref
        .watch(provider)
        .when(
          skipLoadingOnRefresh: false,
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => LearningError(retry: () => ref.invalidate(provider)),
          data: (feed) {
            final p = feed.page;
            final controller = ref.read(provider.notifier);
            final busy =
                feed.refreshing || feed.loadingMore || feed.loadingOutside;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextButton(
                  onPressed: busy ? null : controller.refresh,
                  child: const Text('순위 새로고침'),
                ),
                if (feed.refreshing) const LinearProgressIndicator(),
                if (feed.refreshFailed)
                  const Text('새 순위를 불러오지 못했어요. 기존 목록을 유지했어요.'),
                Text(
                  '${query.metric.label} ${p.rows.length <= 10 ? 'TOP 10' : '순위'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (p.rows.isEmpty) const Text('선택 기간에 공개할 순위가 없어요.'),
                for (final row in p.rows)
                  RankTile(
                    row: row,
                    metric: query.metric,
                    own: row.identity == ownIdentity,
                  ),
                if (feed.changed) ...[
                  const Text('순위가 바뀌었어요. 새로고침해 주세요.'),
                  TextButton(
                    onPressed: busy ? null : controller.refresh,
                    child: const Text('최신 순위 보기'),
                  ),
                ] else if (p.nextOffset != null) ...[
                  if (feed.moreFailed)
                    const Text('추가 순위를 불러오지 못했어요. 기존 목록은 유지돼요.'),
                  TextButton.icon(
                    key: const ValueKey('rank-load-more'),
                    onPressed: busy ? null : () => controller.more(),
                    icon: feed.loadingMore
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.keyboard_arrow_down),
                    label: Text(feed.moreFailed ? '순위 다시 불러오기' : '순위 더 보기'),
                  ),
                ],
                if (p.around.isNotEmpty) ...[
                  const LearningSectionHeader('우리 학교 주변 순위'),
                  for (final row in p.around)
                    RankTile(
                      row: row,
                      metric: query.metric,
                      own: row.identity == ownIdentity,
                    ),
                ],
                if (p.outside.isNotEmpty) ...[
                  const LearningSectionHeader('순위권 밖'),
                  for (final row in p.outside)
                    _UnrankedSchoolTile(
                      row: row,
                      own: row.identity == ownIdentity,
                    ),
                  if (p.outsideNextOffset != null && !feed.changed) ...[
                    if (feed.outsideFailed) const Text('학교 목록을 더 불러오지 못했어요.'),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => controller.more(outside: true),
                      child: Text(
                        feed.loadingOutside
                            ? '불러오는 중'
                            : feed.outsideFailed
                            ? '학교 목록 다시 불러오기'
                            : '학교 더 보기',
                      ),
                    ),
                  ],
                  if (p.minRecorders != null && p.minRankRecorders != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        p.minRecorders == p.minRankRecorders
                            ? '${p.minRecorders}명 이상 기록하면 학교 공부시간과 순위가 공개돼요.'
                            : '${p.minRecorders}명 이상 기록하면 학교 공부시간이 공개되고, ${p.minRankRecorders}명 이상 기록하면 순위에 참여할 수 있어요.',
                      ),
                    ),
                ],
                if (p.mine == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('우리 학교는 아직 선택한 순위의 공개 기준을 충족하지 않았어요.'),
                  ),
              ],
            );
          },
        );
  }
}

class _UnrankedSchoolTile extends ConsumerWidget {
  const _UnrankedSchoolTile({required this.row, required this.own});
  final UnrankedSchool row;
  final bool own;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: LearningCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ref
              .watch(rankSchoolNameProvider((row.office, row.school)))
              .when(
                data: (name) => Text(
                  '$name${own ? ' · 우리 학교' : ''}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                loading: () => const Text('학교명 확인 중'),
                error: (_, _) => TextButton(
                  onPressed: () => ref.invalidate(
                    rankSchoolNameProvider((row.office, row.school)),
                  ),
                  child: const Text('학교명 다시 확인'),
                ),
              ),
          const SizedBox(height: 8),
          Text(
            own && row.active != null ? '참여 학생 ${row.active}명' : '참여 학생 수 비공개',
          ),
        ],
      ),
    ),
  );
}

class RankTile extends ConsumerWidget {
  const RankTile({
    super.key,
    required this.row,
    required this.metric,
    required this.own,
  });
  final SchoolRank row;
  final RankMetric metric;
  final bool own;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(rankSchoolNameProvider((row.office, row.school)));
    final time = metric == RankMetric.total ? row.ms : row.average;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: LearningCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            name.when(
              data: (schoolName) => Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${row.rank}위${own ? ' · 우리 학교' : ''} · ',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: schoolName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => Text('${row.rank}위 · 학교명 확인 중'),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(
                  rankSchoolNameProvider((row.office, row.school)),
                ),
                child: Text('${row.rank}위 · 학교명 다시 확인'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              metric == RankMetric.participation
                  ? '참여 ${own ? row.active?.toString() ?? '**' : '**'}명'
                  : time == null
                  ? '공개 기준 미충족'
                  : learningDuration(time),
              style: metric == RankMetric.participation
                  ? null
                  : TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: metric == RankMetric.total
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xff5eead4)
                                : const Color(0xff0f766e))
                          : (Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xffc4b5fd)
                                : const Color(0xff6d28d9)),
                    ),
            ),
            if (metric == RankMetric.participation)
              Text('가입 ${own ? row.registered?.toString() ?? '**' : '**'}명'),
          ],
        ),
      ),
    );
  }
}

/// Reuses the approved light surface; dark contexts use the same spacing/radius
/// with theme surface/outline so text never becomes white on a white card.
class LearningCard extends StatelessWidget {
  const LearningCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.light) return LsCard(child: child);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        side: BorderSide(color: theme.colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: child,
      ),
    );
  }
}

class LearningSectionHeader extends StatelessWidget {
  const LearningSectionHeader(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      top: AppTokens.sectionGap,
      bottom: AppTokens.space12,
    ),
    child: Semantics(
      header: true,
      child: Text(
        title,
        style: AppTokens.sectionTitle.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    ),
  );
}
