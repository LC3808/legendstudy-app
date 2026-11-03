import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/math_text.dart';
import 'package:legendstudy_app/features/essay/math_mobile/academic_purple.dart';
import 'package:legendstudy_app/features/essay/math_mobile/coaching_contract.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_coaching_screen.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_formula_editor.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_image_tools.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_mobile_preview.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_recognition_panel.dart';

void main() {
  const capture = bool.fromEnvironment('TASK16F_CAPTURE');
  setUpAll(() async {
    if (capture) {
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

      await (FontLoader('Pretendard')..addFont(
            File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  Future<void> screenshot(WidgetTester t, String name) async {
    if (!capture) return;
    await t.runAsync(() async {
      final boundary = t.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')),
      );
      final image = await boundary.toImage(pixelRatio: 2),
          bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final folder = Directory('/private/tmp/legendstudy-task16f-screens');
      await folder.create(recursive: true);
      await File('${folder.path}/$name.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  Widget host(Widget child, {double scale = 1}) => MaterialApp(
    theme: ThemeData(useMaterial3: true, fontFamily: 'Pretendard'),
    home: RepaintBoundary(
      key: const ValueKey('capture'),
      child: MediaQuery(
        data: MediaQueryData(
          size: const Size(393, 852),
          textScaler: TextScaler.linear(scale),
        ),
        child: MathMobileTheme(child: child),
      ),
    ),
  );
  test(
    'contract rejects premature full solutions and more than five tasks',
    () {
      final data = mathMobilePreviewSnapshot();
      expect(
        () => CoachingSnapshot({...data, 'full_solution': <String, dynamic>{}}),
        throwsFormatException,
      );
      expect(
        () => CoachingSnapshot({
          ...data,
          'tasks': List.filled(6, (data['tasks'] as List).first),
        }),
        throwsFormatException,
      );
      expect(CoachingSnapshot(data).chargeLabel, '무료 재첨삭 1회 남음');
      expect(
        CoachingSnapshot({
          ...data,
          'rewrite_policy': {'eligible': false, 'paid_available': true},
        }).chargeLabel,
        '이용권 1개 사용',
      );
      expect(unresolvedMath(r'e^{?}'), isTrue);
      expect(unresolvedMath('[이하 일부 판독 불명]'), isTrue);
      expect(unresolvedMath('[분수식]'), isTrue);
      expect(unresolvedMath('[ 분수식 ]'), isTrue);
      expect(unresolvedMath('분수식의 분모는 0이 아니다.'), isFalse);
      expect(unresolvedMath('[판독 불확실: x 또는 -x]'), isTrue);
      expect(unresolvedMath('[인식 불가]'), isTrue);
      expect(unresolvedMath(r'\frac{}{}'), isTrue);
      expect(unresolvedMath(r'e^{-x}'), isFalse);
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets('Academic Purple native result and concepts at $scale text', (
      t,
    ) async {
      t.view.physicalSize = const Size(393, 852);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final data = CoachingSnapshot(mathMobilePreviewSnapshot());
      await t.pumpWidget(
        host(
          MathCoachingScreen(
            snapshot: data,
            request: (a, p) async => {'attempts': <dynamic>[]},
            onRewrite: (_) async {},
          ),
          scale: scale,
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('72%'), findsNothing);
      expect(find.text('첨삭 결과'), findsOneWidget);
      expect(t.takeException(), isNull);
      await screenshot(t, 'result-$scale');
      await t.tap(find.text('기본 개념 확인'));
      await t.pumpAndSettle();
      await t.tap(find.text('합성함수의 미분법'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await screenshot(t, 'concepts-$scale');
    });
  }
  testWidgets('task hints accumulate without exposing final solution', (
    t,
  ) async {
    t.view.physicalSize = const Size(393, 852);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final data = mathMobilePreviewSnapshot(), calls = <int>[];
    await t.pumpWidget(
      host(
        MathTaskPage(
          task: objects(data['tasks']).first,
          concepts: objects(data['concepts']),
          evaluationId: 'e',
          onRewrite: () async {},
          request: (a, p) async {
            calls.add(p['level'] as int);
            return {
              'body': p['level'] == 1 ? 'SAFE_HINT_ONE' : 'SAFE_HINT_TWO',
            };
          },
        ),
      ),
    );
    await t.pumpAndSettle();
    await screenshot(t, 'task');
    await t.tap(find.text('개념 힌트 보기'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('해결 방향 보기'));
    await t.tap(find.text('해결 방향 보기'));
    await t.pumpAndSettle();
    expect(calls, [1, 2]);
    expect(find.text('SAFE_HINT_ONE'), findsOneWidget);
    expect(find.text('SAFE_HINT_TWO'), findsOneWidget);
  });
  testWidgets(
    'explicit full-solution request is required and server failure remains closed',
    (t) async {
      t.view.physicalSize = const Size(393, 852);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      var calls = 0;
      final data = CoachingSnapshot({
        ...mathMobilePreviewSnapshot(),
        'tasks': <dynamic>[],
        'strengths': <dynamic>[],
      });
      await t.pumpWidget(
        host(
          MathCoachingScreen(
            snapshot: data,
            onRewrite: (_) async {},
            request: (a, p) async {
              calls++;
              throw StateError('offline');
            },
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('전체 풀이 및 해설 보기'));
      await t.tap(find.text('전체 풀이 및 해설 보기'));
      await t.pumpAndSettle();
      expect(calls, 0);
      await screenshot(t, 'disclosure-confirmation');
      await t.tap(find.text('정답·해설 공개'));
      await t.pumpAndSettle();
      expect(calls, 1);
      expect(find.byType(MathSolutionPage), findsNothing);
    },
  );
  testWidgets(
    'uncertainty blocks confirmation; editing invalidates source acceptance',
    (t) async {
      t.view.physicalSize = const Size(393, 852);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      var saved = 0;
      await t.pumpWidget(
        host(
          Scaffold(
            body: ListView(
              children: [
                MathRecognitionPanel(
                  regions: [
                    {
                      'id': 'q1',
                      'reading_order': 13,
                      'raw_text': 'e^{?}',
                      'normalized_math': 'e^{?}',
                      'uncertain': true,
                    },
                  ],
                  onConfirm: (_) async {
                    saved++;
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        t
            .widget<FilledButton>(find.widgetWithText(FilledButton, '답안 입력 완료'))
            .onPressed,
        isNull,
      );
      await screenshot(t, 'recognition');
      await t.tap(find.text('전사 내용 수정'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), r'e^{-x}');
      await t.pumpAndSettle();
      expect(t.testTextInput.isVisible, isTrue);
      await t.ensureVisible(find.byTooltip('키보드 닫기'));
      await t.tap(find.byTooltip('키보드 닫기'));
      await t.pumpAndSettle();
      expect(t.testTextInput.isVisible, isFalse);
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        r'e^{-x}',
      );
      expect(saved, 0); // Closing the keyboard does not confirm or evaluate.
      await Scrollable.ensureVisible(
        t.element(find.text('원본을 대조했고 수정한 기호·값을 확인했어요')),
        alignment: 0.3,
      );
      await t.pumpAndSettle();
      await t.tap(find.text('원본을 대조했고 수정한 기호·값을 확인했어요'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('모든 영역을 확인했으며 이 전사본으로 첨삭을 요청합니다.'));
      await t.tap(find.text('모든 영역을 확인했으며 이 전사본으로 첨삭을 요청합니다.'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('답안 입력 완료'));
      await t.tap(find.text('답안 입력 완료'));
      expect(saved, 1);
      await t.enterText(find.byType(TextField), r'e^{?}');
      await t.pumpAndSettle();
      expect(
        t
            .widget<FilledButton>(find.widgetWithText(FilledButton, '답안 입력 완료'))
            .onPressed,
        isNull,
      );
    },
  );
  testWidgets(
    'photo rotation/crop creates a separate image and preserves original bytes',
    (t) async {
      await t.runAsync(() async {
        final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 20, 30),
          Paint()..color = Colors.purple,
        );
        final picture = recorder.endRecording(),
            image = await picture.toImage(20, 30);
        final raw = await image.toByteData(format: ui.ImageByteFormat.png);
        final original = raw!.buffer.asUint8List(), copy = original.toList();
        image.dispose();
        picture.dispose();
        final derived = await transformMathPhoto(
          original,
          turns: 1,
          crop: const Rect.fromLTRB(0, 0, .5, 1),
        );
        final codec = await ui.instantiateImageCodec(derived);
        final result = await codec.getNextFrame();
        expect(result.image.width, 15);
        expect(result.image.height, 20);
        expect(original, copy);
        result.image.dispose();
        codec.dispose();
      });
    },
  );
  testWidgets('full solution and history render only supplied source facts', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        const MathSolutionPage(
          solution: {
            'references': [
              {
                'origin': 'OFFICIAL',
                'body': r'\[\frac{1}{2}+\int_0^1 x^2 dx\]',
              },
            ],
            'steps': [
              {
                'position': 1,
                'representation': 'W=k/l의 확률분포를 구한다.',
                'explanation': '조건을 확인한다.',
              },
            ],
            'paths': <dynamic>[],
          },
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(
      find.byWidgetPredicate(
        (w) => w is MathText && w.text == r'\(W=k/l\)의 확률분포를 구한다.',
      ),
      findsOneWidget,
    );
    await screenshot(t, 'solution');
    await t.pumpWidget(
      host(
        Scaffold(
          body: MathCoachingHistory(
            snapshot: CoachingSnapshot(mathMobilePreviewSnapshot()),
            request: (a, p) async => {
              'attempts': [
                {
                  'resolve_kind': 'INITIAL',
                  'completed_at': '2026-11-02',
                  'evaluation_state': 'COMPLETED',
                  'exposed_hint_levels': [1, 2],
                  'solution_revealed': true,
                  'credit_label': '검수 예제 · 실제 차감 없음',
                },
              ],
            },
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await screenshot(t, 'history');
    expect(find.text('전체 해설 공개됨'), findsOneWidget);
  });
  testWidgets(
    'Q2 confirmation preserves conclusion omitted by normalized math',
    (t) async {
      await t.pumpWidget(
        host(
          Scaffold(
            body: ListView(
              children: [
                MathRecognitionPanel(
                  regions: [
                    {
                      'id': 'q2',
                      'raw_text': '25<n<100 (최댓값 99, 최솟값 26)',
                      'normalized_math': '25<n<100',
                      'uncertain': true,
                    },
                  ],
                  onConfirm: (_) async {},
                ),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('전사 내용 수정'));
      await t.pumpAndSettle();
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        contains('최댓값 99, 최솟값 26'),
      );
    },
  );
}
