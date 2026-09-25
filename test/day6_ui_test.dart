import 'support/search_fake.dart';

import 'package:legendstudy_app/features/materials/application/search_controller.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/links/external_link.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';
import 'package:legendstudy_app/features/content/domain/content_item.dart';
import 'package:legendstudy_app/features/content/domain/content_repository.dart';
import 'package:legendstudy_app/features/exams/domain/exam_metadata.dart';
import 'package:legendstudy_app/features/exams/domain/exam_repository.dart';
import 'package:legendstudy_app/features/exams/exam_providers.dart';
import 'package:legendstudy_app/features/resources/domain/content_resource.dart';
import 'package:legendstudy_app/features/resources/domain/resource_repository.dart';
import 'package:legendstudy_app/features/resources/resource_providers.dart';

ContentItem parent({String type = 'exam'}) => ContentItem(
  id: 'parent',
  slug: 'fixture',
  contentType: type,
  title: '검증용 콘텐츠',
  summary: '검증용 요약',
  sourceUrl: 'https://legendstudy.com/1',
  isActive: true,
  publishedAt: DateTime.utc(2026, 9, 13),
  sourceUpdatedAt: DateTime.utc(2026, 9, 14),
);
const exam = ExamMetadata(
  contentItemId: 'parent',
  year: 2026,
  academicYear: 2027,
  examMonth: 9,
  gradeLevel: 3,
  examType: 'evaluation_mock',
);
ContentResource resource({
  String id = 'r',
  String? occurrence,
  String group = '일반 자료',
  String resourceType = 'question',
  String linkKind = 'file',
  String sourceUrl = 'https://example.org/page',
  String? fileUrl = 'https://example.org/file.pdf',
}) => ContentResource(
  id: id,
  contentItemId: 'parent',
  examSubjectId: occurrence,
  groupLabel: group,
  resourceType: resourceType,
  title: '첨부 $id',
  sourceUrl: sourceUrl,
  fileUrl: fileUrl,
  linkKind: linkKind,
);

class Parents implements ContentRepository {
  Future<ContentItem?> Function() detail = () async => parent();
  final calls = <ContentFilter>[];
  @override
  Future<List<ContentItem>> fetchRecentContent({int limit = 30}) async => [];
  @override
  Future<List<ContentItem>> searchContent(
    String query, {
    int limit = 30,
    String? contentType,
  }) async {
    calls.add((query: query, contentType: contentType));
    return [parent()];
  }

  @override
  Future<ContentItem?> fetchContentBySlug(String slug) => detail();
  @override
  Future<List<ContentItem>> fetchContentByIds(List<String> ids) async => [];
}

class Exams implements ExamRepository {
  Future<Map<String, ExamMetadata>> Function() result = () async => {
    'parent': exam,
  };
  @override
  Future<Map<String, ExamMetadata>> fetchForContentIds(List<String> ids) =>
      result();
}

class Resources implements ResourceRepository {
  Future<List<ContentResource>> Function() result = () async => [];
  @override
  Future<List<ContentResource>> fetchForContent(String contentItemId) =>
      result();
}

