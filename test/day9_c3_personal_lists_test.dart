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
  Future<bool> isBookmarked(String contentItemId) async => false;
}

class ListRecentRepository implements RecentViewRepository {
  ListRecentRepository(this.entries);
  final List<PersonalContentEntry> entries;
  int reads = 0;
  @override
  Future<List<PersonalContentEntry>> fetchOwnRecentViews() async {
    reads++;
    return entries;
  }

  @override
  Future<void> touchRecentView(String contentItemId) async {}
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
