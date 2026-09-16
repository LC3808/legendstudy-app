import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/content/domain/content_item.dart';
import 'package:legendstudy_app/features/content/domain/content_repository.dart';
import 'package:legendstudy_app/features/content/presentation/content_detail_page.dart';
import 'package:legendstudy_app/features/personal/bookmark_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/personal/domain/personal_repositories.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';

class FakeBookmarkRepository implements BookmarkRepository {
  bool saved = false;
  int reads = 0, adds = 0, deletes = 0;
  bool failNext = false;
  final Completer<void>? gate;
  FakeBookmarkRepository({this.gate});
  @override
  Future<List<PersonalContentEntry>> fetchOwnBookmarks() async => [];
  @override
  Future<bool> isBookmarked(String _) async {
    reads++;
    return saved;
  }

  @override
  Future<void> addBookmark(String _) async {
    adds++;
    if (gate != null) await gate!.future;
    if (failNext) {
      failNext = false;
      throw StateError('test failure');
    }
    saved = true;
  }

  @override
  Future<void> deleteBookmark(String _) async {
    deletes++;
    if (failNext) {
      failNext = false;
      throw StateError('test failure');
    }
    saved = false;
  }
}

class FakeRecentRepository implements RecentViewRepository {
  int touches = 0;
  bool fail = false;
  @override
  Future<List<PersonalContentEntry>> fetchOwnRecentViews({
    int limit = 100,
  }) async => [];
  @override
  Future<void> touchRecentView(String _) async {
    touches++;
    if (fail) throw StateError('test failure');
  }

  @override
  Future<void> deleteRecentView(String _) async {}

  @override
  Future<void> deleteAllRecentViews() async {}
}

class FakeContentRepository implements ContentRepository {
  FakeContentRepository(this.item);
  final ContentItem item;
  @override
  Future<List<ContentItem>> fetchRecentContent({int limit = 30}) async => [
    item,
  ];
  @override
  Future<List<ContentItem>> searchContent(
    String query, {
    int limit = 30,
    String? contentType,
  }) async => [item];
  @override
  Future<ContentItem?> fetchContentBySlug(String slug) async => item;
  @override
  Future<List<ContentItem>> fetchContentByIds(List<String> ids) async => [item];
}

ContentItem item() => ContentItem(
  id: 'content-1',
  slug: 'item-1',
  contentType: 'education_column',
  title: '긴 자료 제목',
  sourceUrl: 'https://legendstudy.com/item-1',
  isActive: true,
);

ProviderContainer containerFor({
  required AuthStatus auth,
  required FakeBookmarkRepository bookmarks,
}) => ProviderContainer(
  overrides: [
    authStateProvider.overrideWith((ref) => Stream.value(auth)),
    bookmarkRepositoryProvider.overrideWithValue(bookmarks),
  ],
);

void main() {
  test('authenticated saved and unsaved state, add/delete, duplicate tap protection', () async {
    final repo = FakeBookmarkRepository(gate: Completer<void>());
    final container = containerFor(
      auth: const AuthStatus('a'),
      bookmarks: repo,
    );
    addTearDown(container.dispose);
    final sub = container.listen(bookmarkStateProvider('content-1'), (_, _) {});
    addTearDown(sub.close);
    container.read(bookmarkStateProvider('content-1'));
    await container.read(authStateProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final controller = container.read(
      bookmarkStateProvider('content-1').notifier,
    );
    final first = controller.toggle();
    await container.read(authStateProvider.future);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(repo.adds, 1);
    expect(
      container.read(bookmarkStateProvider('content-1')).phase,
      BookmarkPhase.mutating,
    );
    final second = controller.toggle();
    expect(repo.adds, 1);
    (repo.gate!).complete();
    await Future.wait([first, second]);
    expect(container.read(bookmarkStateProvider('content-1')).isSaved, isTrue);
    await controller.toggle();
    expect(repo.deletes, 1);
    expect(container.read(bookmarkStateProvider('content-1')).isSaved, isFalse);
  });

  test(
    'guest bookmark does not call repository and auth A/B state is isolated',
    () async {
      final guestRepo = FakeBookmarkRepository();
      final guest = containerFor(
        auth: const AuthStatus(null),
        bookmarks: guestRepo,
      );
      addTearDown(guest.dispose);
      final guestSub = guest.listen(
        bookmarkStateProvider('content-1'),
        (_, _) {},
      );
      addTearDown(guestSub.close);
      guest.read(bookmarkStateProvider('content-1'));
      await guest.read(authStateProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(guest.read(bookmarkStateProvider('content-1')).isSaved, isFalse);
      expect(guestRepo.reads, 0);
      final aRepo = FakeBookmarkRepository()..saved = true;
      final a = containerFor(auth: const AuthStatus('a'), bookmarks: aRepo);
      addTearDown(a.dispose);
      final aSub = a.listen(bookmarkStateProvider('content-1'), (_, _) {});
      addTearDown(aSub.close);
      a.read(bookmarkStateProvider('content-1'));
      await a.read(authStateProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(a.read(bookmarkStateProvider('content-1')).isSaved, isTrue);
      final bRepo = FakeBookmarkRepository();
      final b = containerFor(auth: const AuthStatus('b'), bookmarks: bRepo);
      addTearDown(b.dispose);
      final bSub = b.listen(bookmarkStateProvider('content-1'), (_, _) {});
      addTearDown(bSub.close);
      b.read(bookmarkStateProvider('content-1'));
      await b.read(authStateProvider.future);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(b.read(bookmarkStateProvider('content-1')).isSaved, isFalse);
    },
  );

  testWidgets(
    'resolved detail records recent once and rebuild does not repeat it',
    (tester) async {
      final recent = FakeRecentRepository();
      final bookmarks = FakeBookmarkRepository();
      final value = item();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('a')),
            ),
            contentDetailProvider('item-1').overrideWith((ref) async => value),
            bookmarkRepositoryProvider.overrideWithValue(bookmarks),
            recentViewRepositoryProvider.overrideWithValue(recent),
          ],
          child: const MaterialApp(home: ContentDetailPage(slug: 'item-1')),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('긴 자료 제목'), findsOneWidget);
      expect(recent.touches, 0);
      await tester.pump(const Duration(seconds: 10));
      expect(recent.touches, 1);
    },
  );

  testWidgets(
    'recent failure does not hide detail and a fresh entry records again',
    (tester) async {
      final recent = FakeRecentRepository()..fail = true;
      final value = item();
      Future<void> pumpPage(String slug) => tester.pumpWidget(
        ProviderScope(
          key: ValueKey(slug),
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('a')),
            ),
            contentDetailProvider(slug).overrideWith((ref) async => value),
            bookmarkRepositoryProvider.overrideWithValue(
              FakeBookmarkRepository(),
            ),
            recentViewRepositoryProvider.overrideWithValue(recent),
          ],
          child: MaterialApp(home: ContentDetailPage(slug: slug)),
        ),
      );
      await pumpPage('item-1');
      await tester.pump();
      await tester.pump();
      expect(find.text('긴 자료 제목'), findsOneWidget);
      expect(recent.touches, 0);
      recent.fail = false;
      await pumpPage('item-1-reentry');
      await tester.pump();
      await tester.pump();
      expect(recent.touches, 0);
      await tester.pump(const Duration(seconds: 10));
      expect(recent.touches, 1);
    },
  );
}
