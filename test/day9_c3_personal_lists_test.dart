import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/exams/exam_providers.dart';
import 'package:legendstudy_app/features/exams/domain/exam_metadata.dart';
import 'package:legendstudy_app/features/content/presentation/content_type_badge.dart';
import 'package:legendstudy_app/features/content/domain/content_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/content/domain/content_item.dart';
import 'package:legendstudy_app/features/content/domain/content_repository.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/personal/domain/personal_repositories.dart';
import 'package:legendstudy_app/features/personal/personal_list_providers.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/personal/presentation/personal_material_list.dart';

class ListBookmarkRepository implements BookmarkRepository {
  ListBookmarkRepository(this.entries);
  final List<PersonalContentEntry> entries;
  int reads = 0;
  bool fail = false;
  @override
  Future<List<PersonalContentEntry>> fetchOwnBookmarks() async {
    reads++;
    if (fail) throw StateError('bookmark failure');
    return entries;
  }

  @override
  Future<void> addBookmark(String contentItemId) async {}
  @override
  Future<void> deleteBookmark(String contentItemId) async {}
  @override
  Future<Set<String>> fetchBookmarkedIds(List<String> ids) async => {};
  @override
  Future<bool> isBookmarked(String contentItemId) async => false;
}

class ListRecentRepository implements RecentViewRepository {
  ListRecentRepository(this.entries);
  final List<PersonalContentEntry> entries;
  int reads = 0;
  @override
  Future<List<PersonalContentEntry>> fetchOwnRecentViews({
    int limit = 100,
  }) async {
    reads++;
    return entries.take(limit).toList();
  }

  @override
  Future<void> touchRecentView(String contentItemId) async {}

  @override
  Future<void> deleteRecentView(String contentItemId) async {}

  @override
  Future<void> deleteAllRecentViews() async {}
}

class BatchContentRepository implements ContentRepository {
  BatchContentRepository(this.items);
  final List<ContentItem> items;
  int batchReads = 0;
  @override
  Future<List<ContentItem>> fetchRecentContent({int limit = 30}) async => items;
  @override
  Future<List<ContentItem>> searchContent(
    String query, {
    int limit = 30,
    String? contentType,
  }) async => items;
  @override
  Future<ContentItem?> fetchContentBySlug(String slug) async => null;
  @override
  Future<List<ContentItem>> fetchContentByIds(List<String> ids) async {
    batchReads++;
    return items.where((item) => ids.contains(item.id)).toList();
  }
}

PersonalContentEntry entry(String id, int day) => PersonalContentEntry(
  id: 'row-$id',
  contentItemId: id,
  timestamp: DateTime.utc(2026, 9, day),
);

ContentItem content(String id, String title) => ContentItem(
  id: id,
  slug: id,
  contentType: 'education_column',
  title: title,
  sourceUrl: 'https://legendstudy.com/$id',
  isActive: true,
);

ProviderContainer listContainer({
  required AuthStatus auth,
  required ListBookmarkRepository bookmarks,
  required ListRecentRepository recent,
  required BatchContentRepository content,
}) => ProviderContainer(
  overrides: [
    authStateProvider.overrideWith((ref) => Stream.value(auth)),
    bookmarkRepositoryProvider.overrideWithValue(bookmarks),
    recentViewRepositoryProvider.overrideWithValue(recent),
    contentRepositoryProvider.overrideWithValue(content),
  ],
);

