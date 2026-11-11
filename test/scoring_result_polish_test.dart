import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/learning/learning_widgets.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_display_title.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_result_view.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';

import 'support/grade_fixture.dart';
import 'practice_grade_test.dart' show sampleAttempt;

const render = bool.fromEnvironment('SCORING_UX_RENDER');
final frame = GlobalKey();
Future<void> capture(WidgetTester t, String name) async {
  if (!render) return;
  await t.pump();
  await t.runAsync(() async {
    final image =
        await (frame.currentContext!.findRenderObject()
                as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('/private/tmp/legendstudy-scoring-ux')
      ..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    if (render) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader('ScoringPreview')..addFont(
            File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
    }
  });
  test('display title retains academic year, source and safe fallback', () {
    const title =
        '[2024년 11월 시행] 2025학년도 수능 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학';
    expect(scoringDisplayTitle(title), '2025학년도 수능 기출');
    expect(scoringDisplayTitle('2027학년도 9월 모의평가 - 문제/정답'), '2027학년도 9월 모의평가');
    expect(scoringDisplayTitle('2025학년도 수능 기출'), '2025학년도 수능 기출');
    expect(scoringDisplayTitle('낯선 시험명'), '낯선 시험명');
    expect(title, contains('문제, 답'));
  });
  testWidgets('grade reference banner preview', (t) async {
    t.view.physicalSize = const Size(428, 926);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light.copyWith(
          textTheme: AppTheme.light.textTheme.apply(
            fontFamily: render ? 'ScoringPreview' : null,
          ),
        ),
        builder: (context, child) => RepaintBoundary(key: frame, child: child!),
        home: Scaffold(
          appBar: AppBar(title: const Text('시험 결과')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ScoringResultView(attempt: sampleAttempt(), guest: true),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('추정 등급 · 1등급'), findsOneWidget);
    expect(t.takeException(), isNull);
    await capture(t, 'estimated-grade');
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('score, numeric answers and time metrics readable at $scale', (
      t,
    ) async {
      t.view.physicalSize = const Size(428, 926);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      Widget app(Widget child) => MaterialApp(
        theme: AppTheme.light.copyWith(
          textTheme: AppTheme.light.textTheme.apply(
            fontFamily: render ? 'ScoringPreview' : null,
          ),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(key: frame, child: child!),
        ),
        home: child,
      );
      final answers = List.generate(
        30,
        (i) => AnswerReview.typed(
          i + 1,
          i == 29
              ? 315
              : i == 27
              ? 3
              : 1,
          i < 20 ? 3 : 4,
          answerType: i == 29 ? 'numeric' : 'multiple_choice',
          acceptedAnswers: [
            i == 29
                ? 316
                : i == 27 || i == 21
                ? 4
                : 1,
          ],
          questionId: 'q${i + 1}',
        ),
      );
      final score = ScoreResult(88, 100, answers);
      final attempt = ScoringAttempt(
        id: 'synthetic-preview',
        title: '[2024년 11월 시행] 2025학년도 수능 기출 - 문제, 답, 해설',
        subject: '수학 · 기하',
        draft: gradeDraft('unavailable', List.filled(100, 1)),
        result: score,
      );
      await t.pumpWidget(
        app(
          Scaffold(
            appBar: AppBar(title: const Text('시험 결과')),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ScoringResultView(attempt: attempt, guest: true),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('88 / 100점'), findsOneWidget);
      expect(t.takeException(), isNull);
      if (scale == 1) await capture(t, 'result');
      await t.ensureVisible(find.text('답안 확인'));
      await t.tap(find.text('답안 확인'));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      if (scale == 1) await capture(t, 'answers');
      await t.ensureVisible(find.text('30번 · 오답'));
      await t.pumpAndSettle();
      expect(find.text('315'), findsOneWidget);
      expect(find.text('316'), findsOneWidget);
      expect(t.takeException(), isNull);
      if (scale == 1) await capture(t, 'numeric-answer');
      await t.pageBack();
      await t.pumpAndSettle();
      await t.pumpWidget(
        app(
          Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    const StudySummaryMetrics(
                      today: 1200000,
                      allTime: 36120000,
                      week: 10800000,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('0시간 20분'), findsOneWidget);
      expect(find.text('10시간 2분'), findsOneWidget);
      expect(find.text('3시간 0분'), findsOneWidget);
      final labels = t
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data)
          .toList();
      expect(labels.indexOf('오늘 공부시간'), lessThan(labels.indexOf('이번 주 공부시간')));
      expect(labels.indexOf('이번 주 공부시간'), lessThan(labels.indexOf('누적 공부시간')));
      expect(
        t.widget<Text>(find.text('0시간 20분')).style!.color,
        isNot(t.widget<Text>(find.text('10시간 2분')).style!.color),
      );
      expect(t.takeException(), isNull);
      if (scale == 1) await capture(t, 'study-metrics');
    });
  }
}
