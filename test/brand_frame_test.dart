import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/brand/brand_frame.dart';
import 'package:legendstudy_app/features/brand/brand_wordmark.dart';

void main() {
  for (final initMs in [0, 400, 3000]) {
    testWidgets('brand paints with init delay $initMs without a fixed hold', (
      tester,
    ) async {
      final start = DateTime.now().subtract(const Duration(seconds: 10));
      Widget frame(bool ready) => BrandGate(
        processStart: start,
        ready: ready,
        child: const MaterialApp(home: Scaffold(body: Text('HOME'))),
      );
      await tester.pumpWidget(frame(initMs == 0));
      expect(find.byType(BrandWordmark), findsOneWidget);
      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );
      if (initMs > 0) {
        await tester.pump(Duration(milliseconds: initMs));
        expect(find.byType(BrandWordmark), findsOneWidget);
        await tester.pumpWidget(frame(true));
      } else {
        await tester.pump();
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.byType(BrandWordmark), findsNothing);
      await tester.pumpWidget(frame(true));
      expect(find.byType(BrandWordmark), findsNothing);
    });
  }
}
