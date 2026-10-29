import 'package:legendstudy_app/features/essay/exam_submission.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';

void main() {
  for (final (track, selected, mathPublished) in [
    ('사회·상경', {'text', 'math'}, true),
    ('통합', {'text', 'math'}, true),
    ('사회·상경', {'math'}, false),
  ]) {
    testWidgets(
      'mixed review preserves choices without unsafe submission: $track $selected',
      (t) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
              SourceDraftGateway.channel,
              (_) async => null,
            );
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(SourceDraftGateway.channel, null),
        );
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              examAvailabilityProvider((owner: 'owner', examId: 'exam'))
                  .overrideWith(
                    (ref) async => {
                      'ready': true,
                      'questionIds': ['text-q', 'math-q'],
                      'mathQuestions': {'math-q': 'approved-leaf'},
                    },
                  ),
              mathCatalogProvider('owner').overrideWith(
                (ref) async => mathPublished
                    ? [
                        {
                          'essay_exam_id': 'exam',
                          'essay_question_id': 'math-q',
                          'leaf_id': 'approved-leaf',
                        },
                      ]
                    : [],
              ),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ExamAnswerReview(
                  owner: 'owner',
                  currentQuestion: 'text',
                  selectedQuestions: selected,
                  exam: {
                    'key': 'exam',
                    'dbExamId': 'exam',
                    'universityName': '시험대학교',
                    'year': 2026,
                    'kind': 'admission',
                    'track': track,
                    'session': '2026학년도 시험대학교 수시논술 사회·상경',
                    'questions': [
                      {
                        'key': 'text',
                        'dbQuestionId': 'text-q',
                        'label': '문제 1',
                        'inputMode': 'text',
                      },
                      {
                        'key': 'math',
                        'dbQuestionId': 'math-q',
                        'label': '문제 2',
                        'inputMode': 'image',
                      },
                    ],
                  },
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(
          find.textContaining(
            !mathPublished
                ? '현재 이 수리 문항은 첨삭을 이용할 수 없어요'
                : track == '통합'
                ? '시험 정보를 확인하기 전에는 이 수리 문항을 제출할 수 없어요'
                : '글쓰기 문항과 수리 문항을 함께 제출하는 기능을 준비 중이에요',
          ),
          findsOneWidget,
        );
        expect(find.byType(CheckboxListTile), findsNWidgets(2));
        expect(
          t
                  .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
                  .where((w) => w.value == true)
                  .length ==
              selected.length,
          isTrue,
        );
        expect(find.textContaining('첨삭 요청 ·'), findsNothing);
        expect(find.text('시험대학교'), findsOneWidget);
        expect(find.text('2026학년도 수시논술 사회·상경'), findsOneWidget);
        expect(find.textContaining('TEXT · Essay(TEXT)'), findsNothing);
        expect(find.textContaining('IMAGE · Math'), findsNothing);
        expect(find.text('답안 수정'), findsOneWidget);
        expect(t.takeException(), isNull);
      },
    );
  }
}
