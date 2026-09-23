import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/study/trends/study_trends.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';

StudyRecord sample(
  String id,
  DateTime start, {
  bool mock = false,
  bool include = true,
  int minutes = 60,
}) => StudyRecord(
  id: id,
  startedMs: start.millisecondsSinceEpoch,
  endedMs: start.millisecondsSinceEpoch + minutes * 60000,
  segments: [ActiveSegment(0, minutes * 60000)],
  mode: mock ? 'mock_exam' : 'study',
  title: mock ? '시험' : null,
  plannedSeconds: mock ? 4800 : null,
  includeInStudyTotal: include,
);
void main() {
  final day = DateTime.utc(2026, 9, 23);
  test('daily, Monday weekly, calendar monthly KST boundaries share union', () {
    final rows = [
      sample('a', DateTime.utc(2026, 9, 20, 14, 30)), // KST Sunday 23:30
      sample('b', DateTime.utc(2026, 9, 20, 15, 0)), // overlap half hour
      sample('c', DateTime.utc(2026, 8, 31, 14, 30)),
    ];
    expect(
      studyBuckets(rows, [
        (
          dayStartMs(DateTime.utc(2026, 9, 20)),
          dayStartMs(DateTime.utc(2026, 9, 21)),
        ),
      ]),
      [1800000],
    );
    expect(
      studyBuckets(rows, [
        (
          dayStartMs(monday(day)),
          dayStartMs(trendEnd(TrendPeriod.weekly, monday(day))),
        ),
      ]),
      [3600000],
    );
    expect(
      studyBuckets(rows, [
        (dayStartMs(DateTime.utc(2026, 9)), dayStartMs(DateTime.utc(2026, 10))),
      ]),
      [7200000],
    );
    expect(trendDates(TrendPeriod.daily, day).length, 14);
    expect(
      trendDates(TrendPeriod.weekly, day).every((d) => d.weekday == 1),
      true,
    );
    expect(trendDates(TrendPeriod.monthly, day).first, DateTime.utc(2026, 4));
  });
  test('included mock counts; excluded mock retained but never aggregated', () {
    final rows = [
      sample('a', DateTime.utc(2026, 9, 23), mock: true),
      sample('b', DateTime.utc(2026, 9, 23, 2), mock: true, include: false),
    ];
    final bounds = [
      (dayStartMs(day), dayStartMs(day.add(const Duration(days: 1)))),
    ];
    expect(studyBuckets(rows, bounds), [3600000]);
    expect(studyWeek(rows, dayStartMs(day) + 36000000).last, 3600000);
  });
  for (final (current, previous, days, expected) in [
    (120, 100, 3, '20% 늘었어요'),
    (80, 100, 3, '20% 줄었어요'),
    (105, 100, 3, '비슷한'),
    (110, 100, 3, '비슷한'),
    (100, 0, 3, '변화율을 비교하지'),
    (0, 100, 3, '100% 줄었어요'),
    (0, 0, 0, '충분하지'),
    (100, 100, 2, '충분하지'),
  ]) {
    test(
      'trend comparison $current/$previous $days days',
      () => expect(
        compareStudyTrend(current, previous, activeDays: days, label: '최근'),
        contains(expected),
      ),
    );
  }
  test('comment ignores partial today and requires three recorded days', () {
    final rows = [
      for (var i = 1; i <= 3; i++) sample('$i', DateTime.utc(2026, 9, 23 - i)),
    ];
    final before = trendComment(rows, day, TrendPeriod.daily);
    expect(before, contains('이전 기간'));
    rows.add(sample('today', DateTime.utc(2026, 9, 23), minutes: 600));
    expect(trendComment(rows, day, TrendPeriod.daily), before);
  });
}
