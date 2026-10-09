import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/brand/brand_frame.dart';

void main() {
  testWidgets('brand waits for init without showing account UI', (
    tester,
  ) async {
    final start = DateTime.now();
    Widget frame(bool ready) => BrandGate(
      processStart: start,
      ready: ready,
      child: ready
          ? const Text('account', textDirection: TextDirection.ltr)
          : const SizedBox.expand(),
    );
    await tester.pumpWidget(frame(false));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('account'), findsNothing);
    await tester.pumpWidget(frame(true));
    await tester.pumpAndSettle();
    expect(find.text('account'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });
}
