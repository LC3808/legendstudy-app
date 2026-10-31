import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legendstudy_app/features/feedback/essay_feedback.dart';

void main() {
  test('only canonical references, no answer content', () {
    expect(essayFeedbackReference('student answer'), isNull);
    expect(
      essayFeedbackReference(
        '00000000-0000-4000-8000-000000000001/00000000-0000-4000-8000-000000000002',
      ),
      isNotNull,
    );
  });
  testWidgets(
    'satisfaction alone, retry keeps request key and no answer payload',
    (t) async {
      final calls = <Map<String, dynamic>>[];
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: EssayFeedbackForm(
                submit: (p) async {
                  calls.add(Map.of(p));
                  if (calls.length == 1) throw Exception();
                },
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('도움이 되었어요'));
      await t.pump();
      await t.ensureVisible(find.text('제출하기'));
      await t.tap(find.text('제출하기'));
      await t.pumpAndSettle();
      expect(calls.single['message'], '');
      expect(calls.single.containsKey('answer'), false);
      await t.tap(find.text('제출하기'));
      await t.pumpAndSettle();
      expect(calls[0]['request_key'], calls[1]['request_key']);
      expect(find.text(feedbackThanks), findsOneWidget);
    },
  );
  testWidgets('bug requires category and description', (t) async {
    int calls = 0;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: EssayFeedbackForm(
              bugOnly: true,
              submit: (_) async {
                calls++;
              },
            ),
          ),
        ),
      ),
    );
    await t.ensureVisible(find.text('제출하기'));
    await t.tap(find.text('제출하기'));
    await t.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('오류 유형과 설명을 입력해 주세요.'), findsOneWidget);
  });
}
