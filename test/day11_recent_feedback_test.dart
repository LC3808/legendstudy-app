import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/personal/domain/recent_view_tracking.dart';
import 'package:legendstudy_app/features/feedback/domain/feedback_models.dart';

void main() {
  final start = DateTime(2026, 9, 16, 12);

  test('recent view requires ten seconds of foreground dwell', () {
    final tracker = ForegroundRecentViewTracker()..start(start);
    expect(tracker.check(start.add(const Duration(seconds: 9))), isFalse);
    expect(tracker.qualified, isFalse);
    expect(tracker.check(start.add(const Duration(seconds: 10))), isTrue);
  });

  test('background time is excluded from foreground dwell', () {
    final tracker = ForegroundRecentViewTracker()..start(start);
    tracker.lifecycle(
      AppLifecycleState.paused,
      start.add(const Duration(seconds: 6)),
    );
    tracker.lifecycle(
      AppLifecycleState.resumed,
      start.add(const Duration(minutes: 2, seconds: 6)),
    );
    expect(
      tracker.check(start.add(const Duration(minutes: 2, seconds: 9))),
      isFalse,
    );
    expect(
      tracker.check(start.add(const Duration(minutes: 2, seconds: 10))),
      isTrue,
    );
  });

  test('meaningful action qualifies immediately and only once', () {
    final tracker = ForegroundRecentViewTracker()..start(start);
    expect(
      tracker.markMeaningful(start.add(const Duration(seconds: 2))),
      isTrue,
    );
    expect(
      tracker.markMeaningful(start.add(const Duration(seconds: 3))),
      isTrue,
    );
    expect(tracker.qualified, isTrue);
  });

  test(
    'feedback categories and validation model expose only supported types',
    () {
      expect(FeedbackCategory.values.map((c) => c.value), [
        'inquiry',
        'bug',
        'suggestion',
        'other',
      ]);
      expect(meaningfulRecentViewThreshold, const Duration(seconds: 10));
    },
  );
}
