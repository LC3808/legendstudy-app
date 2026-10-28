import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/answer_image_crop.dart';

// The crop screen opens, decodes the captured image, and offers 적용 / 다시 촬영 /
// 취소. Image decode needs real async (runAsync), so the decode phase is driven
// there. PNG re-encoding (toByteData) is not reliable in the headless test
// engine, so the 적용 → 미리보기 → 첨부 rasterization result is verified on device.
late Uint8List _src;

Future<Uint8List> _png(int w, int h) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = const Color(0xFF2563A8),
  );
  final image = await recorder.endRecording().toImage(w, h);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return data!.buffer.asUint8List();
}

Widget _harness(void Function(AnswerCropOutcome?) onResult) => MaterialApp(
  home: Scaffold(
    body: Builder(
      builder: (context) => ElevatedButton(
        onPressed: () async => onResult(await cropAnswerImage(context, _src)),
        child: const Text('go'),
      ),
    ),
  ),
);

Future<void> _openDecoded(
  WidgetTester tester,
  void Function(AnswerCropOutcome?) onResult,
) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(_harness(onResult));
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  });
}

void main() {
  setUpAll(() async => _src = await _png(80, 60));

  testWidgets('crop screen opens with 적용/다시 촬영/취소 after decode', (tester) async {
    await _openDecoded(tester, (_) {});
    expect(find.text('사진 자르기'), findsOneWidget);
    expect(find.text('적용'), findsOneWidget);
    expect(find.text('다시 촬영'), findsOneWidget);
    expect(find.byTooltip('취소'), findsOneWidget);
  });

  testWidgets('다시 촬영 asks the caller to capture again', (tester) async {
    AnswerCropOutcome? result;
    await _openDecoded(tester, (r) => result = r);
    await tester.runAsync(() async {
      await tester.tap(find.text('다시 촬영'));
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await tester.pump();
    });
    expect(result?.retake, isTrue);
  });

  testWidgets('cancel returns no outcome so the existing answer is preserved', (
    tester,
  ) async {
    AnswerCropOutcome? result;
    var done = false;
    await tester.pumpWidget(
      _harness((r) {
        result = r;
        done = true;
      }),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byTooltip('취소'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(done, isTrue);
    expect(result, isNull);
  });
}