void main() {
  late Parents parents;
  late Exams exams;
  late Resources resources;
  Uri? opened;
  setUp(() {
    parents = Parents();
    exams = Exams();
    resources = Resources();
    opened = null;
  });
  Future<ProviderContainer> mount(
    WidgetTester tester, {
    String route = '/materials',
  }) async {
    final container = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(parents),
        searchRepositoryProvider.overrideWithValue(
          LegacySearchFake(parents, exam: exam),
        ),
        examRepositoryProvider.overrideWithValue(exams),
        resourceRepositoryProvider.overrideWithValue(resources),
        externalOpenerProvider.overrideWithValue((uri) async {
          opened = uri;
          return true;
        }),
      ],
    );
    addTearDown(container.dispose);
    container.read(routerProvider).go(route);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LegendStudyApp(),
      ),
    );
    await tester.pump();
    return container;
  }

  Future<void> choose(WidgetTester tester, String label) async {
    final f = find.widgetWithText(FilterChip, label);
    await tester.ensureVisible(f);
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'type only, combined submit and filter clear retain independent keyword state',
    (tester) async {
      await mount(tester);
      await tester.pumpAndSettle();
      await choose(tester, '모의고사');
      expect(parents.calls.last, (query: '', contentType: 'exam'));
      await tester.enterText(find.byType(TextField), '영어');
      await tester.pumpAndSettle();
      expect(parents.calls.last.query, isEmpty);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(parents.calls.last, (query: '영어', contentType: 'exam'));
      await choose(tester, '전체');
      expect(parents.calls.last, (query: '영어', contentType: null));
      await choose(tester, '학습자료');
      await tester.tap(find.byTooltip('검색어 지우기'));
      await tester.pumpAndSettle();
      expect(parents.calls.last, (query: '', contentType: 'study_material'));
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, '학습자료'))
            .selected,
        isTrue,
      );
    },
  );
  testWidgets('query and type survive tab switches and root detail back', (
    tester,
  ) async {
    await mount(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '영어');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await choose(tester, '모의고사');
    await tester.tap(find.byType(NavigationDestination).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NavigationDestination).at(1));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '영어',
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, '모의고사'))
          .selected,
      isTrue,
    );
    expect(find.text('고3 · 9월 · 2026년 · 평가원'), findsOneWidget);
    await tester.ensureVisible(find.text('검증용 콘텐츠'));
    await tester.tap(find.text('검증용 콘텐츠'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('검증용 콘텐츠'), findsOneWidget);
    expect(find.text('자료 상세'), findsNothing);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '영어',
    );
    expect(
      tester
          .widget<FilterChip>(find.widgetWithText(FilterChip, '모의고사'))
          .selected,
      isTrue,
    );
  });
  testWidgets(
    'Home shortcuts enter real type filter without keyword substitution',
    (tester) async {
      await mount(tester, route: '/home');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('논술'));
      await tester.tap(find.text('논술'));
      await tester.pumpAndSettle();
      expect(parents.calls.last, (query: '', contentType: 'university_essay'));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, '논술'))
            .selected,
        isTrue,
      );
    },
  );
  testWidgets('detail loading then missing parent is a normal state', (
    tester,
  ) async {
    final pending = Completer<ContentItem?>();
    parents.detail = () => pending.future;
    await mount(tester, route: '/materials/fixture');
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('자료를 찾을 수 없어요.'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });
  testWidgets(
    'direct detail back recovers Materials without changing route structure',
    (tester) async {
      await mount(tester, route: '/materials/fixture');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        1,
      );
    },
  );
  testWidgets('detail uses display title and omits source dates', (
    tester,
  ) async {
    const raw = '2026 고3 모의고사 기출 - 문제/답/해설 자료';
    parents.detail = () async => ContentItem(
      id: 'parent',
      slug: 'fixture',
      contentType: 'exam',
      title: raw,
      sourceUrl: 'https://legendstudy.com/1',
      isActive: true,
      publishedAt: DateTime.utc(2026, 9, 13),
      sourceUpdatedAt: DateTime.utc(2026, 9, 14),
    );
    await mount(tester, route: '/materials/fixture');
    await tester.pumpAndSettle();
    expect(find.text('2026 고3 모의고사'), findsOneWidget);
    expect(find.text(raw), findsNothing);
    expect(find.textContaining('게시 '), findsNothing);
    expect(find.textContaining('원문 수정'), findsNothing);
    expect(find.text('출처: 레전드스터디'), findsOneWidget);
    expect(find.text('원문 보기'), findsOneWidget);
    expect((await parents.detail())!.title, raw);
  });
  testWidgets(
    'parent error retries into general content without duplicate title',
    (tester) async {
      parents.detail = () async => throw StateError('test');
      await mount(tester, route: '/materials/fixture');
      await tester.pumpAndSettle();
      expect(find.text('자료를 불러오지 못했어요.'), findsOneWidget);
      parents.detail = () async => parent(type: 'study_material');
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('검증용 콘텐츠'), findsOneWidget);
      expect(find.text('검증용 요약'), findsOneWidget);
      expect(find.text('이 자료에는 별도의 첨부 파일이 없어요.'), findsOneWidget);
      expect(find.text('원문 보기'), findsOneWidget);
      expect(find.text('원문 수정 2026.09.14'), findsNothing);
    },
  );
  testWidgets(
    'exam metadata loading and retry does not hide resource section',
    (tester) async {
      final pending = Completer<Map<String, ExamMetadata>>();
      exams.result = () => pending.future;
      resources.result = () async => [resource()];
      await mount(tester, route: '/materials/fixture');
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.completeError(StateError('test'));
      await tester.pumpAndSettle();
      expect(find.text('시험 정보를 불러오지 못했어요.'), findsOneWidget);
      expect(find.text('첨부 r'), findsOneWidget);
      exams.result = () async => {'parent': exam};
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('고3 · 9월 · 2026년 · 평가원'), findsOneWidget);
      expect(find.text('2027학년도'), findsOneWidget);
    },
  );
  testWidgets('empty exam metadata does not manufacture a metadata line', (
    tester,
  ) async {
    exams.result = () async => {};
    await mount(tester, route: '/materials/fixture');
    await tester.pumpAndSettle();
    expect(find.text('검증용 콘텐츠'), findsOneWidget);
    expect(find.textContaining('학년도'), findsNothing);
    expect(find.textContaining('고3'), findsNothing);
  });
  testWidgets('resource loading error retry and general group', (tester) async {
    parents.detail = () async => parent(type: 'study_material');
    final pending = Completer<List<ContentResource>>();
    resources.result = () => pending.future;
    await mount(tester, route: '/materials/fixture');
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(StateError('test'));
    await tester.pumpAndSettle();
    expect(find.text('첨부 자료를 불러오지 못했어요.'), findsOneWidget);
    resources.result = () async => [resource()];
    await tester.ensureVisible(find.text('다시 시도'));
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('일반 자료'), findsOneWidget);
    expect(find.text('문제 보기'), findsOneWidget);
  });
  testWidgets(
    'unknown resources open the parent source, not the resource URL',
    (tester) async {
      resources.result = () async => [
        resource(
          linkKind: 'unknown',
          sourceUrl: 'https://blog.kakaocdn.net/unsigned.pdf',
          fileUrl: null,
        ),
      ];
      await mount(tester, route: '/materials/fixture');
      await tester.pumpAndSettle();
      expect(find.text('상단 원문 보기에서 자료를 확인하세요.'), findsOneWidget);
      await tester.ensureVisible(find.text('원문 보기'));
      await tester.tap(find.text('원문 보기'));
      await tester.pumpAndSettle();
      expect(opened.toString(), 'https://legendstudy.com/1');
      expect(opened.toString(), isNot(contains('kakaocdn')));
    },
  );
  testWidgets('landing listening resources open their own landing page', (
    tester,
  ) async {
    resources.result = () async => [
      resource(
        resourceType: 'listening_audio',
        linkKind: 'landing_page',
        sourceUrl: 'https://app.box.com/s/english-audio',
        fileUrl: null,
        group: '영어',
      ),
    ];
    await mount(tester, route: '/materials/fixture');
    await tester.pumpAndSettle();
    expect(find.text('영어 듣기'), findsOneWidget);
    await tester.ensureVisible(find.text('영어 듣기 자료 페이지 보기'));
    await tester.tap(find.text('영어 듣기 자료 페이지 보기'));
    await tester.pumpAndSettle();
    expect(opened.toString(), 'https://app.box.com/s/english-audio');
  });
  testWidgets(
    'article with zero resources has source action without large empty card',
    (tester) async {
      parents.detail = () async => parent(type: 'education_column');
      await mount(tester, route: '/materials/fixture');
      await tester.pumpAndSettle();
      expect(find.text('원문 보기'), findsOneWidget);
      expect(find.text('이 자료에는 별도의 첨부 파일이 없어요.'), findsNothing);
      expect(find.text('첨부 자료'), findsNothing);
    },
  );
  testWidgets(
    'subject groups, general attachments and full detail fit 360x640 at 2x',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      resources.result = () async => [
        resource(id: 'mapped', occurrence: 'a', group: '국어'),
        resource(id: 'raw', occurrence: 'b', group: '수학 가형'),
        resource(id: 'general'),
      ];
      await mount(tester, route: '/materials/fixture');
      await tester.pumpAndSettle();
      expect(find.text('국어'), findsOneWidget);
      expect(find.text('수학 가형'), findsOneWidget);
      expect(find.text('일반 자료'), findsOneWidget);
      expect(find.text('첨부 general'), findsOneWidget);
      await tester.ensureVisible(find.text('첨부 general'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  for (final outcome in ['success', 'false', 'exception']) {
    testWidgets(
      'external open handles $outcome without claiming remote availability',
      (tester) async {
        Uri? opened;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              externalOpenerProvider.overrideWithValue((uri) async {
                opened = uri;
                if (outcome == 'exception') throw StateError('test');
                return outcome == 'success';
              }),
            ],
            child: MaterialApp(
              home: Scaffold(
                body: ExternalLinkButton(
                  uri: Uri.parse('https://example.org/file.pdf'),
                  label: '열기',
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('열기'));
        await tester.pumpAndSettle();
        expect(opened.toString(), 'https://example.org/file.pdf');
        expect(
          find.text('외부 링크를 열지 못했어요. 다시 시도해 주세요.'),
          outcome == 'success' ? findsNothing : findsOneWidget,
        );
      },
    );
  }
}
