import 'package:legendstudy_app/features/study/trends/study_bar_chart.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';
import 'package:legendstudy_app/features/school/presentation/home_meal_card.dart';
import 'package:legendstudy_app/shared/widgets/shell_widgets.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'package:legendstudy_app/features/study/presentation/study_page.dart';
import 'package:legendstudy_app/features/study/study_providers.dart';

import 'study_core_test.dart' show TestClock, TestStore, TestRepo;

import 'package:legendstudy_app/features/study/focus/focus_service.dart';

import 'study_focus_test.dart' show TestFocusService;
import 'mock_exam_test.dart' show TestAlerts;

const render = bool.fromEnvironment('POLISH_RENDER');
final boundary = GlobalKey();
double previewScale = 1;
Future<void> Function(String)? nativeCapture;
Future<void> capture(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull);
  if (nativeCapture != null) {
    await nativeCapture!(name);
  }
  if (!render) return;
  await tester.runAsync(() async {
    final image =
        await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/polish')..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  test('state text and selected outline meet accessibility contrast', () {
    double contrast(Color a, Color b) {
      final values = [a.computeLuminance(), b.computeLuminance()]..sort();
      return (values.last + .05) / (values.first + .05);
    }

    expect(
      contrast(AppTokens.textPrimary, AppTokens.primary),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppTokens.textPrimary, AppTokens.primarySoft),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppTokens.textPrimary, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
  });
  setUpAll(() async {
    if (render) {
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
      final loader = FontLoader('PolishPreview')
        ..addFont(
          File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
              .readAsBytes()
              .then((b) => ByteData.sublistView(b)),
        );
      await loader.load();
    }
  });
  Widget shell(Widget child) => RepaintBoundary(
    key: boundary,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(previewScale)),
        child: child!,
      ),
      theme: render
          ? AppTheme.light.copyWith(
              textTheme: AppTheme.light.textTheme.apply(
                fontFamily: 'PolishPreview',
              ),
            )
          : AppTheme.light,
      home: Scaffold(body: SafeArea(child: child)),
    ),
  );
  testWidgets('restored custom setup preserves optional blank subject', (
    tester,
  ) async {
    previewScale = 1;
    final c = StudyController(
      TestClock(),
      TestStore(),
      () => TestRepo('A'),
      ticking: false,
    );
    c.identity(null, resolved: true);
    await c.settled;
    c.selectMock(true);
    c.configureMock(const MockSetup('내 시험', null, 600));
    final container = ProviderContainer(
      overrides: [
        studyControllerProvider.overrideWith((ref) => c),
        focusServiceProvider.overrideWithValue(
          TestFocusService()..capability = FocusCapability.unsupported,
        ),
        mockNotificationProvider.overrideWithValue(TestAlerts()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: shell(const StudyPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('mock-subject-')), findsOneWidget);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('mock-minutes')))
          .controller!
          .text,
      '10',
    );
    expect(c.mockSetup!.subject, isNull);
  });
  for (final size in [const Size(360, 640), const Size(428, 926)]) {
    if (nativeCapture != null && size.width != 428) continue;
    for (final scale in [1.0, 2.0]) {
      final tag = '${size.width.toInt()}-${scale.toInt()}x';
      void viewport(WidgetTester tester) {
        previewScale = scale;
        if (nativeCapture != null) return;
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      }

      for (final dinner in [false, true]) {
        testWidgets('meal compact/expand full long menu dinner=$dinner $tag', (
          tester,
        ) async {
          viewport(tester);
          final meals = [
            const Meal(
              date: '20260914',
              mealType: '중식',
              menuItems: [
                '친환경 현미찹쌀밥',
                '한우사골떡만둣국 (밀·계란·쇠고기)',
                '돼지고기김치볶음과 온두부',
                '시금치나물과 배추김치',
                '제철 과일과 수제 요구르트',
              ],
            ),
            if (dinner)
              const Meal(
                date: '20260914',
                mealType: '석식',
                menuItems: ['닭고기채소볶음밥', '해물짬뽕국과 군만두', '마지막 메뉴 · 사과'],
              ),
          ];
          await tester.pumpWidget(
            shell(
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: DailyUtilityCard(
                    wrapHeader: true,
                    title: '레전드스터디국제과학인문융합고등학교',
                    body: MealSummary(
                      meals: meals,
                      now: DateTime.utc(2026, 9, 14, 3),
                    ),
                  ),
                ),
              ),
            ),
          );
          expect(find.text('오늘 급식'), findsOneWidget);
          final preview = tester.widget<Text>(
            find.text('중식 · ${meals.first.menuItems.join(' · ')}'),
          );
          expect(preview.maxLines, 2);
          await capture(tester, 'meal-collapsed-$dinner-$tag');
          await tester.tap(find.byKey(const Key('meal-expand')));
          await tester.pumpAndSettle();
          expect(find.text('중식'), findsOneWidget);
          expect(find.text('석식'), dinner ? findsOneWidget : findsNothing);
          for (final meal in meals) {
            final menu = find.text(meal.menuItems.join('\n'));
            expect(tester.widget<Text>(menu).maxLines, isNull);
          }
          await capture(tester, 'meal-expanded-$dinner-$tag');
          await tester.ensureVisible(
            find.text(meals.last.menuItems.join('\n')),
          );
          await tester.pumpAndSettle();
          await capture(tester, 'meal-bottom-$dinner-$tag');
          await tester.ensureVisible(find.text('오늘 급식'));
          await tester.tap(find.byKey(const Key('meal-expand')));
          await tester.pumpAndSettle();
          expect(find.text('오늘 급식'), findsOneWidget);
        });
      }
      testWidgets(
        'states presets ordering and ascending seven-day chart $tag',
        (tester) async {
          viewport(tester);
          final clock = TestClock();
          final c = StudyController(
            clock,
            TestStore(),
            () => TestRepo('A'),
            ticking: false,
          );
          c.identity(null, resolved: true);
          await c.settled;
          final container = ProviderContainer(
            overrides: [
              studyControllerProvider.overrideWith((ref) => c),
              focusServiceProvider.overrideWithValue(
                TestFocusService()..capability = FocusCapability.unsupported,
              ),
              mockNotificationProvider.overrideWithValue(TestAlerts()),
            ],
          );
          addTearDown(container.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: shell(const StudyPage()),
            ),
          );
          await tester.pumpAndSettle();
          Future<void> press(String label) async {
            final f = find.text(label).last;
            await tester.ensureVisible(f);
            await tester.tap(f);
            await tester.pumpAndSettle();
          }

          final segment = find.widgetWithText(OutlinedButton, '공부 타이머');
          expect(tester.getSize(segment).height, greaterThanOrEqualTo(48));
          final selected = tester
              .widget<OutlinedButton>(segment)
              .style!
              .side!
              .resolve({})!;
          expect(selected.width, 2);
          final chart = tester.widget<StudyBarChart>(
            find.byType(StudyBarChart),
          );
          expect(chart.labels, ['화', '수', '목', '금', '토', '일', '월']);
          expect(chart.descriptions, [
            for (var d = 8; d <= 14; d++) '2026.9.$d',
          ]);
          expect(chart.totals, c.week);
          await press('공부 시작');
          expect(
            find.ancestor(
              of: find.text('일시정지'),
              matching: find.byWidgetPredicate((w) => w is OutlinedButton),
            ),
            findsOneWidget,
          );
          expect(find.byIcon(Icons.pause), findsOneWidget);
          await capture(tester, 'running-$tag');
          await press('일시정지');
          expect(
            find.ancestor(
              of: find.text('계속하기'),
              matching: find.byWidgetPredicate((w) => w is FilledButton),
            ),
            findsOneWidget,
          );
          expect(find.byIcon(Icons.play_arrow), findsOneWidget);
          await capture(tester, 'paused-$tag');
          await press('종료');
          await press('모의고사');
          expect(c.mockSetup!.subject, '국어');
          expect(c.mockSetup!.plannedSeconds, 4800);
          expect(find.text('시험 시간'), findsOneWidget);
          await capture(tester, 'mock-setup-$tag');
          final dropdown = find.byKey(const Key('mock-duration'));
          final labels = tester.widget<DropdownButtonFormField<String>>(
            dropdown,
          );
          // Open the actual menu to check display order, duration and long labels.
          expect(labels, isNotNull);
          await tester.ensureVisible(dropdown);
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
          await capture(tester, 'preset-menu-$tag');
          final choices = [
            '국어 80분',
            '수학 100분',
            '영어 70분',
            '영어 45분 · 듣기 제외',
            '한국사 30분',
            '탐구 30분',
            '사용자 지정',
          ];
          final positions = choices
              .map((t) => tester.getTopLeft(find.text(t).last).dy)
              .toList();
          expect(positions, orderedEquals([...positions]..sort()));
          await press('영어 45분 · 듣기 제외');
          await press('연습 시작');
          expect(c.draft!.mock!.subject, '영어');
          expect(c.draft!.mock!.plannedSeconds, 2700);
          clock.advance(2700000);
          await c.tick();
          await tester.pumpAndSettle();
          expect(find.text('시험 시간이 끝났어요.'), findsOneWidget);
          await capture(tester, 'timeUp-$tag');
          expect(MockSetup.presets.values, [80, 100, 70, 45, 30, 30]);
        },
      );
    }
  }
}
