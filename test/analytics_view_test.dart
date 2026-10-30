import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/analytics/analytics_providers.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_service.dart';
import 'package:legendstudy_app/features/analytics/domain/analytics_events.dart';
import 'package:legendstudy_app/features/analytics/presentation/analytics_view.dart';

class Recorder implements AnalyticsService {
  final events = <String>[];
  @override
  void logEvent(String name, [Map<String, Object?>? params]) {
    events.add(name);
  }

  @override
  void setScreen(String name) {}
  @override
  void setUserId(String? id) {}
}

void main() {
  testWidgets('result view emits once per mount, not rebuild', (tester) async {
    final recorder = Recorder();
    Widget tree() => ProviderScope(
      overrides: [analyticsServiceProvider.overrideWithValue(recorder)],
      child: const AnalyticsView(AnalyticsEvents.essayResultView),
    );
    await tester.pumpWidget(tree());
    await tester.pumpWidget(tree());
    expect(recorder.events, [AnalyticsEvents.essayResultView]);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(tree());
    expect(recorder.events.length, 2);
  });
  testWidgets('default Noop works without Firebase configuration', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AnalyticsView(AnalyticsEvents.essayResultView),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
