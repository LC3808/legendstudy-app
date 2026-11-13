import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../domain/study_models.dart';
import '../data/study_repository.dart';
import '../study_providers.dart';

enum TrendPeriod { daily, weekly, monthly }

const trendStableThreshold = 0.10;
const trendMinimumActiveDays = 3;

final trendRemoteProvider = FutureProvider.autoDispose
    .family<List<StudyRecord>, (int, int)>((ref, bounds) async {
      // Refresh after completion/cloud reconciliation, not every timer tick.
      ref.watch(studyControllerProvider.select((study) => study.records));
      final auth = ref.watch(authStateProvider);
      if (auth.isLoading || auth.hasError) throw const StudyStorageError();
      if (auth.value?.userId == null) return [];
      final repository = ref.watch(studyRepositoryFactoryProvider)();
      if (repository.owner != auth.value!.userId ||
          repository is! StudyRangeRepository) {
        throw const StudyStorageError();
      }
      return (repository as StudyRangeRepository).fetchRange(
        bounds.$1,
        bounds.$2,
      );
    });

DateTime monday(DateTime day) => day.subtract(Duration(days: day.weekday - 1));
List<DateTime> trendDates(TrendPeriod period, DateTime day) => switch (period) {
  TrendPeriod.daily => [
    for (var i = 6; i >= 0; i--) day.subtract(Duration(days: i)),
  ],
  TrendPeriod.weekly => [
    for (var i = 7; i >= 0; i--) monday(day).subtract(Duration(days: i * 7)),
  ],
  TrendPeriod.monthly => [
    for (var i = 5; i >= 0; i--) DateTime.utc(day.year, day.month - i),
  ],
};
DateTime trendEnd(TrendPeriod period, DateTime start) => switch (period) {
  TrendPeriod.daily => start.add(const Duration(days: 1)),
  TrendPeriod.weekly => start.add(const Duration(days: 7)),
  TrendPeriod.monthly => DateTime.utc(start.year, start.month + 1),
};

String compareStudyTrend(
  int current,
  int previous, {
  required int activeDays,
  required String label,
}) {
  if (activeDays < trendMinimumActiveDays) {
    return '아직 추세를 분석하기에 공부 기록이 충분하지 않아요.';
  }
  if (previous == 0) return '이전 기간의 공부 기록이 없어 변화율을 비교하지 않아요.';
  final change = (current - previous) / previous;
  if (change.abs() <= trendStableThreshold) return '$label 공부시간은 비슷한 수준이에요.';
  return '$label 공부시간이 이전 기간보다 ${(change.abs() * 100).round()}% ${change > 0 ? '늘었어요' : '줄었어요'}.';
}

String trendComment(
  List<StudyRecord> records,
  DateTime day,
  TrendPeriod period,
) {
  final currentStart = switch (period) {
    TrendPeriod.daily => day.subtract(const Duration(days: 7)),
    TrendPeriod.weekly => monday(day).subtract(const Duration(days: 14)),
    TrendPeriod.monthly => DateTime.utc(day.year, day.month - 1),
  };
  final end = switch (period) {
    TrendPeriod.daily => day,
    TrendPeriod.weekly => monday(day),
    TrendPeriod.monthly => DateTime.utc(day.year, day.month),
  };
  final previousStart = switch (period) {
    TrendPeriod.daily => currentStart.subtract(const Duration(days: 7)),
    TrendPeriod.weekly => currentStart.subtract(const Duration(days: 14)),
    TrendPeriod.monthly => DateTime.utc(
      currentStart.year,
      currentStart.month - 1,
    ),
  };
  final totals = studyBuckets(records, [
    (dayStartMs(previousStart), dayStartMs(currentStart)),
    (dayStartMs(currentStart), dayStartMs(end)),
  ]);
  final days = studyBuckets(records, [
    for (
      var d = previousStart;
      d.isBefore(end);
      d = d.add(const Duration(days: 1))
    )
      (dayStartMs(d), dayStartMs(d.add(const Duration(days: 1)))),
  ]);
  return compareStudyTrend(
    totals[1],
    totals[0],
    activeDays: days.where((n) => n > 0).length,
    label: switch (period) {
      TrendPeriod.daily => '최근 완료된 7일',
      TrendPeriod.weekly => '최근 완료된 2주',
      TrendPeriod.monthly => '지난달',
    },
  );
}

List<String> trendLabels(TrendPeriod period, List<DateTime> dates) => [
  for (var i = 0; i < dates.length; i++)
    switch (period) {
      TrendPeriod.daily => const [
        '월',
        '화',
        '수',
        '목',
        '금',
        '토',
        '일',
      ][dates[i].weekday - 1],
      TrendPeriod.weekly =>
        i == 0 || dates[i].month != dates[i - 1].month
            ? '${dates[i].month}월'
            : '',
      TrendPeriod.monthly => '${dates[i].month}월',
    },
];

/// Attribute the same interval union as studyBuckets, never double-count overlaps.
/// Different simultaneous subjects remain explicitly ambiguous, not guessed.
Map<String, int> studySubjectTotals(
  List<StudyRecord> records,
  int start,
  int end, {
  StudyDraft? draft,
  int? offset,
}) {
  final events = <int, List<(String, int)>>{};
  void add(int anchor, List<ActiveSegment> segments, String? subject) {
    final label = subject == null || subject.trim().isEmpty ? '미분류' : subject;
    for (final segment in segments) {
      final a = (anchor + segment.start).clamp(start, end);
      final b = (anchor + segment.end).clamp(start, end);
      if (b <= a) continue;
      (events[a] ??= []).add((label, 1));
      (events[b] ??= []).add((label, -1));
    }
  }

  for (final record in {for (final r in records) r.id: r}.values) {
    if (record.mode == 'mock_exam' && !record.includeInStudyTotal) continue;
    add(record.startedMs, record.segments, record.subject);
  }
  if (draft != null &&
      offset != null &&
      (draft.mock?.includeInStudyTotal ?? true) &&
      !records.any((r) => r.id == draft.id)) {
    add(
      draft.startedMs,
      draft.activeAt(offset),
      draft.mock?.subject ?? draft.studySubject,
    );
  }
  final times = events.keys.toList()..sort();
  final counts = <String, int>{}, totals = <String, int>{};
  int? previous;
  for (final time in times) {
    final active = counts.keys.where((s) => counts[s]! > 0).toList();
    if (previous != null && active.isNotEmpty) {
      final label = active.length == 1 ? active.single : '과목 겹침';
      totals[label] = (totals[label] ?? 0) + time - previous;
    }
    for (final (subject, delta) in events[time]!) {
      counts[subject] = (counts[subject] ?? 0) + delta;
    }
    previous = time;
  }
  return totals;
}
