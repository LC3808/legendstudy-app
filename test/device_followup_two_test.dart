import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/study/trends/study_bar_chart.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_repository.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';
import 'package:legendstudy_app/features/study/presentation/mock_exam_panel.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';

import 'mock_scoring_test.dart' show availability, FakeScoring;
import 'mock_exam_test.dart' show TestAlerts;
import 'study_core_test.dart' show TestClock, TestStore, TestRepo;
import 'study_repository_test.dart' show config;

class Papers extends FakeScoring {
  Papers() : super(null);
  bool unavailable = false;
  final prepared = <String>[];
  @override
  Future<List<ScoringPaper>> availablePapers() async {
    if (unavailable) throw const ScoringFailure();
    return [
      for (final item in [('exam-a', '국어'), ('exam-a', '영어'), ('exam-b', '수학')])
        ScoringPaper(
          MockScoringAvailability.fromJson({
            ...availability().toJson(),
            'exam_subject_id': '${item.$1}-${item.$2}',
          }),
          item.$1 == 'exam-a' ? '2026학년도 모의고사' : '다른 시험',
          examId: item.$1,
          subjectLabel: item.$2,
          year: 2026,
          grade: 3,
          month: item.$1 == 'exam-a' ? 6 : 9,
          subjectCode: {'국어': 'korean', '영어': 'english', '수학': 'math'}[item.$2],
        ),
    ];
  }

  @override
  Future<AnswerDraft> prepare(MockScoringAvailability a) async {
    prepared.add(a.examSubjectId);
    return AnswerDraft(a, const [
      AnswerEntryQuestion(1, 2),
      AnswerEntryQuestion(2, 2),
      AnswerEntryQuestion(3, 2),
    ]);
  }
}

void main() {
  final cases = <List<int>>[
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 60000],
    [0, 60000, 0, 180000, 0, 60000, 0],
    [60000, 60000, 60000, 60000, 60000, 60000, 60000],
    [0, 3600000, 0, 7200000, 1800000, 0, 10800000],
  ];
  for (final size in [const Size(360, 640), const Size(428, 926)]) {
    for (final scale in [1.0, 2.0]) {
      for (var c = 0; c < cases.length; c++) {
        testWidgets('daily values average geometry $size $scale case$c', (
          t,
        ) async {
          t.view.physicalSize = size;
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
          final totals = cases[c];
          await t.pumpWidget(
            MaterialApp(
              theme: AppTheme.light,
              home: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: StudyBarChart(
                      labels: const ['목', '금', '토', '일', '월', '화', '수'],
                      totals: totals,
                      dailyDetails: true,
                    ),
                  ),
                ),
              ),
            ),
          );
          final max = studyChartCeiling(totals),
              avg = totals.reduce((a, b) => a + b) / 7;
          expect(studyChartAverage(totals), avg);
          final painter =
              t
                      .widget<CustomPaint>(
                        find.byKey(const Key('study-average-line')),
                      )
                      .painter!
                  as StudyAverageLine;
          expect(painter.ratio, max == 0 ? 0 : avg / max);
          for (var i = 0; i < 7; i++) {
            expect(
              t.widget<Text>(find.byKey(ValueKey('study-value-$i'))).data,
              studyBarDuration(totals[i]),
            );
            expect(
              t.getSize(find.byKey(ValueKey('study-bar-$i'))).height,
              closeTo(max == 0 ? 0 : 160 * totals[i] / max, .001),
            );
            if (i > 0) {
              expect(
                t.getTopLeft(find.byKey(ValueKey('study-bar-$i'))).dx,
                greaterThan(
                  t.getTopLeft(find.byKey(ValueKey('study-bar-${i - 1}'))).dx,
                ),
              );
            }
          }
          expect(t.takeException(), isNull);
        });
      }
    }
  }
  test(
    'catalogue joins exam subject metadata and fails closed when absent',
    () async {
      for (final missing in [false, true]) {
        final repo = SupabaseScoringRepository(
          config,
          MockClient((request) async {
            if (request.url.path.endsWith('mock_exam_scoring_availability')) {
              expect(
                request.url.queryParameters['availability'],
                'eq.scoring_available',
              );
              return http.Response(jsonEncode([availability().toJson()]), 200);
            }
            expect(
              request.url.queryParameters['select'],
              contains('subjects(name,code,category)'),
            );
            return http.Response(
              jsonEncode(
                missing
                    ? []
                    : [
                        {
                          'id': 'occurrence',
                          'content_item_id': 'exam-a',
                          'raw_subject_label': 'raw',
                          'subjects': {'name': '국어'},
                          'exams': {
                            'exam_type': 'evaluation_mock',
                            'year': 2026,
                            'grade_level': 3,
                            'exam_month': 6,
                            'content_items': {'title': '실제 시험'},
                          },
                        },
                      ],
              ),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );
        if (missing) {
          await expectLater(
            repo.availablePapers(),
            throwsA(isA<ScoringFailure>()),
          );
        } else {
          final row = (await repo.availablePapers()).single;
          expect(row.examIdentity, 'exam-a');
          expect(row.subjectLabel, '국어');
          expect(row.title, '실제 시험');
        }
      }
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets('exam context filters subjects and pins key $scale', (t) async {
      t.view.physicalSize = const Size(360, 640);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final papers = Papers()..unavailable = true,
          c = StudyController(
            TestClock(),
            TestStore(),
            () => TestRepo('A'),
            ticking: false,
            scoringRepository: () => papers,
          );
      addTearDown(c.dispose);
      c.identity(null, resolved: true);
      await c.settled;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SingleChildScrollView(
              child: MockExamPanel(
                study: c,
                start: c.startMock,
                notifications: TestAlerts(),
                startBusy: false,
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      Future<void> tap(Finder f) async {
        await t.ensureVisible(f);
        await t.tap(f);
        await t.pumpAndSettle();
      }

      expect(find.text('시험 목록 새로고침'), findsNothing);
      await tap(find.text('공식 기출'));
      expect(find.text('다시 시도'), findsOneWidget);
      papers.unavailable = false;
      await tap(find.text('다시 시도'));
      expect(find.text('다시 시도'), findsNothing);
      await tap(find.byKey(const ValueKey('official-year-null')));
      await tap(find.text('2026년').last);
      await tap(find.byKey(const ValueKey('official-grade-null')));
      await tap(find.text('고3').last);
      await tap(find.byKey(const ValueKey('official-month-null')));
      await tap(find.text('6월').last);
      expect(find.byKey(const Key('mock-title')), findsNothing);
      expect(find.text('수학'), findsNothing);
      await tap(find.text('영어').last);
      expect(c.mockSetup!.title, '2026학년도 모의고사');
      expect(c.mockSetup!.subject, '영어');
      expect(papers.prepared.single, 'exam-a-영어');
      await tap(find.byKey(const Key('mock-duration')));
      await tap(find.text('수학 100분').last);
      expect(c.mockSetup!.subject, '영어');
      await tap(find.text('시험 시작'));
      expect(c.draft!.answers!.availability.examSubjectId, 'exam-a-영어');
      expect(t.takeException(), isNull);
    });
  }
}
