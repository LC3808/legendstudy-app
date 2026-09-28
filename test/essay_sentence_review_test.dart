import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/essay_sentence_review.dart';
import 'package:legendstudy_app/features/essay/essay_pages.dart';
import 'package:legendstudy_app/features/essay/essay_preview.dart';

import 'core_ux_test.dart' as preview;

const answer = '😀 자료는 증가했다. 그러므로 자료는 감소했다.';
EssaySentenceItem item({
  String id = 'x',
  int start = 12,
  int end = 26,
  String quote = '그러므로 자료는 감소했다.',
  EssaySentencePriority priority = EssaySentencePriority.contradiction,
  String? example,
}) => EssaySentenceItem(
  id: id,
  category: EssaySentenceCategory.logic,
  priority: priority,
  start: start,
  end: end,
  quote: quote,
  diagnosis: '앞 문장의 증가와 이 문장의 감소가 어떻게 이어지는지 설명이 필요해요.',
  direction: '서로 다른 자료를 뜻하는지 확인하고 연결 근거를 밝혀 보세요.',
  example: example,
);
EssaySentenceReview review(List<EssaySentenceItem> items) =>
    EssaySentenceReview(
      evaluationId: 'evaluation-a',
      attemptId: 'attempt-a',
      items: items,
    );

void main() {
  test('exact code point quote and ownership; fabricated or normalized quote denied', () {
    final start = answer.runes.toList().indexOf('그'.runes.single);
    final good = item(start: start, end: answer.runes.length);
    expect(review([good]).verified('evaluation-a', 'attempt-a', answer), [
      good,
    ]);
    expect(
      review([good]).verified('evaluation-b', 'attempt-a', answer),
      isEmpty,
    );
    expect(
      review([good]).verified('evaluation-a', 'attempt-b', answer),
      isEmpty,
    );
    expect(
      review([good]).verified('evaluation-a', 'attempt-a', '새 draft'),
      isEmpty,
    );
    expect(
      review([item(quote: '학생이 쓰지 않은 문장')])
          .verified('evaluation-a', 'attempt-a', answer),
      isEmpty,
    );
    expect(
      review([item(start: -1)]).verified('evaluation-a', 'attempt-a', answer),
      isEmpty,
    );
    expect(review([]).verified('evaluation-a', 'attempt-a', answer), isEmpty);
    expect(
      review([good, good]).verified('evaluation-a', 'attempt-a', answer),
      hasLength(1),
    );
  });
  test('maximum five, impact order, zero is valid', () {
    const body = '가나다라마바사';
    final items = List.generate(
      7,
      (i) => item(
        id: '$i',
        start: i,
        end: i + 1,
        quote: body[i],
        priority: i == 6
            ? EssaySentencePriority.contradiction
            : EssaySentencePriority.wording,
      ),
    );
    final selected = review(items).verified('evaluation-a', 'attempt-a', body);
    expect(selected, hasLength(5));
    expect(selected.first.id, '6');
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'sentence section collapses, exact quote and optional example $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final good = item(start: 12, end: answer.runes.length);
        await tester.pumpWidget(
          preview.app(
            Scaffold(
              body: SingleChildScrollView(
                child: EssaySentenceSection(
                  review: review([good]),
                  evaluationId: 'evaluation-a',
                  attemptId: 'attempt-a',
                  submittedAnswer: answer,
                ),
              ),
            ),
            scale: scale,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('문장 다듬기 · 1개'), findsOneWidget);
        expect(find.text('원문'), findsNothing);
        await tester.tap(find.byType(ExpansionTile));
        await tester.pumpAndSettle();
        expect(find.text('원문'), findsOneWidget);
        expect(find.text('수정 방향'), findsOneWidget);
        expect(find.text('수정 예시'), findsNothing);
        expect(find.text(good.quote), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('unavailable is not no-errors; placement before improvements', (
    tester,
  ) async {
    await tester.pumpWidget(
      preview.app(
        EssayResultView(
          evaluation: firstPreviewEvaluation,
          question: essayPreviewQuestions.first,
          comparison: false,
          onRewrite: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('문장별 진단이 아직 제공되지 않았어요.'), findsOneWidget);
    final section = find.byType(EssaySentenceSection);
    expect(
      tester.getTopLeft(section).dy,
      greaterThan(tester.getTopLeft(find.text('평가 항목별 진단')).dy),
    );
    expect(
      tester.getTopLeft(section).dy,
      lessThan(tester.getTopLeft(find.text('보완할 점').last).dy),
    );
  });
}
