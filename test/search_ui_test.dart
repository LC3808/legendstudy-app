import 'package:legendstudy_app/features/content/domain/content_item.dart';

import 'study_core_test.dart' show TestClock, TestStore, TestRepo;

import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/study_providers.dart';

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/materials/application/search_controller.dart';
import 'package:legendstudy_app/features/materials/domain/search_models.dart';
import 'package:legendstudy_app/features/materials/presentation/materials_page.dart';

import 'support/search_fake.dart';

const render = bool.fromEnvironment('SEARCH_RENDER');
Future<void> Function(String)? nativeCapture;
final boundary = GlobalKey();
Future<void> capture(WidgetTester tester, String name) async {
  expect(tester.takeException(), isNull);
  if (nativeCapture != null) await nativeCapture!(name);
  if (!render) return;
  await tester.runAsync(() async {
    final image =
        await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final folder = Directory('build/search-review')
      ..createSync(recursive: true);
    File('${folder.path}/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  WidgetController.hitTestWarningShouldBeFatal = true;
  setUpAll(() async {
    if (render) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader('SearchPreview')..addFont(
            File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                .readAsBytes()
                .then((b) => ByteData.sublistView(b)),
          ))
          .load();
    }
  });
  Future<void> choose(WidgetTester tester, String chip, String option) async {
    final finder = find.widgetWithText(ActionChip, chip);
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
    final tile = find.widgetWithText(ListTile, option);
    await tester.ensureVisible(tile);
    await tester.tap(tile);
    await tester.pumpAndSettle();
  }

  for (final size in [const Size(360, 640), const Size(428, 926)]) {
    for (final scale in [1.0, 2.0]) {
      for (final scenario in [
        'empty',
        'one',
        'many',
        'loading',
        'error',
        'filters',
        'keyboard',
      ]) {
        testWidgets('search render ${size.width} $scale $scenario', (
          tester,
        ) async {
          if (nativeCapture != null && size.width == 360) return;
          if (const bool.fromEnvironment('SEARCH_KEYBOARD_ONLY') &&
              scenario != 'keyboard') {
            return;
          }
          if (nativeCapture == null) {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
          }
          final fixtures = searchFixtures();
          final long = fixtures.first;
          final one = ResourceSearchItem(
            content: long.content,
            exam: long.exam,
            sortDate: long.sortDate,
            groups: [
              ResourceGroup(
                name: '아주 긴 과목 이름과 선택과목 세부 분류 표시',
                examSubjectId: 'long-occurrence',
                resources: long.groups.single.resources,
              ),
            ],
          );
          final repo = FakeSearchRepository(
            items: scenario == 'empty'
                ? []
                : scenario == 'one'
                ? [one]
                : fixtures,
          );
          final pending = Completer<void>();
          if (scenario == 'loading') repo.delay = pending.future;
          if (scenario == 'error') repo.fail = true;
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                searchRepositoryProvider.overrideWithValue(repo),
                studyControllerProvider.overrideWith(
                  (ref) => StudyController(
                    TestClock(),
                    TestStore(),
                    () => TestRepo('test-only'),
                  ),
                ),
              ],
              child: RepaintBoundary(
                key: boundary,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: render
                      ? AppTheme.light.copyWith(
                          textTheme: AppTheme.light.textTheme.apply(
                            fontFamily: 'SearchPreview',
                          ),
                        )
                      : AppTheme.light,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: Scaffold(
                    body: SafeArea(child: MaterialsPage()),
                    bottomNavigationBar: NavigationBar(
                      selectedIndex: 1,
                      destinations: [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined),
                          label: '홈',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.article),
                          label: '자료',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.timer_outlined),
                          label: '학습',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline),
                          label: 'MY',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          if (scenario == 'filters') {
            await choose(tester, '학년', '고3');
            await choose(tester, '연도', '2026년');
            await choose(tester, '과목', '국어');
            expect(repo.calls.last.filters.grade, 3);
            expect(repo.calls.last.filters.year, 2026);
            expect(repo.calls.last.filters.subjectId, 'korean');
          }
          if (scenario == 'keyboard') {
            await tester.showKeyboard(find.byType(TextField));
            if (nativeCapture == null) {
              tester.view.viewInsets = const FakeViewPadding(bottom: 280);
              addTearDown(tester.view.resetViewInsets);
            }
            await tester.enterText(find.byType(TextField), '고3');
            await tester.pump(const Duration(milliseconds: 400));
            await tester.pump();
            if (nativeCapture != null) {
              await tester.tap(find.byType(TextField));
              await SystemChannels.textInput.invokeMethod<void>(
                'TextInput.show',
              );
              await Future<void>.delayed(const Duration(milliseconds: 700));
              await tester.pump();
              expect(
                tester.view.viewInsets.bottom,
                greaterThan(0),
                reason: 'Native software keyboard must actually be visible',
              );
            }
          }
          final width = nativeCapture == null
              ? size.width.toInt()
              : (tester.view.physicalSize.width / tester.view.devicePixelRatio)
                    .round();
          final name = '$width-${scale.toInt()}x-$scenario';
          await capture(tester, name);
          if (scenario != 'keyboard') {
            final target = switch (scenario) {
              'empty' => find.text('아직 등록된 자료가 없어요.'),
              'error' => find.text('다시 시도'),
              'loading' => find.byType(CircularProgressIndicator),
              _ => find.byType(SearchResultTile).first,
            };
            await tester.ensureVisible(target);
            await tester.pump(const Duration(milliseconds: 100));
            await capture(tester, '$name-result');
          }
          if (scenario == 'error') {
            repo.fail = false;
            await tester.tap(find.text('다시 시도'));
            await tester.pumpAndSettle();
            expect(find.byType(SearchResultTile), findsNWidgets(3));
          }
          if (scenario == 'filters') {
            await tester.ensureVisible(find.text('필터 초기화'));
            await tester.tap(find.text('필터 초기화'));
            await tester.pumpAndSettle();
            expect(repo.calls.last.filters.isEmpty, isTrue);
          }
          if (scenario == 'loading') {
            pending.complete();
            await tester.pumpAndSettle();
          }
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }
  testWidgets('Owner five results then explicit more renders ten', (
    tester,
  ) async {
    final repo = FakeSearchRepository(
      items: [
        ...searchFixtures(),
        ResourceSearchItem(
          content: const ContentItem(
            id: 'extra',
            slug: 'extra',
            contentType: 'study_material',
            title: '추가 자료',
            sourceUrl: 'https://example.org/extra',
            isActive: true,
          ),
          groups: const [],
        ),
      ],
    )..pageSize = 5;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [searchRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: MaterialsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SearchResultTile), findsNWidgets(5));
    final more = find.text('자료 더 보기');
    await tester.ensureVisible(more);
    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(find.byType(SearchResultTile), findsNWidgets(10));
    expect(tester.takeException(), isNull);
  });
  testWidgets('Home query handoff, debounce, no results and clear browse', (
    tester,
  ) async {
    final repo = FakeSearchRepository();
    final container = ProviderContainer(
      overrides: [
        searchRepositoryProvider.overrideWithValue(repo),
        studyControllerProvider.overrideWith(
          (ref) => StudyController(
            TestClock(),
            TestStore(),
            () => TestRepo('test-only'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LegendStudyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '2026 9 월 고3 영어');
    expect(repo.calls, isEmpty);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(
      container
          .read(routerProvider)
          .routeInformationProvider
          .value
          .uri
          .queryParameters['q'],
      '2026 9 월 고3 영어',
    );
    expect(repo.calls.last.text, '2026 9월 고3 영어');
    expect(find.byType(SearchResultTile), findsOneWidget);
    final before = repo.calls.length;
    await tester.enterText(find.byType(TextField), '없는');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), '없는자료');
    await tester.pump(const Duration(milliseconds: 300));
    expect(repo.calls.length, before);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();
    expect(repo.calls.length, before + 1);
    expect(find.text('조건에 맞는 자료가 없어요.'), findsOneWidget);
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pumpAndSettle();
    expect(repo.calls.last.isBrowse, isTrue);
    expect(find.byType(SearchResultTile), findsNWidgets(3));
  });
}
