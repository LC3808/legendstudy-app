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
        ref.invalidate(schoolRanksProvider);
      },
    );
    ref.listen(studyControllerProvider.select((s) => s.nowMs ~/ 60000), (_, _) {
      // Keep the server-confirmed day/week current across KST boundaries.
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
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => ref.invalidate(learningSummaryProvider),
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
                              ? const Text('아직 참여 순위가 없어요.')
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
                                            '전체 기간 참여 학생 수 순위 ${r.mine!.rank}위',
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

class SchoolRankingPage extends ConsumerStatefulWidget {
  const SchoolRankingPage({super.key});
  @override
  ConsumerState<SchoolRankingPage> createState() => _SchoolRankingPageState();
}

class _SchoolRankingPageState extends ConsumerState<SchoolRankingPage> {
  RankQuery query = defaultRankQuery;
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
                                    ChoiceChip(
                                      label: Text(m.label),
                                      selected: query.metric == m,
                                      onSelected: (_) => setState(
                                        () => query = (
                                          period: query.period,
                                          metric: m,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final p in RankPeriod.values)
                                    ChoiceChip(
                                      label: Text(p.label),
                                      selected: query.period == p,
                                      onSelected: (_) => setState(
                                        () => query = (
                                          period: p,
                                          metric: query.metric,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              TextButton(
                                onPressed: () =>
                                    ref.invalidate(schoolRanksProvider),
                                child: const Text('순위 새로고침'),
                              ),
                              ref
                                  .watch(schoolRanksProvider(query))
                                  .when(
                                    skipLoadingOnRefresh: false,
                                    loading: () =>
                                        const LinearProgressIndicator(),
                                    error: (_, _) => LearningError(
                                      retry: () => ref.invalidate(
                                        schoolRanksProvider(query),
                                      ),
                                    ),
                                    data: (r) => Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          '${query.metric.label} TOP 10',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                        if (r.top.isEmpty)
                                          const Text('선택 기간에 공개할 순위가 없어요.'),
                                        for (final row in r.top)
                                          RankTile(
                                            row: row,
                                            metric: query.metric,
                                            own:
                                                row.identity == school.identity,
                                          ),
                                        if (r.around.isNotEmpty) ...[
                                          const LearningSectionHeader(
                                            '우리 학교 주변 순위',
                                          ),
                                          for (final row in r.around)
                                            RankTile(
                                              row: row,
                                              metric: query.metric,
                                              own:
                                                  row.identity ==
                                                  school.identity,
                                            ),
                                        ],
                                        if (r.mine == null)
                                          const Text(
                                            '우리 학교는 아직 선택한 순위의 공개 기준을 충족하지 않았어요.',
                                          ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          '다른 학교의 가입·참여 인원은 **로 표시해요. 총 공부 시간과 평균은 기록자 3명 이상일 때 공개돼요. 공동 순위와 표시 순서는 서버 기준이에요.',
                                        ),
                                      ],
                                    ),
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
