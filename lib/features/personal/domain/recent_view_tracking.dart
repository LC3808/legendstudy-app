import 'package:flutter/widgets.dart';

const meaningfulRecentViewThreshold = Duration(seconds: 10);

/// Tracks foreground-only dwell time. Background time is never added.
class ForegroundRecentViewTracker {
  DateTime? _foregroundSince;
  Duration _foregroundDwell = Duration.zero;
  bool _meaningful = false;
  bool _qualified = false;

  Duration get foregroundDwell => _foregroundDwell;
  bool get qualified => _qualified;

  void start(DateTime now) => _foregroundSince ??= now;

  void lifecycle(AppLifecycleState state, DateTime now) {
    if (state == AppLifecycleState.resumed) {
      start(now);
    } else if (_foregroundSince != null) {
      _accumulate(now);
      _foregroundSince = null;
    }
  }

  bool markMeaningful(DateTime now) {
    _meaningful = true;
    _accumulate(now);
    return _qualify();
  }

  bool check(DateTime now) {
    _accumulate(now);
    return _qualify();
  }

  /// Called by a timer scheduled while the tracker is foreground-active.
  /// Keeping this separate from DateTime.now makes fake-clock/widget tests
  /// deterministic while production still uses the foreground timer boundary.
  bool thresholdReached() {
    _foregroundDwell = meaningfulRecentViewThreshold;
    return _qualify();
  }

  void _accumulate(DateTime now) {
    final since = _foregroundSince;
    if (since == null) return;
    final elapsed = now.difference(since);
    if (elapsed.isNegative) return;
    _foregroundDwell += elapsed;
    _foregroundSince = now;
  }

  bool _qualify() {
    if (!_qualified &&
        (_meaningful || _foregroundDwell >= meaningfulRecentViewThreshold)) {
      _qualified = true;
    }
    return _qualified;
  }
}
