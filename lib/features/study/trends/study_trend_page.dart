import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/shell_widgets.dart';
import '../study_providers.dart';
import '../domain/study_models.dart';
import 'study_trends.dart';
import 'study_bar_chart.dart';

class StudyTrendPage extends ConsumerStatefulWidget {
  const StudyTrendPage({super.key});
  @override
  ConsumerState<StudyTrendPage> createState() => _StudyTrendPageState();
}

class _StudyTrendPageState extends ConsumerState<StudyTrendPage> {
  TrendPeriod period = TrendPeriod.daily;
  @override
  Widget build(BuildContext context) {
    final study = ref.watch(studyControllerProvider);
    final day = koreanDay(study.nowMs);
    final range = (
      dayStartMs(DateTime.utc(day.year, day.month - 5)),
      dayStartMs(day.add(const Duration(days: 1))),
    );
    final remote = ref.watch(trendRemoteProvider(range));
    if (!study.ready) return const Center(child: CircularProgressIndicator());
    return ShellPage(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            tooltip: '공부 추이 새로고침',
            onPressed: () => ref.invalidate(trendRemoteProvider(range)),
            icon: const Icon(Icons.refresh),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final p in TrendPeriod.values)
              ChoiceChip(
                label: Text(switch (p) {
                  TrendPeriod.daily => '일별',
                  TrendPeriod.weekly => '주별',
                  TrendPeriod.monthly => '월별',
                }),
                selected: p == period,
                onSelected: (_) => setState(() => period = p),
              ),
          ],
        ),
        const SizedBox(height: 16),
        remote.when(
          skipLoadingOnReload: false,
          skipLoadingOnRefresh: false,
          loading: () =>
              const LinearProgressIndicator(semanticsLabel: '공부 추이 불러오는 중'),
          error: (_, _) => ErrorState(
            message: '공부 추이의 전체 기록을 확인하지 못했어요.',
            onRetry: () => ref.invalidate(trendRemoteProvider(range)),
          ),
          data: (rows) {
            final records = {
              for (final r in rows) r.id: r,
              for (final r in study.records) r.id: r,
            }.values.toList();
            final dates = trendDates(period, day);
            final totals = studyBuckets(
              records,
              [
                for (final d in dates)
                  (dayStartMs(d), dayStartMs(trendEnd(period, d))),
              ],
              draft: study.recovery ? null : study.draft,
              offset: study.offset,
            );
            final max = totals.fold<int>(0, (a, b) => a > b ? a : b);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${switch (period) {
                    TrendPeriod.daily => '오늘',
                    TrendPeriod.weekly => '이번 주',
                    TrendPeriod.monthly => '이번 달',
                  }} ${studyDuration(totals.last)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Text('현재 기간은 진행 중이에요.'),
                const SizedBox(height: 16),
                Text(
                  '${dates.first.month}.${dates.first.day} ~ ${day.month}.${day.day}',
                ),
                StudyBarChart(
                  dailyDetails: period == TrendPeriod.daily,
                  labels: trendLabels(period, dates),
                  descriptions: dates
                      .map((d) => '${d.year}.${d.month}.${d.day}')
                      .toList(),
                  totals: totals,
                ),
                if (max == 0) const Text('아직 공부 기록이 없어요.'),
                const Divider(),
                Text(trendComment(records, day, period)),
                const SizedBox(height: 8),
                const Text('완료된 기간의 총 공부시간을 비교해요. 이번 기간과 진행 중인 기록은 비교에서 제외해요.'),
              ],
            );
          },
        ),
      ],
    );
  }
}
