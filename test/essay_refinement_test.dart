import 'dart:io';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/essay/essay_pages.dart';
import 'package:legendstudy_app/features/essay/essay_preview.dart';
import 'package:legendstudy_app/features/essay/evaluation_report.dart';
import 'package:legendstudy_app/features/essay/growth_bars.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/essay_growth_page.dart';
import 'package:legendstudy_app/features/essay/result_disclosure.dart';
import 'package:legendstudy_app/features/essay/shared_history.dart';
import 'package:legendstudy_app/features/essay/shared_history_page.dart';

SharedEssayRecord row(int n, {int round = 1, bool truncated = false}) =>
    SharedEssayRecord(
      id: 'run-$n',
      math: false,
      exam: true,
      at: DateTime.utc(2026, 10, 29).subtract(Duration(days: n)),
      rewrite: false,
      examData: {
        'exam_id': 'exam-$n',
        'university': '대학$n',
        'displayExam': '2026학년도 수시논술 · 인문 · T2 · 오후 1교시',
        'state': 'completed',
        'learning_round': round,
        '_historyTruncated': truncated,
        'questions': [
          {'dbQuestionId': 'z', 'label': '문제 1'},
          {'dbQuestionId': 'a', 'label': '문제 2'},
        ],
      },
      evaluations: const [
        {'id': 'run/a', 'state': 'COMPLETED'},
        {'id': 'run/z', 'state': 'COMPLETED'},
      ],
    );
Widget app(
  List<SharedEssayRecord> rows, {
  Widget page = const EssayGrowthPage(),
  double scale = 1,
}) => ProviderScope(
  overrides: [
    authStateProvider.overrideWith(
      (ref) => Stream.value(const AuthStatus('owner')),
    ),
    supabaseClientProvider.overrideWithValue(null),
    sharedEssayHistoryProvider('owner').overrideWith((ref) async => rows),
  ],
  child: MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(scale)),
      child: page,
    ),
  ),
);
List<Key> cardKeys(WidgetTester tester) =>
    (tester.widget<ListView>(find.byType(ListView)).childrenDelegate
            as SliverChildListDelegate)
        .children
        .map((w) => w.key)
        .whereType<ValueKey<String>>()
        .where((k) => k.value.startsWith('run-'))
        .toList();

