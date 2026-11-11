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
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: [
                _Stat('오늘 공부시간', learningDuration(s.today)),
                _Stat(
                  '누적 공부시간',
                  s.allTime == null ? '조회 미연결' : learningDuration(s.allTime!),
                ),
                _Stat('이번 주 공부시간', learningDuration(s.week)),
              ],
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

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label),
      Text(value, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}

class LearningHomeExtras extends ConsumerWidget {
  const LearningHomeExtras({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final study = ref.watch(studyControllerProvider);
    final records = [...study.records]
      ..sort((a, b) => b.startedMs.compareTo(a.startedMs));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const LearningSectionHeader('최근 학습 기록'),
        LearningCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('최근 7일 중 최대 5개 · 각 기록의 공부 시간'),
              if (study.historyError || study.historyLimit)
                LearningError(retry: study.sync)
              else if (records.isEmpty)
                const Text('최근 학습 기록이 없어요.'),
              for (final r in records.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_date(r.startedMs)} · ${r.title ?? (r.mode == 'study' ? '공부' : '모의고사')}',
                      ),
                      Text(
                        '${learningDuration(r.activeMs)} · ${study.guest
                            ? '기기 임시 기록'
                            : r.synced
                            ? '동기화 완료'
                            : '동기화 대기'}${r.includeInStudyTotal ? '' : ' · 공부시간 합산 제외'}',
                      ),
                    ],
                  ),
                ),
              TextButton(
                onPressed: () => context.push('/my/trends'),
                child: const Text('학습 추이 자세히 보기'),
              ),
            ],
          ),
        ),
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

  String _date(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(
      ms,
      isUtc: true,
    ).add(const Duration(hours: 9));
    return '${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
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
                        .watch(ownSchoolCardProvider)
                        .when(
                          skipLoadingOnRefresh: false,
                          data: (card) =>
                              Text('우리 학교 가입 학생 ${card.registered}명'),
                          loading: () => const LinearProgressIndicator(),
                          error: (_, _) => LearningError(
                            retry: () => ref.invalidate(ownSchoolCardProvider),
                          ),
                        ),
                    const Text('전체 기간 · 참여 학생 수 순위'),
                    ref
                        .watch(schoolRanksProvider(defaultRankQuery))
                        .when(
                          skipLoadingOnRefresh: false,
                          data: (r) => Text(
                            r.mine == null
                                ? '아직 참여 순위가 없어요. 공부를 완료하면 순위에 반영돼요.'
                                : '${r.mine!.rank}위 · 참여 ${r.mine!.active?.toString() ?? '**'}명',
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
                                          '다른 학교의 가입·참여 인원은 **로 표시해요. 총공부시간과 평균은 기록자 3명 이상일 때 공개돼요. 공동 순위와 표시 순서는 서버 기준이에요.',
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
            Text(
              '${row.rank}위${own ? ' · 우리 학교' : ''}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            name.when(
              data: Text.new,
              loading: () => const Text('학교명 확인 중'),
              error: (_, _) => TextButton(
                onPressed: () => ref.invalidate(
                  rankSchoolNameProvider((row.office, row.school)),
                ),
                child: const Text('학교명 다시 확인'),
              ),
            ),
            Text(
              metric == RankMetric.participation
                  ? '참여 ${own ? row.active?.toString() ?? '**' : '**'}명'
                  : time == null
                  ? '공개 기준 미충족'
                  : learningDuration(time),
            ),
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
