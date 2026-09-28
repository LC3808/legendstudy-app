import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/essay/essay_models.dart';
import 'package:legendstudy_app/features/essay/essay_preview.dart';
import 'package:legendstudy_app/features/essay/essay_controller.dart';
import 'package:legendstudy_app/features/essay/essay_pages.dart';
import 'package:legendstudy_app/features/lab/lab_page.dart';

import 'core_ux_test.dart' as preview;

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CORE_RENDER')) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final f = File('/System/Library/Fonts/AppleSDGothicNeo.ttc');
      await (FontLoader(
        'CorePreview',
      )..addFont(f.readAsBytes().then(ByteData.sublistView))).load();
    }
  });
  void size(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> show(
    WidgetTester tester,
    Widget child, {
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      ProviderScope(child: preview.app(child, scale: scale)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> close(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('existing LAB entry navigates native preview and back', (
    tester,
  ) async {
    size(tester, const Size(360, 740));
    final router = GoRouter(
      initialLocation: '/lab',
      routes: [
        GoRoute(
          path: '/lab',
          builder: (_, _) => const Scaffold(body: LabPage()),
          routes: essayRoutes,
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await tapVisible(tester, find.text('논술 화면 미리보기'));
    expect(find.byType(EssayHomePage), findsOneWidget);
    await tapVisible(tester, find.text('문항 1 · 공공 공간과 선택'));
    expect(find.byType(EssayWorkspacePage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(EssayHomePage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(LabPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester);
  });

  testWidgets('university and exam selection resets question context', (
    tester,
  ) async {
    size(tester, const Size(360, 800));
    await show(tester, const EssayHomePage());
    expect(find.textContaining('평가 자료 일부'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2025 정규논술 · 인문계').last);
    await tester.pumpAndSettle();
    expect(find.text('문항 1 · 비교 기준'), findsOneWidget);
    expect(find.text('문항 1 · 공공 공간과 선택'), findsNothing);
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('누리대학교 (가상)').last);
    await tester.pumpAndSettle();
    expect(find.text('문항 1 · 요약'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester);
  });
  testWidgets('save failure retains text, retry saves before submission', (
    tester,
  ) async {
    size(tester, const Size(360, 800));
    final gateway = PreviewEssayGateway()..failSave = true;
    final c = EssayController(gateway, initialBody: previewAnswer);
    addTearDown(c.dispose);
    await show(
      tester,
      EssayWorkspacePage(question: essayPreviewQuestions.first, controller: c),
    );
    await tester.enterText(
      find.byKey(const ValueKey('essay-editor')),
      '보존할 답안',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 250));
    expect(c.draftStatus, DraftStatus.failed);
    expect(c.body, '보존할 답안');
    gateway.failSave = false;
    await tapVisible(tester, find.text('저장 다시 시도'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(c.draftStatus, DraftStatus.saved);
    expect(gateway.draft.body, '보존할 답안');
    await close(tester);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('360px writing switching retains text scale $scale', (
      tester,
    ) async {
      size(tester, const Size(360, 800));
      await show(
        tester,
        EssayWorkspacePage(question: essayPreviewQuestions.first),
        scale: scale,
      );
      await tester.enterText(
        find.byKey(const ValueKey('essay-editor')),
        '나의 작성 내용',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 250));
      await tester.tap(find.text('문제'));
      await tester.pumpAndSettle();
      expect(find.text('문제'), findsWidgets);
      await tester.tap(find.text('답안'));
      await tester.pumpAndSettle();
      expect(find.text('나의 작성 내용'), findsOneWidget);
      expect(find.text('8자 · 공백 포함'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await preview.capture(tester, 'essay-writing-mobile-${scale.toInt()}x');
      await close(tester);
    });
  }
  testWidgets('desktop independent split and official timer scope', (
    tester,
  ) async {
    size(tester, const Size(1280, 960));
    await show(
      tester,
      EssayWorkspacePage(question: essayPreviewQuestions.first),
    );
    expect(find.byType(SegmentedButton<bool>), findsNothing);
    expect(find.text('제시문 (가)'), findsOneWidget);
    expect(find.byKey(const ValueKey('essay-editor')), findsOneWidget);
    await preview.capture(tester, 'essay-writing-desktop');
    await tester.tap(find.text('실전 모드로'));
    await tester.pump();
    expect(find.textContaining('자동 제출하지 않습니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await close(tester);
  });
  testWidgets(
    'immutable first answer, result, rewrite, second change and collapsed example',
    (tester) async {
      size(tester, const Size(360, 800));
      final gateway = PreviewEssayGateway();
      final c = EssayController(gateway, initialBody: previewAnswer);
      addTearDown(c.dispose);
      await show(
        tester,
        EssayWorkspacePage(
          question: essayPreviewQuestions.first,
          controller: c,
        ),
      );
      await tapVisible(tester, find.text('제출하고 첨삭 화면 살펴보기'));
      expect(c.stage, EssayStage.result);
      expect(find.text('종합 평가'), findsOneWidget);
      expect(find.text('첨삭을 반영한 예시 답안 · AI 생성'), findsNothing);
      await preview.capture(tester, 'essay-result-mobile');
      await tapVisible(tester, find.text('다시 써보기'));
      expect(find.text('내 첫 답안'), findsOneWidget);
      await preview.capture(tester, 'essay-rewrite-mobile');
      await tester.enterText(
        find.byKey(const ValueKey('essay-editor')),
        '수정한 새로운 답안',
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 250));
      await tapVisible(tester, find.text('제출하고 첨삭 화면 살펴보기'));
      expect(c.stage, EssayStage.comparison);
      expect(gateway.submitted, [previewAnswer, '수정한 새로운 답안']);
      expect(find.text('이번 답안의 변화 한눈에 보기'), findsOneWidget);
      expect(find.text('→'), findsNWidgets(3));
      expect(find.textContaining('길어진 문장'), findsWidgets);
      await preview.capture(tester, 'essay-comparison-mobile');
      await tapVisible(tester, find.text('첨삭을 반영한 예시답안 보기'));
      expect(find.textContaining('대학의 공식 답안이 아닙니다'), findsOneWidget);
      await close(tester);
    },
  );
  testWidgets('first result offers soft nudge without locking example', (
    tester,
  ) async {
    size(tester, const Size(360, 800));
    var rewrites = 0;
    await show(
      tester,
      EssayResultView(
        evaluation: firstPreviewEvaluation,
        question: essayPreviewQuestions.first,
        comparison: false,
        onRewrite: () => rewrites++,
      ),
    );
    expect(find.text(firstPreviewEvaluation.example), findsNothing);
    await tapVisible(tester, find.text('첨삭을 반영한 예시답안 보기'));
    expect(find.text('직접 다시 써보기'), findsOneWidget);
    await tester.tap(find.text('그래도 예시 답안 보기'));
    await tester.pumpAndSettle();
    expect(find.text(firstPreviewEvaluation.example), findsOneWidget);
    expect(rewrites, 0);
    await close(tester);
  });
  testWidgets('CAS conflict preserves local text until explicit reload', (
    tester,
  ) async {
    size(tester, const Size(360, 800));
    final gateway = PreviewEssayGateway()
      ..draft = const EssayDraft('다른 기기의 내용', 2);
    final c = EssayController(gateway, initialBody: previewAnswer);
    addTearDown(c.dispose);
    await show(
      tester,
      EssayWorkspacePage(question: essayPreviewQuestions.first, controller: c),
    );
    await tester.enterText(
      find.byKey(const ValueKey('essay-editor')),
      '내가 보존할 내용',
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 250));
    expect(c.draftStatus, DraftStatus.conflict);
    expect(c.body, '내가 보존할 내용');
    await preview.capture(tester, 'essay-conflict-mobile');
    await tapVisible(tester, find.text('최신 내용과 비교'));
    expect(find.text('다른 기기의 내용'), findsOneWidget);
    await tester.tap(find.text('최신 내용 불러오기'));
    await tester.pumpAndSettle();
    expect(c.body, '다른 기기의 내용');
    expect(c.revision, 2);
    await close(tester);
  });
  testWidgets('processing failure retry reuses submitted snapshot', (
    tester,
  ) async {
    size(tester, const Size(360, 800));
    final gateway = PreviewEssayGateway()..failEvaluation = true;
    final c = EssayController(gateway, initialBody: previewAnswer);
    addTearDown(c.dispose);
    await show(
      tester,
      EssayWorkspacePage(question: essayPreviewQuestions.first, controller: c),
    );
    await tester.ensureVisible(find.text('제출하고 첨삭 화면 살펴보기'));
    await tester.tap(find.text('제출하고 첨삭 화면 살펴보기'));
    await tester.pump();
    expect(c.stage, EssayStage.processing);
    await tester.pumpAndSettle();
    expect(c.stage, EssayStage.failed);
    await preview.capture(tester, 'essay-failure-mobile');
    gateway.failEvaluation = false;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(c.stage, EssayStage.result);
    expect(gateway.submitted.length, 1);
    await close(tester);
  });
  testWidgets(
    'levels include accessible Korean meanings and null is not zero',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await show(
        tester,
        Column(
          children: [
            for (final level in [1, 2, 3, 4, 5, null]) EssayLevel(level),
          ],
        ),
      );
      expect(find.bySemanticsLabel('5단계 중 4단계, 대체로 충실'), findsOneWidget);
      expect(find.text('판단이 어려워요'), findsOneWidget);
      expect(find.text('★★★★★'), findsOneWidget);
      semantics.dispose();
      await close(tester);
    },
  );

  test(
    'summary excerpts preserve source prefix and keep short text intact',
    () {
      const short = '확인된 변화 없음';
      expect(essaySummaryExcerpt(short), short);
      final source = firstPreviewEvaluation.priorities.first;
      final excerpt = essaySummaryExcerpt(source);
      expect(excerpt.length, lessThan(source.length));
      expect(excerpt.endsWith('연결하기'), isTrue);
      expect(
        excerpt,
        source.replaceFirst('연결해 보세요.', '연결하기'),
      );
    },
  );

  testWidgets(
    'overview selects existing first item without inferring resolution',
    (tester) async {
      size(tester, const Size(1440, 1800));
      for (final comparison in [false, true]) {
        final e = comparison ? secondPreviewEvaluation : firstPreviewEvaluation;
        await show(
          tester,
          EssayResultView(
            evaluation: e,
            question: essayPreviewQuestions.first,
            comparison: comparison,
            onRewrite: () {},
          ),
        );
        final overview = find.byKey(const ValueKey('answer-overview'));
        Finder within(String text) =>
            find.descendant(of: overview, matching: find.text(text));
        expect(
          within(comparison ? '이번 답안의 변화 한눈에 보기' : '내 답안 한눈에 보기'),
          findsOneWidget,
        );
        for (final text in e.checklist.take(1)) {
          expect(within(essaySummaryExcerpt(text)), findsOneWidget);
        }
        expect(within(e.checklist[2]), findsNothing);
        expect(
          find.text(e.checklist[2]),
          findsOneWidget,
        ); // Detailed result preserved.
        expect(
          within(essaySummaryExcerpt(e.improvements.first)),
          findsOneWidget,
        );
        if (comparison) {
          expect(within('이번 평가에서 확인된 항목이 없어요.'), findsOneWidget);
          expect(find.text('무엇이 달라졌나요?'), findsNothing);
          expect(find.text('좋아지고 있는 부분'), findsNothing);
          expect(
            tester.widget<Text>(within('해결한 부분')).style!.color,
            const Color(0xFF5C6269),
          );
          expect(
            within(essaySummaryExcerpt(e.changes['좋아진 부분']!.first)),
            findsOneWidget,
          );
        } else {
          expect(
            within(essaySummaryExcerpt(e.priorities.first)),
            findsOneWidget,
          );
          expect(
            tester.getTopLeft(within('잘한 점')).dy,
            tester.getTopLeft(within('보완할 점')).dy,
          );
        }
        expect(tester.takeException(), isNull);
        await close(tester);
      }
    },
  );

  for (final comparison in [false, true]) {
    for (final width in [360.0, 1440.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('result hierarchy $comparison width $width scale $scale', (
          tester,
        ) async {
          size(tester, Size(width, 1800));
          final evaluation = comparison
              ? secondPreviewEvaluation
              : firstPreviewEvaluation;
          await show(
            tester,
            EssayResultView(
              evaluation: evaluation,
              question: essayPreviewQuestions.first,
              comparison: comparison,
              onRewrite: () {},
            ),
            scale: scale,
          );
          final title = find.text(evaluation.dimensions.first.label).first;
          final explanation = find
              .text(evaluation.dimensions.first.explanation)
              .first;
          expect(
            tester.getTopLeft(explanation).dy,
            greaterThan(tester.getTopLeft(title).dy),
          );
          expect(find.text('▶'), findsWidgets);
          if (!comparison) {
            final state = find.text('대체로 충실').first;
            final stars = find.text('★★★★☆').first;
            expect(
              tester.getTopLeft(state).dx,
              lessThan(tester.getTopLeft(stars).dx),
            );
            if (width > 600 && scale == 1) {
              expect(
                tester.getTopLeft(state).dy,
                closeTo(tester.getTopLeft(title).dy, 1),
              );
              expect(
                tester.getTopLeft(state).dx - tester.getTopRight(title).dx,
                closeTo(10, 1),
              );
            } else {
              expect(
                tester.getTopLeft(state).dy,
                greaterThan(tester.getTopLeft(title).dy),
              );
            }
          }
          if (scale == 1) {
            await preview.capture(
              tester,
              'essay-${comparison ? 'comparison' : 'result'}-${width == 360 ? 'mobile' : 'desktop'}-final',
            );
          }
          expect(tester.takeException(), isNull);
          await close(tester);
        });
      }
    }
  }
  testWidgets(
    'problem-only source provenance and unknown time do not imply eligibility',
    (tester) async {
      size(tester, const Size(360, 800));
      await show(
        tester,
        EssayWorkspacePage(question: essayPreviewQuestions[1]),
      );
      expect(find.text('실전 모드로'), findsNothing);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, '제출하고 첨삭 화면 살펴보기'),
      );
      expect(button.onPressed, isNull);
      await tester.tap(find.text('문제'));
      await tester.pumpAndSettle();
      expect(find.text('대학 공식 모의논술 자료 기반 · 표시 예시'), findsOneWidget);
      expect(find.text('시험시간 미확인'), findsOneWidget);
      await close(tester);
    },
  );
}
