import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';
import 'package:legendstudy_app/features/content/domain/content_item.dart';
import 'package:legendstudy_app/features/content/domain/content_repository.dart';
import 'package:legendstudy_app/features/content/presentation/content_card.dart';
import 'package:legendstudy_app/features/home/presentation/home_page.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/personal/domain/personal_repositories.dart';
import 'package:legendstudy_app/features/personal/personal_list_providers.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/personal/presentation/personal_material_list.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';

Meal meal(String date, String type) =>
    Meal(date: date, mealType: type, menuItems: ['$type 메뉴']);

void main() {
  group('Meal Today/Tomorrow KST policy', () {
    test('before 14:00 keeps lunch primary and today detail', () {
      final plan = mealDisplayPlan(
        now: DateTime.utc(2026, 9, 16, 4, 59), // 13:59 KST
        today: [meal('20260916', '중식')],
        tomorrow: [meal('20260917', '중식')],
      );
      expect(plan.primaryIsTomorrow, isFalse);
      expect(plan.primary.single.date, '20260916');
      expect(plan.secondary.single.date, '20260916');
    });

    test('14:00 without dinner promotes tomorrow', () {
      final plan = mealDisplayPlan(
        now: DateTime.utc(2026, 9, 16, 5), // 14:00 KST
        today: [meal('20260916', '중식')],
        tomorrow: [meal('20260917', '중식')],
      );
      expect(plan.primaryIsTomorrow, isTrue);
      expect(plan.primary.single.date, '20260917');
      expect(plan.secondary.single.date, '20260917');
    });

    test('before 19:00 keeps dinner primary and today detail', () {
      final plan = mealDisplayPlan(
        now: DateTime.utc(2026, 9, 16, 9),
        today: [meal('20260916', '중식'), meal('20260916', '석식')],
        tomorrow: [meal('20260917', '중식'), meal('20260917', '석식')],
      );
      expect(plan.primary.map((item) => item.mealType), ['석식']);
      expect(plan.secondary, hasLength(2));
    });

    test('after 14:00 with no dinner and no tomorrow is empty', () {
      final plan = mealDisplayPlan(
        now: DateTime.utc(2026, 9, 16, 9),
        today: [meal('20260916', '중식')],
        tomorrow: const [],
      );
      expect(plan.isEmpty, isTrue);
    });

    test('KST date and midnight do not depend on device timezone', () {
      expect(
        koreanDateOffset(DateTime.utc(2026, 9, 16, 14, 59), 0),
        '20260916',
      );
      expect(koreanDateOffset(DateTime.utc(2026, 9, 16, 15), 0), '20260917');
      expect(koreanDateOffset(DateTime.utc(2026, 9, 16, 15), 1), '20260918');
    });
  });

  test('Home recent content provider requests a bounded six items', () async {
    final repository = RecentContentRepository(List.generate(7, content));
    final container = ProviderContainer(
      overrides: [contentRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final items = await container.read(homeRecentContentProvider.future);
    expect(items, hasLength(6));
    expect(repository.limit, 6);
  });

  for (final count in [0, 1, 2, 3, 6, 7]) {
    testWidgets('Home recent updates shows 2 then at most 6 for $count items', (
      tester,
    ) async {
      final items = List.generate(count, content);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeRecentContentProvider.overrideWith((ref) async => items),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: HomeRecentUpdates()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(ContentCard), findsNWidgets(count < 3 ? count : 2));
      if (count > 2) {
        expect(find.text('더보기'), findsOneWidget);
        await tester.tap(find.text('더보기'));
        await tester.pump();
        expect(find.byType(ContentCard), findsNWidgets(count > 6 ? 6 : count));
        expect(find.text('접기'), findsOneWidget);
      } else {
        expect(find.text('더보기'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final count in [0, 1, 2, 3, 6, 7]) {
    testWidgets('Home recent views shows 2 then at most 6 for $count items', (
      tester,
    ) async {
      final repository = RecentRepository(count);
      final contentRepository = RecentContentRepository(
        List.generate(count, content),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('account-a')),
            ),
            recentViewRepositoryProvider.overrideWithValue(repository),
            contentRepositoryProvider.overrideWithValue(contentRepository),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PersonalMaterialList(
                  kind: PersonalListKind.recentViews,
                  homeMode: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('자료 목록을 불러오는 중…'), findsNothing);
      expect(repository.limit, 6);
      final visible = count < 3 ? count : 2;
      expect(find.byType(Card), findsNWidgets(visible));
      if (count > 2) {
        expect(find.text('더보기'), findsOneWidget);
        await tester.tap(find.text('더보기'));
        await tester.pump();
        expect(find.byType(Card), findsNWidgets(count > 6 ? 6 : count));
        expect(find.text('접기'), findsOneWidget);
      } else {
        expect(find.text('더보기'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Guest Home recent views performs no personal read', (
    tester,
  ) async {
    final repository = RecentRepository(7);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus(null)),
          ),
          recentViewRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: PersonalMaterialList(
              kind: PersonalListKind.recentViews,
              homeMode: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(repository.reads, 0);
    expect(find.text('로그인하면 이 기능을 이용할 수 있어요.'), findsOneWidget);
  });
}

ContentItem content(int index) => ContentItem(
  id: 'content-$index',
  slug: 'content-$index',
  contentType: 'education_column',
  title: '자료 $index',
  sourceUrl: 'https://legendstudy.com/content-$index',
  isActive: true,
);

class RecentContentRepository implements ContentRepository {
  RecentContentRepository(this.items);
  final List<ContentItem> items;
  int? limit;

  @override
  Future<List<ContentItem>> fetchRecentContent({int limit = 30}) async {
    this.limit = limit;
    return items.take(limit).toList();
  }

  @override
  Future<List<ContentItem>> searchContent(
    String query, {
    int limit = 30,
    String? contentType,
  }) async => items;

  @override
  Future<ContentItem?> fetchContentBySlug(String slug) async => null;

  @override
  Future<List<ContentItem>> fetchContentByIds(List<String> ids) async =>
      items.where((item) => ids.contains(item.id)).toList();
}

class RecentRepository implements RecentViewRepository {
  RecentRepository(int count)
    : entries = List.generate(
        count,
        (index) => PersonalContentEntry(
          id: 'recent-$index',
          contentItemId: 'content-$index',
          timestamp: DateTime.utc(2026, 9, 16, 12, 0 - index),
        ),
      );
  final List<PersonalContentEntry> entries;
  int reads = 0;
  int? limit;

  @override
  Future<List<PersonalContentEntry>> fetchOwnRecentViews({
    int limit = 100,
  }) async {
    reads++;
    this.limit = limit;
    return entries.take(limit).toList();
  }

  @override
  Future<void> touchRecentView(String contentItemId) async {}

  @override
  Future<void> deleteRecentView(String contentItemId) async {}

  @override
  Future<void> deleteAllRecentViews() async {}
}