void main() {
  for (final kind in PersonalListKind.values) {
    for (final width in [360.0, 428.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('personal card hierarchy $kind $width $scale', (
          tester,
        ) async {
          tester.view.physicalSize = Size(width, width == 360 ? 640 : 926);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          const title = '긴 학습자료 제목과 과목별 설명을 표시해도 삭제 아이콘과 겹치지 않는 자료';
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                authStateProvider.overrideWith(
                  (ref) => Stream.value(const AuthStatus('a')),
                ),
                bookmarkRepositoryProvider.overrideWithValue(
                  ListBookmarkRepository([entry('a', 15)]),
                ),
                recentViewRepositoryProvider.overrideWithValue(
                  ListRecentRepository([entry('a', 15)]),
                ),
                contentRepositoryProvider.overrideWithValue(
                  BatchContentRepository([content('a', title)]),
                ),
              ],
              child: MaterialApp(
                theme: AppTheme.light,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: PersonalMaterialListPage(kind: kind),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final badge = find.byType(ContentTypeBadge);
          expect(tester.widget<ContentTypeBadge>(badge).outlined, isTrue);
          final marker = find.descendant(
            of: badge,
            matching: find.byType(Container),
          );
          final box =
              tester.widget<Container>(marker).decoration! as BoxDecoration;
          expect(box.color, AppTokens.background);
          expect((box.border! as Border).top.color, AppTokens.textPrimary);
          final badgeText = find.descendant(
            of: badge,
            matching: find.byType(Text),
          );
          expect(
            tester.widget<Text>(badgeText).style!.color,
            AppTokens.textPrimary,
          );
          final card = tester.widget<Card>(find.byType(Card).first);
          expect(card.color, AppTokens.surface);
          expect(card.elevation, 0);
          expect(
            (card.shape! as RoundedRectangleBorder).side.color,
            AppTokens.majorSurfaceBorder,
          );
          final titleRect = tester.getRect(find.text(title));
          final badgeRect = tester.getRect(badgeText);
          expect(badgeRect.bottom <= titleRect.top, isTrue);
          expect(badgeRect.right <= width, isTrue);
          if (kind == PersonalListKind.recentViews) {
            final delete = find.byWidgetPredicate(
              (w) => w is IconButton && w.tooltip == '최근 본 자료 삭제',
            );
            expect(titleRect.right <= tester.getRect(delete).left, isTrue);
            expect(
              tester.widget<IconButton>(delete).color,
              AppTokens.textSecondary,
            );
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  test('canonical material labels match search categories', () {
    expect(materialTypeLabel('exam', examType: 'csat'), '수능');
    for (final type in ['national_mock', 'evaluation_mock']) {
      expect(
        materialTypeLabel('exam', examType: type),
        contentTypeLabels['exam'],
      );
    }
    expect(materialTypeLabel('exam'), '시험 자료');
    for (final pair in [
      ('national_mock', '학력평가'),
      ('evaluation_mock', '모의평가'),
      ('csat', '수능'),
      ('unknown', '시험 자료'),
    ]) {
      expect(
        materialTypeLabel('exam', examType: pair.$1, preciseExam: true),
        pair.$2,
      );
    }
    expect(materialTypeLabel('exam', preciseExam: true), '시험 자료');
    expect(materialTypeLabel('university_essay'), '논술');
    expect(materialTypeLabel('study_material'), '학습자료');
  });
  for (final kind in PersonalListKind.values) {
    for (final type in ['csat', 'national_mock', 'evaluation_mock']) {
      testWidgets('$kind uses canonical title and badge for $type', (
        tester,
      ) async {
        final prefix = type == 'csat'
            ? '2026학년도 수능'
            : type == 'evaluation_mock'
            ? '2026 고3 모의평가'
            : '2025년 10월 고3 모의고사';
        final raw = '$prefix 기출 - 문제, 답, 해설, 등급컷';
        final item = ContentItem(
          id: 'a',
          slug: 'a',
          contentType: 'exam',
          title: raw,
          sourceUrl: 'https://legendstudy.com/1',
          isActive: true,
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => Stream.value(const AuthStatus('a')),
              ),
              bookmarkRepositoryProvider.overrideWithValue(
                ListBookmarkRepository([entry('a', 15)]),
              ),
              recentViewRepositoryProvider.overrideWithValue(
                ListRecentRepository([entry('a', 15)]),
              ),
              contentRepositoryProvider.overrideWithValue(
                BatchContentRepository([item]),
              ),
              examMetadataProvider('a').overrideWith(
                (ref) async => {
                  'a': ExamMetadata(contentItemId: 'a', examType: type),
                },
              ),
            ],
            child: MaterialApp(home: PersonalMaterialListPage(kind: kind)),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text(prefix), findsOneWidget);
        expect(find.text(raw), findsNothing);
        expect(
          find.descendant(
            of: find.byType(ContentTypeBadge),
            matching: find.text(
              type == 'csat'
                  ? '수능'
                  : type == 'national_mock'
                  ? '학력평가'
                  : '모의평가',
            ),
          ),
          findsOneWidget,
        );
        expect(item.title, raw);
        expect(tester.takeException(), isNull);
      });
    }
  }

  test(
    'saved list keeps server order and hydrates with one bounded batch',
    () async {
      final bookmarks = ListBookmarkRepository([
        entry('a', 15),
        entry('missing', 14),
        entry('b', 13),
      ]);
      final contentRepo = BatchContentRepository([
        content('a', '최신 저장 자료'),
        content('b', '이전 저장 자료'),
      ]);
      final container = listContainer(
        auth: const AuthStatus('account-a'),
        bookmarks: bookmarks,
        recent: ListRecentRepository([]),
        content: contentRepo,
      );
      addTearDown(container.dispose);
      final sub = container.listen(
        personalMaterialListProvider(PersonalListKind.bookmarks),
        (_, _) {},
      );
      addTearDown(sub.close);
      final items = await container.read(
        personalMaterialListProvider(PersonalListKind.bookmarks).future,
      );
      expect(items.map((item) => item.item.id), ['a', 'b']);
      expect(contentRepo.batchReads, 1);
      expect(bookmarks.reads, 1);
    },
  );

  test('guest list does not request cloud personal or content data', () async {
    final bookmarks = ListBookmarkRepository([]);
    final recent = ListRecentRepository([]);
    final contentRepo = BatchContentRepository([]);
    final container = listContainer(
      auth: const AuthStatus(null),
      bookmarks: bookmarks,
      recent: recent,
      content: contentRepo,
    );
    addTearDown(container.dispose);
    expect(
      await container.read(
        personalMaterialListProvider(PersonalListKind.bookmarks).future,
      ),
      isEmpty,
    );
    expect(
      await container.read(
        personalMaterialListProvider(PersonalListKind.recentViews).future,
      ),
      isEmpty,
    );
    expect(bookmarks.reads, 0);
    expect(recent.reads, 0);
    expect(contentRepo.batchReads, 0);
  });

  testWidgets(
    'authenticated recent list shows order, long titles, and 2x text without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final recent = ListRecentRepository([entry('a', 15), entry('b', 14)]);
      final contentRepo = BatchContentRepository([
        content('a', '아주 긴 최근 본 자료 제목이 여러 줄로 안전하게 표시되는지 확인합니다'),
        content('b', '이전 자료'),
      ]);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => Stream.value(const AuthStatus('a')),
              ),
              bookmarkRepositoryProvider.overrideWithValue(
                ListBookmarkRepository([]),
              ),
              recentViewRepositoryProvider.overrideWithValue(recent),
              contentRepositoryProvider.overrideWithValue(contentRepo),
            ],
            child: const MaterialApp(
              home: PersonalMaterialListPage(
                kind: PersonalListKind.recentViews,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.textContaining('아주 긴 최근 본 자료'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('saved list error exposes retry', (tester) async {
    final bookmarks = ListBookmarkRepository([])..fail = true;
    final contentRepo = BatchContentRepository([]);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('a')),
          ),
          bookmarkRepositoryProvider.overrideWithValue(bookmarks),
          recentViewRepositoryProvider.overrideWithValue(
            ListRecentRepository([]),
          ),
          contentRepositoryProvider.overrideWithValue(contentRepo),
        ],
        child: const MaterialApp(
          home: PersonalMaterialListPage(kind: PersonalListKind.bookmarks),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('자료 목록을 불러오지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}
