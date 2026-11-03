import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/math_mobile/academic_purple.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_recognition_panel.dart';

void main() {
  const capture = bool.fromEnvironment('MATH_BULK_CAPTURE');
  setUpAll(() async {
    if (!capture) return;
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final family in manifest.where(
      (f) => (f['family'] as String).contains('KaTeX'),
    )) {
      final loader = FontLoader(family['family'] as String);
      for (final font in family['fonts'] as List) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
    await (FontLoader('TestKorean')..addFont(
          File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  Future<void> screenshot(WidgetTester t, String name) async {
    if (!capture) return;
    await t.runAsync(() async {
      final boundary = t.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')),
      );
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final folder = Directory('/private/tmp/legendstudy-b55-screens');
      await folder.create(recursive: true);
      await File('${folder.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  const consent = '모든 영역을 확인했으며 이 전사본으로 첨삭을 요청합니다.';
  final bulk = find.byKey(const ValueKey('confirm-recognized-regions'));
  Finder checkbox(String id) => find.byKey(ValueKey('confirm-region-$id'));
  Finder jump(String id) => find.byKey(ValueKey('review-region-$id'));
  Finder back(String id) => find.byKey(ValueKey('return-to-confirmation-$id'));
  FilledButton confirmButton(WidgetTester t) =>
      t.widget<FilledButton>(find.widgetWithText(FilledButton, '답안 입력 완료'));
  bool? checked(WidgetTester t, String id) =>
      t.widget<CheckboxListTile>(checkbox(id)).value;

  Future<void> mount(
    WidgetTester t,
    List<Map<String, dynamic>> regions, {
    double scale = 1,
    bool busy = false,
    Future<void> Function(Map<String, String>)? onConfirm,
  }) async {
    await t.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(fontFamily: capture ? 'TestKorean' : null),
        home: RepaintBoundary(
          key: const ValueKey('capture'),
          child: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: MathMobileTheme(
              child: Scaffold(
                appBar: AppBar(title: const Text('인식 결과 확인')),
                body: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: MathRecognitionPanel(
                    regions: regions,
                    busy: busy,
                    onConfirm: onConfirm ?? (_) async {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, Finder finder) async {
    await t.ensureVisible(finder);
    await t.pumpAndSettle();
    await t.tap(finder);
    await t.pumpAndSettle();
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'bulk selects eligible rows, lists mandatory numbers and jumps to originals at $scale',
      (t) async {
        var saves = 0;
        await mount(
          t,
          [
            {
              'id': 'a',
              'reading_order': 1,
              'raw_text': 'x=1',
              'uncertain': false,
            },
            {
              'id': 'b',
              'reading_order': 2,
              'raw_text': 'r=-1/6',
              'uncertain': false,
            },
            {
              'id': 'c',
              'reading_order': 6,
              'raw_text': 'e^{?}',
              'uncertain': true,
            },
            {
              'id': 'd',
              'reading_order': 11,
              'raw_text': 'a^2=16',
              'uncertain': true,
            },
            {'id': 'e', 'raw_text': '[판독 불명]', 'uncertain': false},
          ],
          scale: scale,
          onConfirm: (_) async {
            saves++;
          },
        );
        await tap(t, bulk);
        expect(checked(t, 'a'), isTrue);
        expect(checked(t, 'b'), isTrue);
        for (final id in ['c', 'd', 'e']) {
          expect(checked(t, id), isFalse);
        }
        expect(find.text('확인 완료 2개 · 남은 영역 3개'), findsOneWidget);
        expect(find.text('확인 완료 2개 · 남은 영역 3개').hitTestable(), findsOneWidget);
        expect(find.text('반드시 수정 · 미식별 내용이 남아 있어요'), findsOneWidget);
        expect(find.text('반드시 확인 · 원본의 기호·값을 대조해 주세요'), findsOneWidget);
        expect(find.widgetWithText(ActionChip, '영역 6'), findsOneWidget);
        expect(find.widgetWithText(ActionChip, '영역 11'), findsOneWidget);
        expect(find.widgetWithText(ActionChip, '영역 5'), findsOneWidget);
        expect(confirmButton(t).onPressed, isNull);
        await screenshot(t, 'bulk-result-$scale');
        // Tapping the bulk action again does not undo any checks.
        await tap(t, bulk);
        expect(checked(t, 'a'), isTrue);
        expect(checked(t, 'b'), isTrue);
        await tap(t, jump('c'));
        expect(find.text('영역 6 · 내용 수정 필요').hitTestable(), findsOneWidget);
        expect(t.widget<CheckboxListTile>(checkbox('c')).onChanged, isNull);
        await screenshot(t, 'jump-region-$scale');
        await tap(t, back('c'));
        expect(bulk.hitTestable(), findsOneWidget);
        await tap(t, jump('d'));
        expect(find.text('영역 11 · 원본 대조 필요').hitTestable(), findsOneWidget);
        await tap(t, checkbox('d'));
        await tap(t, back('d'));
        expect(find.text('확인 완료 3개 · 남은 영역 2개'), findsOneWidget);
        expect(
          jump('d'),
          findsNothing,
        ); // Individually reviewed rows leave the list.
        expect(saves, 0);
        expect(t.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'all-uncertain and all-unreadable inputs explain zero bulk checks with every number',
    (t) async {
      for (final unreadable in [false, true]) {
        await mount(t, [
          for (var i = 1; i <= 18; i++)
            {
              'id': 'r$i',
              'reading_order': i,
              'raw_text': unreadable ? 'x=?' : 'x=$i',
              'uncertain': true,
            },
        ]);
        expect(t.widget<OutlinedButton>(bulk).onPressed, isNotNull);
        await tap(t, bulk);
        expect(find.text('확인 완료 0개 · 남은 영역 18개'), findsOneWidget);
        expect(find.text('확인 완료 0개 · 남은 영역 18개').hitTestable(), findsOneWidget);
        expect(
          find.text('일괄 체크 가능한 영역이 없어요. 아래 번호를 눌러 직접 확인해 주세요.'),
          findsOneWidget,
        );
        for (var i = 1; i <= 18; i++) {
          expect(checked(t, 'r$i'), isFalse);
          expect(find.widgetWithText(ActionChip, '영역 $i'), findsOneWidget);
        }
        expect(confirmButton(t).onPressed, isNull);
        await tap(t, jump('r18'));
        expect(
          find
              .text('영역 18 · ${unreadable ? '내용 수정 필요' : '원본 대조 필요'}')
              .hitTestable(),
          findsOneWidget,
        );
        await tap(t, back('r18'));
        await screenshot(t, 'all-required-$unreadable');
        await t.pumpWidget(const SizedBox());
        await t.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'correcting an unreadable region still requires individual review and final consent',
    (t) async {
      Map<String, String>? submitted;
      await mount(
        t,
        [
          {
            'id': 'a',
            'reading_order': 1,
            'raw_text': 'x=1',
            'uncertain': false,
          },
          {
            'id': 'b',
            'reading_order': 6,
            'raw_text': 'e^{?}',
            'uncertain': true,
          },
        ],
        onConfirm: (values) async {
          submitted = values;
        },
      );
      await tap(t, bulk);
      await tap(t, jump('b'));
      await tap(t, find.text('전사 내용 수정').last);
      await t.enterText(find.byType(TextField).last, 'e^{-x}');
      await t.pumpAndSettle();
      await tap(t, find.byTooltip('키보드 닫기').last);
      await tap(t, back('b'));
      expect(find.text('반드시 수정 · 미식별 내용이 남아 있어요'), findsNothing);
      expect(find.text('반드시 확인 · 원본의 기호·값을 대조해 주세요'), findsOneWidget);
      await tap(t, bulk);
      expect(checked(t, 'b'), isFalse);
      await tap(t, jump('b'));
      await tap(t, checkbox('b'));
      await tap(t, back('b'));
      expect(find.text('확인 완료 2개 · 남은 영역 0개'), findsOneWidget);
      expect(
        find
            .byType(ActionChip)
            .evaluate()
            .where((e) => e.widget.key.toString().contains('review-region-')),
        isEmpty,
      );
      expect(confirmButton(t).onPressed, isNull);
      await tap(t, find.text(consent));
      expect(confirmButton(t).onPressed, isNotNull);
      await tap(t, bulk); // Idempotent, even after final consent.
      expect(confirmButton(t).onPressed, isNotNull);
      await tap(t, find.text('답안 입력 완료'));
      expect(submitted, {'a': 'x=1', 'b': 'e^{-x}'});
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'busy state blocks bulk changes and new source resets selection and summary',
    (t) async {
      final regions = [
        {'id': 'a', 'raw_text': 'x=1', 'uncertain': false},
        {'id': 'b', 'raw_text': 'x=2', 'uncertain': false},
      ];
      await mount(t, regions, busy: true);
      expect(t.widget<OutlinedButton>(bulk).onPressed, isNull);
      await mount(t, regions);
      await tap(t, bulk);
      expect(find.text('확인 완료 2개 · 남은 영역 0개'), findsOneWidget);
      expect(confirmButton(t).onPressed, isNull);
      await mount(t, [
        regions.first,
        {...regions.last, 'raw_text': 'x=3'},
      ]);
      expect(checked(t, 'a'), isFalse);
      expect(checked(t, 'b'), isFalse);
      expect(find.textContaining('확인 완료 2개'), findsNothing);
      expect(confirmButton(t).onPressed, isNull);
    },
  );

  const savedInput = String.fromEnvironment('MATH_BULK_STORED_INPUT');
  if (savedInput.isNotEmpty) {
    testWidgets(
      'saved Hanyang input lists original mandatory region numbers without Provider calls',
      (t) async {
        final input = jsonDecode(
          File(savedInput).readAsStringSync(),
        ) as Map<String, dynamic>;
        final regions = (input['candidate_regions'] as List)
            .cast<Map<String, dynamic>>();
        final originalJson = jsonEncode(regions);
        await mount(t, regions);
        await tap(t, bulk);
        expect(jsonEncode(regions), originalJson);
        expect(find.byType(ActionChip), findsNWidgets(regions.length));
        for (final region in regions) {
          expect(
            find.widgetWithText(ActionChip, '영역 ${region['reading_order']}'),
            findsOneWidget,
          );
          expect(checked(t, '${region['id']}'), isFalse);
        }
        expect(confirmButton(t).onPressed, isNull);
        await screenshot(t, 'stored-hanyang-required');
        expect(t.takeException(), isNull);
      },
    );
  }
}
