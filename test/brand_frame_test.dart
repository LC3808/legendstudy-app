import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legendstudy_app/features/brand/brand_frame.dart';

void main() {
  group('brandFrameDuration (cold-start timing)', () {
    final start = DateTime(2026, 1, 1, 0, 0, 0);
    Duration? at(int ms) => brandFrameDuration(start, start.add(Duration(milliseconds: ms)));

    test('fast init fills up to the ~1.5s target', () {
      // init 0.4s → ~1.1s remaining; init 1.2s → ~0.3s remaining.
      expect(at(400), const Duration(milliseconds: 1100));
      expect(at(1200), const Duration(milliseconds: 300));
    });

    test('init at/after the target skips the frame (no extra delay)', () {
      expect(at(1500), isNull);
      expect(at(1800), isNull); // 1.8s init → enter right after init
      expect(at(3000), isNull); // 3s init → enter at 3s, no extra 1.5s
    });

    test('sub-150ms remainder is skipped to avoid a flash', () {
      expect(at(1400), isNull); // 100ms remaining < 150ms floor
      expect(at(1349), const Duration(milliseconds: 151));
    });
  });

  testWidgets('cold start shows the brand frame then reveals the app once',
      (tester) async {
    await tester.pumpWidget(
      BrandGate(
        processStart: DateTime.now(),
        child: const MaterialApp(home: Scaffold(body: Text('APP HOME'))),
      ),
    );
    // Frame is up: tagline visible, app underneath in the tree.
    expect(find.text('나의 학습 기록이 쌓일수록,\n나의 가능성은 선명해집니다.'), findsOneWidget);
    expect(find.text('APP HOME'), findsOneWidget);

    // After the target + fade the frame is gone.
    await tester.pump(brandFrameTarget);
    await tester.pump(const Duration(milliseconds: 300)); // fade
    await tester.pumpAndSettle();
    expect(find.text('나의 학습 기록이 쌓일수록,\n나의 가능성은 선명해집니다.'), findsNothing);
    expect(find.text('APP HOME'), findsOneWidget);

    // Cold-start-only: a second mount in the same process does not re-show it
    // (mimics a background→foreground resume — no reshow).
    await tester.pumpWidget(
      BrandGate(
        processStart: DateTime.now(),
        child: const MaterialApp(home: Scaffold(body: Text('RESUMED'))),
      ),
    );
    await tester.pump();
    expect(find.text('나의 학습 기록이 쌓일수록,\n나의 가능성은 선명해집니다.'), findsNothing);
    expect(find.text('RESUMED'), findsOneWidget);
  });
}