void main() {
  testWidgets('Native result and chart presentation at phone widths', (
    tester,
  ) async {
    final render = Platform.environment['REFINEMENT_RENDER'] == 'true';
    if (render) {
      await tester.runAsync(() async {
        await (FontLoader('QAFont')..addFont(
              File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                  .readAsBytes()
                  .then(ByteData.sublistView),
            ))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      });
    }
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Future<void> capture(String name) async {
      if (!render) return;
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('/private/tmp/legendstudy-refinement-$name.png')
            .writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
    }

    Widget frame(Widget child) => MaterialApp(
      theme: AppTheme.light.copyWith(
        chipTheme: AppTheme.light.chipTheme.copyWith(
          labelStyle: TextStyle(
            fontFamily: render ? 'QAFont' : null,
            fontSize: 14,
            color: AppTokens.textPrimary,
          ),
        ),
        textTheme: AppTheme.light.textTheme.apply(
          fontFamily: render ? 'QAFont' : null,
        ),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text('첨삭 결과')),
        body: RepaintBoundary(
          key: const ValueKey('capture'),
          child: Material(color: AppTokens.background, child: child),
        ),
      ),
    );
    await tester.pumpWidget(
      frame(
        EssayResultView(
          evaluation: secondPreviewEvaluation,
          onRewrite: null,
          question: essayPreviewQuestions.first,
          comparison: true,
          isPreview: false,
          collapsedDetails: true,
          header: EssayResultHeader(record: row(0, round: 2), questionId: 'z'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('AI 재첨삭 평가 설명 보기'), findsNothing);
    expect(find.text('성장 기록 공유'), findsNothing);
    await capture('result');
    final fixture = jsonDecode(
      File('test/fixtures/exam-history-v1.json').readAsStringSync(),
    ) as Map;
    final before = examEvaluationReport(
      Map<String, dynamic>.from(fixture['before'] as Map),
      'question',
    );
    final after = examEvaluationReport(
      Map<String, dynamic>.from(fixture['after'] as Map),
      'question',
    );
    await tester.pumpWidget(
      frame(
        SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: GrowthBars(
            before: before,
            after: after,
            beforeLabel: '최초 첨삭',
            afterLabel: '무료 재첨삭',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('평가 단계 2 → 3'), findsOneWidget);
    await capture('chart');
    expect(tester.takeException(), isNull);
  });

  test('paid followups use learning rounds; official question order does not sort UUIDs', () {
    expect(essayIsFollowup(row(0, round: 3)), isTrue);
    expect(essayIsFollowup(row(0)), isFalse);
    expect(orderedEssayEvaluations(row(0)).map((e) => e['id']), [
      'run/z',
      'run/a',
    ]);
    expect(
      row(0).evaluations.first['id'],
      'run/a',
    ); // Original remains unchanged.
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'one body on collapse and expansion, preserving repeated source ($scale)',
      (tester) async {
        const text = '원문 첫 문장.\n원문 첫 문장.\n세 번째 문장.\n네 번째 문장.\n다섯 번째 문장.';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const SizedBox(
                  width: 320,
                  child: ResultTextDisclosure(text: text),
                ),
              ),
            ),
          ),
        );
        expect(find.text(text), findsOneWidget);
        expect(tester.widget<Text>(find.text(text)).maxLines, 3);
        await tester.tap(find.byType(ResultTextDisclosure));
        await tester.pumpAndSettle();
        expect(find.text(text), findsOneWidget);
        expect(tester.widget<Text>(find.text(text)).maxLines, isNull);
        expect(tester.widget<Text>(find.text(text)).textAlign, TextAlign.left);
        await tester.tap(find.byType(ResultTextDisclosure));
        await tester.pumpAndSettle();
        expect(tester.widget<Text>(find.text(text)).maxLines, 3);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets('compact result metadata at narrow width and scale $scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: SizedBox(
                width: 320,
                child: EssayResultHeader(
                  record: row(0, round: 2),
                  questionId: 'a',
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('대학0'), findsOneWidget);
      expect(find.textContaining('T2 · 오후 1교시'), findsOneWidget);
      expect(find.text('문제 2'), findsOneWidget);
      expect(find.text('2차 첨삭'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  for (final count in [0, 1, 5, 6, 10, 11]) {
    testWidgets('growth exact pages for $count exams', (tester) async {
      await tester.pumpWidget(app([for (var i = 0; i < count; i++) row(i)]));
      await tester.pumpAndSettle();
      expect(cardKeys(tester).length, count.clamp(0, 5));
      if (count <= 5) {
        expect(find.byKey(const ValueKey('growth-next')), findsNothing);
      } else {
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('growth-next')),
          300,
        );
        expect(
          tester
              .widget<OutlinedButton>(
                find.byKey(const ValueKey('growth-previous')),
              )
              .onPressed,
          isNull,
        );
        await tester.tap(find.byKey(const ValueKey('growth-next')));
        await tester.pumpAndSettle();
        expect(cardKeys(tester).first, const ValueKey('run-5'));
        expect(cardKeys(tester).length, (count - 5).clamp(0, 5));
        final list = tester.widget<ListView>(find.byType(ListView));
        expect(list.controller!.offset, 0);
        expect(find.textContaining('회차별 결과 보기'), findsOneWidget);
        if (count > 10) {
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('growth-next')),
            300,
          );
          await tester.tap(find.byKey(const ValueKey('growth-next')));
          await tester.pumpAndSettle();
          expect(cardKeys(tester), [const ValueKey('run-10')]);
        }
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('growth-next')),
          300,
        );
        expect(
          tester
              .widget<OutlinedButton>(find.byKey(const ValueKey('growth-next')))
              .onPressed,
          isNull,
        );
        await tester.tap(find.byKey(const ValueKey('growth-previous')));
        await tester.pumpAndSettle();
        expect(cardKeys(tester).length, 5);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
    'only one growth card opens; incomplete history never invents total pages',
    (tester) async {
      await tester.pumpWidget(
        app([for (var i = 0; i < 6; i++) row(i, truncated: true)]),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('회차별 결과 보기'), findsOneWidget);
      await Scrollable.ensureVisible(
        tester.element(find.text('대학1')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await Scrollable.ensureVisible(
        tester.element(find.text('대학1')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('대학1'));
      await tester.pumpAndSettle();
      expect(find.textContaining('회차별 결과 보기'), findsOneWidget);
      await Scrollable.ensureVisible(
        tester.element(find.text('대학1')),
        alignment: 0.5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('대학1'));
      await tester.pumpAndSettle();
      expect(find.textContaining('회차별 결과 보기'), findsNothing);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('growth-next')),
        300,
      );
      expect(find.text('1 / 2'), findsNothing);
      expect(find.text('1페이지 · 조회 범위'), findsOneWidget);
    },
  );
  testWidgets(
    'history hides search and filters a paid third round as rewrite',
    (tester) async {
      await tester.pumpWidget(
        app([row(0), row(1, round: 3)], page: const SharedEssayHistoryPage()),
      );
      await tester.pumpAndSettle();
      expect(find.text('대학·시험 검색'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('재첨삭').last);
      await tester.pumpAndSettle();
      expect(find.text('대학0'), findsNothing);
      expect(find.text('대학1'), findsOneWidget);
      expect(find.text('3차 첨삭'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
