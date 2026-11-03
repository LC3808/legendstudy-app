import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/math_text.dart';
import 'package:legendstudy_app/features/essay/math_mobile/math_answer_evidence.dart';
import 'package:legendstudy_app/shared/widgets/shell_widgets.dart';
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
  for (final scale in [1.0, 2.0]) {
    testWidgets('task hints and rewrite remain reachable at $scale text', (
      t,
    ) async {
      t.view.physicalSize = const Size(393, 852);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final data = mathMobilePreviewSnapshot(), calls = <int>[];
      var rewritten = false;
      await t.pumpWidget(
        host(
          MathTaskPage(
            task: objects(data['tasks']).first,
            concepts: objects(data['concepts']),
            evaluationId: 'e',
            onRewrite: () async {
              rewritten = true;
            },
            request: (a, p) async {
              calls.add(p['level'] as int);
              return {
                'body': p['level'] == 1 ? 'SAFE_HINT_ONE' : 'SAFE_HINT_TWO',
              };
            },
          ),
          scale: scale,
        ),
      );
      await t.pumpAndSettle();
      await screenshot(t, 'task-$scale');
      await t.scrollUntilVisible(
        find.text('개념 힌트 보기'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.text('개념 힌트 보기'));
      await t.pumpAndSettle();
      await t.ensureVisible(find.text('해결 방향 보기'));
      await t.tap(find.text('해결 방향 보기'));
      await t.pumpAndSettle();
      expect(calls, [1, 2]);
      expect(find.text('SAFE_HINT_ONE'), findsOneWidget);
      expect(find.text('SAFE_HINT_TWO'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('직접 풀이 수정하기'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await screenshot(t, 'task-actions-$scale');
      await t.tap(find.text('직접 풀이 수정하기'));
      expect(rewritten, isTrue);
      expect(t.takeException(), isNull);
    });
  }
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
  for (final scale in [1.0, 2.0]) {
    testWidgets('solution and history facts remain readable at $scale text', (
      t,
    ) async {
      t.view.physicalSize = const Size(393, 852);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
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
          scale: scale,
        ),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('단계 설명'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(t.takeException(), isNull);
      expect(
        find.byWidgetPredicate(
          (w) => w is MathText && w.text == r'\(W=k/l\)의 확률분포를 구한다.',
        ),
        findsOneWidget,
      );
      await screenshot(t, 'solution-$scale');
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
          scale: scale,
        ),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('학습 안내'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await screenshot(t, 'history-$scale');
      expect(t.takeException(), isNull);
      expect(find.text('전체 해설 공개됨'), findsOneWidget);
    });
  }
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

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'recognition comparison fits content and preserves original zoom at $scale',
      (t) async {
        t.view.physicalSize = const Size(393, 852);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final Uint8List bytes = (await t.runAsync(() async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawColor(Colors.white, BlendMode.src);
          canvas.drawRect(
            const Rect.fromLTWH(20, 40, 240, 50),
            Paint()..color = Colors.black,
          );
          final picture = recorder.endRecording();
          final image = await picture.toImage(300, 200);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          picture.dispose();
          return data!.buffer.asUint8List();
        }))!;
        final texts = [
          r'\frac{x^2+1}{x-1}',
          r'\begin{aligned} a&=1\\ b&=2\\ c&=3\\ d&=4\\ e&=5\end{aligned}',
          List.generate(
            30,
            (i) => '조건 $i 를 확인하고 풀이의 근거를 원본과 대조합니다.',
          ).join('\n'),
        ];
        var confirmed = false;
        await t.pumpWidget(
          host(
            Scaffold(
              body: ListView(
                children: [
                  MathRecognitionPanel(
                    regions: [
                      for (var i = 0; i < texts.length; i++)
                        {
                          'id': 'r$i',
                          'reading_order': i + 1,
                          'artifact_id': 'photo',
                          'raw_text': texts[i],
                          'x': 0.05,
                          'y': 0.15,
                          'width': 0.85,
                          'height': 0.4,
                        },
                    ],
                    sources: {'photo': bytes},
                    onConfirm: (_) async => confirmed = true,
                  ),
                ],
              ),
            ),
            scale: scale,
          ),
        );
        await t.pumpAndSettle();
        final panels = find.byType(TabBarView);
        final shortHeight = t.getSize(panels.at(0)).height;
        final multilineHeight = t.getSize(panels.at(1)).height;
        expect(shortHeight, lessThan(230));
        expect(multilineHeight, greaterThan(shortHeight));
        expect(t.getSize(panels.at(2)).height, lessThanOrEqualTo(320));
        expect(
          t.getSize(panels.at(2)).height,
          greaterThanOrEqualTo(multilineHeight),
        );
        final card = t.widget<Card>(find.byType(Card).first);
        expect(
          (card.shape! as RoundedRectangleBorder).side.color,
          AcademicPurple.primary,
        );
        await screenshot(t, 'recognition-adaptive-$scale');
        await t.tap(find.text('원본 이미지').first);
        await t.pump();
        await t.pump(const Duration(milliseconds: 400));
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pumpAndSettle();
        expect(t.getSize(panels.at(0)).height, shortHeight);
        await t.tap(find.byTooltip('원본 크게 보기').first);
        await t.pump();
        await t.pump(const Duration(milliseconds: 400));
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await t.pumpAndSettle();
        expect(find.text('영역 1 · 원본 대조'), findsOneWidget);
        expect(
          t.getSize(find.byType(MathSourceRegion).last).height,
          greaterThan(500),
        );
        expect(
          t.widget<MathSourceRegion>(find.byType(MathSourceRegion).last).bytes,
          same(bytes),
        );
        await t.tap(find.byType(BackButton));
        await t.pumpAndSettle();
        await t.tap(find.text('인식 수식').first);
        await t.pumpAndSettle();
        // The full long transcript remains reachable, rather than being truncated.
        await t.ensureVisible(panels.at(2));
        await t.pumpAndSettle();
        final inner = find
            .descendant(
              of: panels.at(2),
              matching: find.byType(SingleChildScrollView),
            )
            .first;
        await t.drag(inner, const Offset(0, -2500));
        await t.pumpAndSettle();
        final scroll = t.state<ScrollableState>(
          find.descendant(of: inner, matching: find.byType(Scrollable)).first,
        );
        expect(scroll.position.pixels, greaterThan(0));
        scroll.position.jumpTo(scroll.position.maxScrollExtent);
        await t.pumpAndSettle();
        expect(scroll.position.extentAfter, 0);
        expect(t.takeException(), isNull);
        expect(confirmed, isFalse);
      },
    );
  }

  testWidgets('editing transcription grows and shrinks its comparison area', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        Scaffold(
          body: ListView(
            children: [
              MathRecognitionPanel(
                regions: const [
                  {'id': 'r1', 'raw_text': 'x=1'},
                ],
                onConfirm: (_) async {},
              ),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final panel = find.byType(TabBarView);
    final shortHeight = t.getSize(panel).height;
    await t.tap(find.text('전사 내용 수정'));
    await t.pumpAndSettle();
    await t.enterText(
      find.byType(TextField),
      r'\begin{aligned} a&=1\\ b&=2\\ c&=3\\ d&=4\\ e&=5\end{aligned}',
    );
    await t.pumpAndSettle();
    expect(t.getSize(panel).height, greaterThan(shortHeight));
    await t.enterText(find.byType(TextField), 'x=2');
    await t.pumpAndSettle();
    expect(t.getSize(panel).height, shortHeight);
    expect(t.takeException(), isNull);
    expect(
      t
          .widget<FilledButton>(find.widgetWithText(FilledButton, '답안 입력 완료'))
          .onPressed,
      isNull,
    );
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'submission progress and structured evidence capture at $scale',
      (t) async {
        await t.binding.setSurfaceSize(const Size(393, 852));
        addTearDown(() => t.binding.setSurfaceSize(null));
        await t.pumpWidget(
          host(
            Scaffold(
              appBar: AppBar(title: const Text('답안 확인')),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    '한양대학교 · 문제 1',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  const Text('수식과 문장을 인식하고 있어요'),
                  const SizedBox(height: 16),
                  const StepProgressBar(
                    steps: ['답안 준비', '입력 인식', '내용 확인'],
                    activeIndex: 1,
                    activeColor: AcademicPurple.primary,
                    trackColor: AcademicPurple.emphasis,
                  ),
                ],
              ),
            ),
            scale: scale,
          ),
        );
        await t.pump(const Duration(milliseconds: 400));
        await screenshot(t, 'b54-progress-$scale');
        expect(t.takeException(), isNull);
        await t.pumpWidget(
          host(
            Scaffold(
              appBar: AppBar(title: const Text('첨삭 결과')),
              body: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    '잘한 점',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),
                  const MathCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '타당한 풀이 단계의 유지',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text('학생이 확인한 답안에서 풀이 과정을 확인해 보세요.'),
                        SizedBox(height: 16),
                        MathContentSection(
                          label: '학생 답안 근거',
                          child: MathAnswerEvidence(
                            '문제 1\ni) a > 0, r < 0일 때\n'
                            r'\(a_n = ar^{n-1}\)'
                            '\n'
                            '주어진 조건을 적용한다.\n'
                            r'\[\frac{a}{1-r}=200\]'
                            '\n'
                            r'\[r=-\frac{1}{6}\]'
                            '\n'
                            'ii) a < 0, r > 0일 때\n'
                            r'\[a_n=-ar^{n-1}\]'
                            '\n'
                            '부호와 조건을 다시 대조한다.\n마지막 문장',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    '우선 개선할 부분',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            scale: scale,
          ),
        );
        await t.pumpAndSettle();
        await screenshot(t, 'b54-evidence-collapsed-$scale');
        await t.ensureVisible(find.text('답안 근거 전체 보기'));
        await t.tap(find.text('답안 근거 전체 보기'));
        await t.pumpAndSettle();
        await screenshot(t, 'b54-evidence-expanded-$scale');
        expect(t.takeException(), isNull);
      },
    );
  }
  for (final uncertain in [false, true]) {
    testWidgets(
      'bulk recognition confirmation keeps final consent and uncertainty gate: $uncertain',
      (t) async {
        await t.binding.setSurfaceSize(const Size(393, 852));
        addTearDown(() => t.binding.setSurfaceSize(null));
        var saves = 0;
        await t.pumpWidget(
          host(
            Scaffold(
              body: SingleChildScrollView(
                child: MathRecognitionPanel(
                  regions: [
                    {'id': 'a', 'raw_text': 'x=1', 'uncertain': false},
                    {
                      'id': 'b',
                      'raw_text': uncertain ? 'e^{?}' : 'r=-1/6',
                      'uncertain': uncertain,
                    },
                  ],
                  onConfirm: (_) async {
                    saves++;
                  },
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        await t.ensureVisible(find.text('전체 내용 확인'));
        await t.tap(find.text('전체 내용 확인'));
        await t.pumpAndSettle();
        var checks = t
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
            .toList();
        expect(checks[0].value, isTrue);
        expect(checks[1].value, !uncertain);
        expect(checks.last.value, isFalse);
        expect(saves, 0);
        expect(
          t
              .widget<FilledButton>(
                find.widgetWithText(FilledButton, '답안 입력 완료'),
              )
              .onPressed,
          isNull,
        );
        if (!uncertain) {
          await t.ensureVisible(find.text('모든 영역을 확인했으며 이 전사본으로 첨삭을 요청합니다.'));
          await t.tap(find.text('모든 영역을 확인했으며 이 전사본으로 첨삭을 요청합니다.'));
          await t.pumpAndSettle();
          expect(
            t
                .widget<FilledButton>(
                  find.widgetWithText(FilledButton, '답안 입력 완료'),
                )
                .onPressed,
            isNotNull,
          );
          // A correction invalidates its individual check and the final consent.
          await t.ensureVisible(find.text('전사 내용 수정').first);
          await t.tap(find.text('전사 내용 수정').first);
          await t.pumpAndSettle();
          await t.enterText(find.byType(TextField).first, 'x=2');
          await t.pumpAndSettle();
          checks = t
              .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
              .toList();
          expect(checks.first.value, isFalse);
          expect(checks.last.value, isFalse);
        } else {
          expect(checks.last.onChanged, isNull);
        }
        expect(saves, 0);
        expect(t.takeException(), isNull);
      },
    );
  }
  const storedEvidence = String.fromEnvironment('MATH_STORED_COACHING');
  if (capture && storedEvidence.isNotEmpty) {
    testWidgets('stored Hanyang evidence renders without new Provider calls', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final saved = jsonDecode(
        File(storedEvidence).readAsStringSync(),
      ) as Map<String, dynamic>;
      final evidence =
          (saved['strengths'] as List).first['student_formula'] as String;
      expect(mathAnswerBlocks(evidence).join(), evidence);
      await t.pumpWidget(
        host(
          Scaffold(
            appBar: AppBar(title: const Text('학생 답안 근거')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: MathAnswerEvidence(evidence),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await screenshot(t, 'b54-stored-hanyang-collapsed');
      await t.tap(find.text('답안 근거 전체 보기'));
      await t.pumpAndSettle();
      await screenshot(t, 'b54-stored-hanyang-expanded');
      await t.scrollUntilVisible(
        find.text('답안 근거 접기'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      expect(t.takeException(), isNull);
      await t.pumpAndSettle();
      expect(find.text('답안 근거 접기').hitTestable(), findsOneWidget);
      await screenshot(t, 'b54-stored-hanyang-end');
    });
  }
}
