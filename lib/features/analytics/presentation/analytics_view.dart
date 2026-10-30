import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../analytics_guard.dart';
import '../analytics_providers.dart';

/// Zero-size helper that logs a behavioural view/screen event once when it is
/// first mounted. Drop it into a screen's widget tree:
///
///   const AnalyticsView(AnalyticsEvents.essayLabView, onceKey: 'lab_view'),
///
/// Fire-and-forget and no-op when analytics is unconfigured, so it never
/// affects layout or blocks anything. GA4 adds platform automatically.
class AnalyticsView extends ConsumerStatefulWidget {
  const AnalyticsView(this.event, {this.onceKey, this.params, super.key});

  final String event;

  /// When set, the event fires only the first time this key is seen per session.
  final String? onceKey;
  final Map<String, Object?>? params;

  @override
  ConsumerState<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends ConsumerState<AnalyticsView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final analytics = ref.read(analyticsServiceProvider);
      final key = widget.onceKey;
      if (key != null) {
        analytics.logEventOnce(key, widget.event, widget.params);
      } else {
        analytics.logEvent(widget.event, widget.params);
      }
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
