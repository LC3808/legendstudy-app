import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';
import 'package:legendstudy_app/features/school/presentation/home_meal_card.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'package:legendstudy_app/features/study/trends/study_bar_chart.dart';
import 'package:legendstudy_app/features/study/presentation/mock_exam_panel.dart';
import 'package:legendstudy_app/features/study/presentation/free_practice_results.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_repository.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';

import 'study_core_test.dart' show TestClock, TestStore, TestRepo, flush;
import 'mock_exam_test.dart' show TestAlerts;
import 'mock_scoring_test.dart' show FakeScoring, availability;
import 'design_v2_test.dart' show contrast;

Meal meal(String date, [String type = '중식']) =>
    Meal(date: date, mealType: type, menuItems: ['$date $type 메뉴']);
final thursday = DateTime.utc(2026, 9, 24, 3);

class OfficialPapers extends FakeScoring {
  OfficialPapers() : super(null);
  @override
  Future<List<ScoringPaper>> availablePapers() async => [
    for (final y in [2025, 2026])
      for (final subject in [
        ('korean', '국어', '공통'),
        ('english', '영어', '공통'),
        ('physics_1', '물리학Ⅰ', '과학탐구'),
        ('japanese', '일본어', '제2외국어·한문'),
      ])
        for (final variant
            in subject.$1 == 'korean' ? ['화법과 작문', '언어와 매체'] : ['common'])
          ScoringPaper(
            MockScoringAvailability.fromJson({
              ...availability().toJson(),
              'exam_subject_id': '$y-${subject.$1}',
              'paper_variant': variant,
            }),
            '$y 실제 시험',
            examId: 'exam-$y',
            year: y,
            grade: 3,
            month: 6,
            examType: 'evaluation_mock',
            subjectCode: subject.$1,
            subjectLabel: subject.$2,
            subjectCategory: subject.$3,
            subjectId: subject.$1,
            taxonomyVersion: 'v1',
          ),
  ];
  @override
  Future<AnswerDraft> prepare(MockScoringAvailability a) async =>
      AnswerDraft(a, const [
        AnswerEntryQuestion(1, 2),
        AnswerEntryQuestion(2, 2),
        AnswerEntryQuestion(3, 2),
      ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (!const bool.fromEnvironment('FOLLOWUP3_RENDER')) return;
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('DevicePreview')..addFont(
          File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
  });
  test('brand confirmed, no peach selections, actual contrast', () {
    expect(AppTokens.primary, const Color(0xFFFFA300));
    expect(AppTokens.brand, AppTokens.primary);
    expect(AppTokens.primarySoft, AppTokens.cardBorder);
    expect(
      contrast(AppTokens.primary, AppTokens.textPrimary),
      greaterThan(4.5),
    );
    expect(contrast(AppTokens.primary, Colors.white), lessThan(3));
    expect(AppTheme.light.colorScheme.onPrimary, AppTokens.textPrimary);
  });
  test(
    'provided dates only: prior/next/following skip school closure and weekend',
    () async {
      final calls = <String>[];
      final rows = await mealContextDates(thursday, [], (date) async {
        calls.add(date);
        return ['20260923', '20260928', '20260929'].contains(date)
            ? [meal(date)]
            : [];
      });
      expect(rows.map((m) => m.date), ['20260923', '20260928', '20260929']);
      expect(calls, isNot(contains('20260924')));
      expect(calls.toSet().length, calls.length);
    },
  );
  test('today + two provided dates; no past requests', () async {
    final calls = <String>[];
    final rows = await mealContextDates(thursday, [meal('20260924')], (
      date,
    ) async {
      calls.add(date);
      return [meal(date)];
    });
    expect(rows.map((m) => m.date), ['20260924', '20260925', '20260926']);
    expect(calls, ['20260925', '20260926']);
  });
  test(
    'bounded context includes last allowed future date, none beyond',
    () async {
      final calls = <String>[];
      final rows = await mealContextDates(thursday, [], (date) async {
        calls.add(date);
        return date == '20261001' ? [meal(date, '조식')] : [];
      });
      expect(rows.single.date, '20261001');
      expect(calls.length, 14);
      expect(calls, isNot(contains('20261002')));
      expect(await mealContextDates(thursday, [], (_) async => []), isEmpty);
    },
  );
  test(
    'context transport error is not silently treated as missing meal',
    () async {
      await expectLater(
        mealContextDates(
          thursday,
          [],
          (_) async => throw StateError('offline'),
        ),
        throwsStateError,
      );
    },
  );
  for (final include in [true, false]) {
    test(
      'free result durable/manual/owner isolated/inclusion=$include',
      () async {
        final clock = TestClock(), store = TestStore(), repo = TestRepo('A');
        final c = StudyController(clock, store, () => repo, ticking: false);
        c.identity('A', resolved: true);
        await flush(c);
        c.configureMock(
          MockSetup('EBS 연습', null, 60, includeInStudyTotal: include),
        );
        await c.startMock();
        expect(c.draft!.answers, isNull);
        clock.advance(30000);
        await c.end();
        await flush(c);
        final id = c.lastMock!.id;
        expect(c.freePractices.length, 1);
        expect(c.attempts, isEmpty);
        expect(c.week.last, include ? 30000 : 0);
        expect(await c.savePracticeScore(id, 81.5), true);
        expect(c.freePractices.single['manual_score'], 81.5);
        expect(repo.rows.single.payload().containsKey('manual_score'), false);
        store.fail = true;
        expect(await c.savePracticeScore(id, 90), false);
        expect(c.freePractices.single['manual_score'], 81.5);
        store.fail = false;
        expect(await c.savePracticeScore(id, double.nan), false);
        c.dispose();
        final restored = StudyController(
          clock,
          store,
          () => repo,
          ticking: false,
        );
        addTearDown(restored.dispose);
        restored.identity('A', resolved: true);
        await flush(restored);
        expect(restored.freePractices.single['manual_score'], 81.5);
        expect(restored.attempts, isEmpty);
        restored.identity('B', resolved: true);
        await flush(restored);
        expect(restored.freePractices, isEmpty);
        expect(await restored.savePracticeScore(id, 1), false);
      },
    );
  }
  test('pending score save cannot surface in switched owner', () async {
    final clock = TestClock(), store = TestStore(), repo = TestRepo('A');
    final c = StudyController(clock, store, () => repo, ticking: false);
    addTearDown(c.dispose);
    c.identity('A', resolved: true);
    await flush(c);
    c.configureMock(const MockSetup('연습', null, 60));
    await c.startMock();
    clock.advance(2000);
    await c.end();
    await flush(c);
    store.holdWrite = Completer<void>();
    final save = c.savePracticeScore(c.lastMock!.id, 77);
    await Future<void>.delayed(Duration.zero);
    c.identity('B', resolved: true);
    store.holdWrite!.complete();
    expect(await save, false);
    await flush(c);
    expect(c.freePractices, isEmpty);
  });
  for (final size in [const Size(360, 640), const Size(428, 926)]) {
    for (final scale in [1.0, 2.0]) {
      Future<void> setup(WidgetTester t, Widget child) async {
        t.view.physicalSize = size;
        t.view.devicePixelRatio = 1;
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await t.pumpWidget(
          MaterialApp(
            theme: const bool.fromEnvironment('FOLLOWUP3_RENDER')
                ? AppTheme.light.copyWith(
                    chipTheme: AppTheme.light.chipTheme.copyWith(
                      labelStyle: AppTokens.secondary.copyWith(
                        fontFamily: 'DevicePreview',
                      ),
                    ),
                    textTheme: AppTheme.light.textTheme.apply(
                      fontFamily: 'DevicePreview',
                    ),
                  )
                : AppTheme.light,
            home: Scaffold(
              body: RepaintBoundary(
                key: const Key('capture'),
                child: Material(
                  color: AppTokens.background,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
      }

      Future<void> capture(WidgetTester t, String label) async {
        if (!const bool.fromEnvironment('FOLLOWUP3_RENDER')) return;
        await t.runAsync(() async {
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const Key('capture')),
          );
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          final f = File(
            '/private/tmp/legendstudy-followup3/$label-${size.width}-$scale.png',
          );
          await f.parent.create(recursive: true);
          await f.writeAsBytes(data!.buffer.asUint8List());
        });
      }

      testWidgets('meal actual chips and trailing toggle $size/$scale', (
        t,
      ) async {
        await setup(
          t,
          MealSummary(
            now: thursday,
            meals: const [],
            schoolName: '긴 학교명이 표시되는 고등학교',
            tomorrowMeals: [meal('20260928')],
            loadDates: () async => [
              meal('20260923'),
              meal('20260928'),
              meal('20260929', '조식'),
            ],
          ),
        );
        await capture(t, 'meal-collapsed');
        final button = find.byKey(const Key('meal-expand'));
        expect(
          t.getTopLeft(button).dy,
          greaterThan(t.getBottomLeft(find.text('긴 학교명이 표시되는 고등학교')).dy),
        );
        await t.tap(button);
        await t.pumpAndSettle();
        final chips = t
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .toList();
        expect(chips.map((c) => (c.label as Text).data), [
          '9월 23일(수)',
          '9월 28일(월)',
          '9월 29일(화)',
        ]);
        expect(chips.map((c) => c.selected), [false, true, false]);
        expect(find.text('9월 24일(목)'), findsNothing);
        await capture(t, 'meal-expanded');
        await t.tap(find.text('9월 23일(수)'));
        await t.pumpAndSettle();
        expect(find.text('지난 급식'), findsOneWidget);
        expect(find.text('20260923 중식 메뉴'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
      testWidgets(
        'official progressive subject grouping/reset/free separation $size/$scale',
        (t) async {
          final c = StudyController(
            TestClock(),
            TestStore(),
            () => TestRepo('A'),
            ticking: false,
            scoringRepository: () => OfficialPapers(),
          );
          addTearDown(c.dispose);
          c.identity(null, resolved: true);
          await c.settled;
          await setup(
            t,
            MockExamPanel(
              study: c,
              start: c.startMock,
              notifications: TestAlerts(),
              startBusy: false,
            ),
          );
          Future<void> tap(Finder f) async {
            await t.ensureVisible(f);
            await t.tap(f);
            await t.pumpAndSettle();
          }

          await capture(t, 'free');
          await tap(find.text('공식 기출'));
          await capture(t, 'official-year');
          expect(find.byKey(const Key('mock-title')), findsNothing);
          await tap(find.byKey(const ValueKey('official-year-null')));
          await tap(find.text('2026년').last);
          await tap(find.byKey(const ValueKey('official-grade-null')));
          await tap(find.text('고3').last);
          await tap(find.byKey(const ValueKey('official-month-null')));
          await tap(find.text('6월').last);
          expect(find.text('2026 실제 시험'), findsOneWidget);
          await tap(find.widgetWithText(ChoiceChip, '국어'));
          expect(c.scoringSetup, isNull);
          await capture(t, 'official-subject');
          await tap(
            find.byKey(const ValueKey('official-subject-exam-2026-국어-null')),
          );
          await tap(find.text('국어 · 언어와 매체').last);
          expect(c.scoringSetup!.availability.paperVariant, '언어와 매체');
          await tap(find.widgetWithText(ChoiceChip, '영어'));
          expect(c.scoringSetup!.availability.examSubjectId, '2026-english');
          expect(find.text('세부 과목 · 선택과목'), findsNothing);
          await tap(find.widgetWithText(ChoiceChip, '기타'));
          expect(find.text('일본어 · common'), findsOneWidget);
          expect(c.scoringSetup!.availability.examSubjectId, '2026-japanese');
          await tap(find.byKey(const ValueKey('official-year-2026')));
          await tap(find.text('2025년').last);
          expect(c.scoringSetup, isNull);
          expect(find.text('2026 실제 시험'), findsNothing);
          expect(
            find.byKey(const ValueKey('official-grade-null')),
            findsOneWidget,
          );
          await tap(find.text('자유 연습'));
          expect(find.byKey(const Key('mock-title')), findsOneWidget);
          expect(find.text('연도'), findsNothing);
          expect(c.scoringSetup, isNull);
          await t.enterText(
            find.byKey(const Key('mock-title')),
            'EBS FINAL 3회',
          );
          await tap(find.text('연습 시작'));
          expect(c.draft!.mock!.title, 'EBS FINAL 3회');
          expect(c.draft!.answers, isNull);
          expect(t.takeException(), isNull);
        },
      );
      for (final totals in [
        [0, 0, 0, 0, 0, 0, 0],
        [0, 0, 0, 0, 0, 0, 60000],
        [60000, 60000, 60000, 60000, 60000, 60000, 60000],
        [0, 1800000, 3600000, 0, 7200000, 0, 10800000],
      ]) {
        testWidgets(
          'mean annotation outside bars $size/$scale/${totals.last}',
          (t) async {
            await setup(
              t,
              StudyBarChart(
                labels: const ['목', '금', '토', '일', '월', '화', '수'],
                totals: totals,
                dailyDetails: true,
              ),
            );
            expect(find.text('이번 주'), findsOneWidget);
            final label = t.getRect(
              find.byKey(const Key('study-average-label')),
            );
            for (var i = 0; i < 7; i++) {
              final bar = t.getRect(find.byKey(ValueKey('study-bar-$i')));
              expect(label.right, lessThanOrEqualTo(bar.left));
              expect(
                bar.height,
                closeTo(
                  studyBarHeight(totals[i], studyChartCeiling(totals)),
                  .001,
                ),
              );
            }
            final line = t.getRect(find.byKey(const Key('study-average-line')));
            final ratio = studyChartCeiling(totals) == 0
                ? 0
                : studyChartAverage(totals) / studyChartCeiling(totals);
            expect(
              label.bottom,
              lessThanOrEqualTo(line.top + 160 * (1 - ratio)),
            );
            await capture(t, 'chart-${totals.last}');
            expect(t.takeException(), isNull);
          },
        );
      }
    }
  }
  testWidgets(
    'past-only context selects actual date, never creates empty today',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealSummary(
              now: thursday,
              meals: const [],
              loadDates: () async => [meal('20260923')],
            ),
          ),
        ),
      );
      await t.tap(find.byKey(const Key('meal-expand')));
      await t.pumpAndSettle();
      expect(find.text('지난 급식'), findsOneWidget);
      expect(t.widget<ChoiceChip>(find.byType(ChoiceChip)).selected, true);
      expect(find.text('20260923 중식 메뉴'), findsOneWidget);
      await t.tap(find.byKey(const Key('meal-expand')));
      await t.pumpAndSettle();
      expect(find.text('예정된 급식이 없어요.'), findsOneWidget);
      await t.tap(find.byKey(const Key('meal-expand')));
      await t.pumpAndSettle();
      expect(find.text('지난 급식'), findsOneWidget);
    },
  );
  testWidgets('manual score dialog writes real practice once', (t) async {
    final clock = TestClock(),
        c = StudyController(
          clock,
          TestStore(),
          () => TestRepo('A'),
          ticking: false,
        );
    addTearDown(c.dispose);
    c.identity(null, resolved: true);
    await c.settled;
    c.configureMock(const MockSetup('자유연습', null, 60));
    await c.startMock();
    clock.advance(3000);
    await c.end();
    await c.settled;
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FreePracticeResults(study: c)),
      ),
    );
    await t.tap(find.text('자유 연습 기록'));
    await t.pumpAndSettle();
    await t.tap(find.text('자유연습'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), '77.5');
    await t.tap(find.text('저장'));
    await t.pumpAndSettle();
    expect(c.freePractices.single['manual_score'], 77.5);
    expect(c.attempts, isEmpty);
    await t.pump(const Duration(milliseconds: 400));
  });
}
