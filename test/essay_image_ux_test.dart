import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/answer_image.dart';

void main() {
  testWidgets(
    'one picker, confirmed thumbnail removal preserves order at 200%',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aD1sAAAAASUVORK5CYII=',
      );
      final second = Uint8List.fromList(png);
      var images = <Uint8List>[png, second];
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: SingleChildScrollView(
                  child: AnswerImagesInput(
                    values: images,
                    onChanged: (next) async => setState(() => images = next),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('답안 사진 촬영'), findsOneWidget);
      expect(find.text('이미지 첨부'), findsOneWidget);
      expect(find.text('사진 삭제'), findsNothing);
      final close = find.byTooltip('답안 사진 삭제').first;
      expect(tester.getSize(close).width, greaterThanOrEqualTo(44));
      await tester.ensureVisible(close);
      await tester.tap(close);
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(images.length, 2);
      await tester.tap(close);
      await tester.pumpAndSettle();
      await tester.tap(find.text('삭제'));
      await tester.pumpAndSettle();
      expect(images.length, 1);
      expect(identical(images.single, second), isTrue);
      expect(find.text('답안 사진 촬영'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
