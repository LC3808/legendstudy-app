import 'support/search_fake.dart';

import 'package:legendstudy_app/features/study/trends/study_trend_page.dart';

import 'package:legendstudy_app/features/materials/application/search_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';
import 'package:legendstudy_app/features/content/domain/content_item.dart';
import 'package:legendstudy_app/features/content/domain/content_repository.dart';
import 'package:legendstudy_app/features/content/presentation/content_card.dart';

const item = ContentItem(
  id: 'one',
  slug: 'sample',
  contentType: 'study_material',
  title: '테스트 자료',
  sourceUrl: 'https://legendstudy.com/1',
  isActive: true,
);

class ShellContent implements ContentRepository {
  final queries = <String>[];
  @override
  Future<List<ContentItem>> fetchRecentContent({int limit = 30}) async => [];
  @override
  Future<List<ContentItem>> searchContent(
    String query, {
    int limit = 30,
    String? contentType,
  }) async {
    queries.add(query);
    return [item];
  }

  @override
  Future<ContentItem?> fetchContentBySlug(String slug) async =>
      slug == 'sample' ? item : null;
  @override
  Future<List<ContentItem>> fetchContentByIds(List<String> ids) async => [];
}

void main() {
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    String? user,
    ShellContent? content,
  }) async {
    final container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(content ?? ShellContent()),
        searchRepositoryProvider.overrideWithValue(
          LegacySearchFake(content ?? ShellContent()),
        ),
        authStateProvider.overrideWith((ref) => Stream.value(AuthStatus(user))),
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
    return container;
  }

  Future<void> tab(WidgetTester tester, int index) async {
    await tester.tap(find.byType(NavigationDestination).at(index));
    await tester.pumpAndSettle();
  }

  testWidgets('MY study CTAs and score entry use canonical branches', (
    tester,
  ) async {
    final container = await mount(tester, user: 'a');
    await tab(tester, 4);
    await tester.ensureVisible(find.text('공부 추이 보기'));
    await tester.tap(find.text('공부 추이 보기'));
    await tester.pumpAndSettle();
    expect(find.byType(StudyTrendPage), findsOneWidget);
    expect(container.read(routerProvider).canPop(), isTrue);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('공부하러 가기'));
    await tester.tap(find.text('공부하러 가기'));
    await tester.pumpAndSettle();
    expect(
      container.read(routerProvider).routeInformationProvider.value.uri.path,
      '/study',
    );
    await tab(tester, 4);
    await tester.ensureVisible(find.byKey(const Key('my-mock-lab')));
    await tester.tap(find.byKey(const Key('my-mock-lab')));
    await tester.pumpAndSettle();
    expect(find.text('내신 성적 입력과 상세 분석은 아직 지원하지 않아요.'), findsNothing);
    expect(find.text('모의고사 분석'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      4,
    );
    expect(find.text('MY'), findsWidgets);
  });
  for (final detail in [
    ('내신 분석', '/lab/school-scores'),
    ('모의고사 분석', '/lab/scores'),
  ]) {
    testWidgets('LAB ${detail.$1} and direct link return to LAB', (
      tester,
    ) async {
      final c = await mount(tester);
      await tab(tester, 3);
      await tester.tap(find.text(detail.$1));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        3,
      );
      expect(find.text('논술 준비'), findsOneWidget);
      c.read(routerProvider).go(detail.$2);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('논술 준비'), findsOneWidget);
    });
    testWidgets('MY ${detail.$1} Back returns MY', (tester) async {
      await mount(tester, user: 'a');
      await tab(tester, 4);
      final entry = find.byKey(
        Key(
          detail.$2.endsWith('school-scores') ? 'my-school-lab' : 'my-mock-lab',
        ),
      );
      await tester.ensureVisible(entry);
      await tester.tap(entry);
      await tester.pumpAndSettle();
      expect(find.text(detail.$1), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        4,
      );
      expect(find.byKey(const Key('my-mock-lab')), findsOneWidget);
    });
  }
  testWidgets('five destinations and MY saved route retain branch stacks', (
    tester,
  ) async {
    final container = await mount(tester);
    expect(
      tester
          .widgetList<NavigationDestination>(find.byType(NavigationDestination))
          .map((w) => w.label),
      ['홈', '자료', '학습', 'LAB', 'MY'],
    );
    expect(find.text('아직 등록된 자료가 없어요.'), findsOneWidget);
    await tab(tester, 4);
    expect(find.text('로그인'), findsOneWidget);
    expect(find.text('저장한 자료'), findsNothing);
    container.read(routerProvider).go('/my/saved');
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).canPop(), isTrue);
    expect(find.text('로그인하면 이 기능을 이용할 수 있어요.'), findsOneWidget);
    await tab(tester, 2);
    await tab(tester, 4);
    expect(find.text('로그인하면 이 기능을 이용할 수 있어요.'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
  });
  testWidgets(
    'materials search state survives tabs and detail pushes above shell',
    (tester) async {
      final container = await mount(tester);
      await tab(tester, 1);
      await tester.enterText(find.byType(TextField), '영어');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text('테스트 자료'), findsOneWidget);
      await tab(tester, 2);
      await tab(tester, 1);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '영어',
      );
      await tester.ensureVisible(find.text('테스트 자료'));
      await tester.tap(find.text('테스트 자료'));
      await tester.pumpAndSettle();
      expect(container.read(routerProvider).canPop(), isTrue);
      expect(find.text('테스트 자료'), findsOneWidget);
      expect(find.text('자료 상세'), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '영어',
      );
    },
  );
  testWidgets('Home search entry submits only on action and clears results', (
    tester,
  ) async {
    final content = ShellContent();
    await mount(tester, content: content);
    final entry = find.byTooltip('자료 검색');
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), '영어');
    await tester.pumpAndSettle();
    expect(content.queries, isEmpty);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(content.queries, ['영어']);
    expect(find.text('테스트 자료'), findsOneWidget);
    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.text('아직 등록된 자료가 없어요.'), findsOneWidget);
    expect(find.text('테스트 자료'), findsNothing);
    expect(find.byTooltip('검색어 지우기'), findsNothing);
    await tab(tester, 2);
    await tab(tester, 1);
    expect(find.text('아직 등록된 자료가 없어요.'), findsOneWidget);
    expect(content.queries, ['영어']);
  });

  testWidgets(
    'content badges and real metadata fit small screens at large text',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final entry in {
        'exam': '모의고사',
        'study_material': '학습자료',
        'university_essay': '논술',
        'admissions_info': '입시정보',
        'education_column': '교육칼럼',
        'other': '기타',
      }.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ContentCard(
                  ContentItem(
                    id: 'fixture',
                    slug: 'fixture',
                    contentType: entry.key,
                    title: '길이가 긴 자료 제목으로 화면 너비와 큰 글씨 줄바꿈을 확인합니다',
                    summary: '실제 사용자 데이터가 아닌 위젯 테스트 전용 긴 요약 문장입니다. 여러 줄을 넘겨 표시를 검증합니다.',
                    publishedAt: DateTime.utc(2026, 9, 13),
                    sourceUrl: 'https://legendstudy.com/1',
                    isActive: true,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(entry.value), findsOneWidget);
        expect(
          find.text('게시 2026.09.13'),
          entry.key == 'exam' ? findsNothing : findsOneWidget,
        );
        expect(find.text('자료 살펴보기'), findsNothing);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: ContentCard(item))),
      );
      expect(find.textContaining('게시 '), findsNothing);
      expect(find.textContaining('업데이트 '), findsNothing);
    },
  );

  testWidgets('guest can enter school shell without saving or login', (
    tester,
  ) async {
    final container = await mount(tester);
    await tester.ensureVisible(find.text('학교 설정'));
    await tester.tap(find.text('학교 설정'));
    await tester.pumpAndSettle();
    expect(container.read(routerProvider).canPop(), isTrue);
    expect(find.text('학교·학년 설정'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('로그인'), findsNothing);
  });
  testWidgets('Study idle and headers expose accessible semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await mount(tester);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('오늘도 공부를 시작해 볼까요?'))
          .flagsCollection
          .isHeader,
      isTrue,
    );
    expect(find.text('오늘도 공부를 시작해 볼까요?'), findsOneWidget);
    expect(find.byIcon(Icons.auto_stories_outlined), findsNothing);
    expect(find.byType(Image), findsNothing);
    await tab(tester, 2);
    expect(find.bySemanticsLabel('공부 타이머, 대기 상태, 0시간 0분 0초'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, '공부 시작'))
          .onPressed,
      isNotNull,
    );
    semantics.dispose();
  });
  testWidgets('MY recognizes authenticated state without exposing identity', (
    tester,
  ) async {
    await mount(tester, user: 'test-owner-id');
    await tab(tester, 4);
    expect(find.text('로그인 계정'), findsNothing);
    expect(find.text('로그인'), findsNothing);
    expect(find.textContaining('test-owner-id'), findsNothing);
  });
  testWidgets('legacy and new deep routes resolve into correct branches', (
    tester,
  ) async {
    final container = await mount(tester);
    final router = container.read(routerProvider);
    for (final entry in {
      '/browse': 1,
      '/saved': 4,
      '/profile': 4,
      '/study': 2,
      '/my/school': 4,
      '/my/grade': 4,
      '/lab': 3,
    }.entries) {
      router.go(entry.key);
      await tester.pumpAndSettle();
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        entry.value,
      );
      expect(tester.takeException(), isNull);
    }
    router.go('/materials?q=논술');
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '논술',
    );
  });
}
