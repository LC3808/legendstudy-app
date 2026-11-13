import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/shell_widgets.dart';
import '../study_providers.dart';
import '../domain/study_models.dart';
import 'study_trends.dart';
import 'study_bar_chart.dart';
import 'study_goals.dart';

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
            final tomorrow = dayStartMs(day.add(const Duration(days: 1)));
            final summary = studyBuckets(
              records,
              [
                (dayStartMs(day), tomorrow),
                (dayStartMs(monday(day)), tomorrow),
                (dayStartMs(DateTime.utc(day.year, day.month)), tomorrow),
                (
                  dayStartMs(monday(day).subtract(const Duration(days: 7))),
                  dayStartMs(monday(day)),
                ),
              ],
              draft: study.recovery ? null : study.draft,
              offset: study.offset,
            );
            final subjects = studySubjectTotals(
              records,
              dayStartMs(dates.last),
              dayStartMs(trendEnd(period, dates.last)),
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
                Text(
                  '오늘 ${studyDuration(summary[0])} · 이번 주 ${studyDuration(summary[1])} · 이번 달 ${studyDuration(summary[2])}',
                ),
                Text(
                  '이번 주 하루 평균 ${studyDuration(summary[1] ~/ day.weekday)} (월요일~오늘)',
                ),
                Text(
                  '지난주 전체 ${studyDuration(summary[3])} · 현재까지 ${summary[1] >= summary[3] ? '+' : '-'}${studyDuration((summary[1] - summary[3]).abs())}',
                ),
                const Text('진행 중인 이번 주와 완료된 지난주를 비교해요.'),
                const SizedBox(height: 12),
                StudyGoals(study: study, today: summary[0], week: summary[1]),
                const Divider(),
                const Text('선택한 현재 기간의 과목별 공부시간'),
                for (final entry in subjects.entries)
                  Text('${entry.key} · ${studyDuration(entry.value)}'),
                if (subjects.containsKey('과목 겹침'))
                  const Text('다른 기기의 서로 다른 과목이 겹친 시간은 한 번만 별도로 계산해요.'),
                if (subjects.isEmpty) const Text('아직 과목별 공부 기록이 없어요.'),
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
