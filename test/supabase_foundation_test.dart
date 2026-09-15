import 'support/search_fake.dart';
import 'package:legendstudy_app/features/materials/application/search_controller.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';
import 'package:legendstudy_app/features/content/presentation/content_results.dart';
import 'package:legendstudy_app/features/content/domain/content_item.dart';
import 'package:legendstudy_app/features/content/domain/content_repository.dart';
import 'package:legendstudy_app/features/content/data/supabase_content_repository.dart';
import 'package:legendstudy_app/features/personal/data/supabase_personal_repositories.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';

final sample = <String, dynamic>{
  'id': 'content-1',
  'slug': 'study-example',
  'content_type': 'education_column',
  'title': '학습 안내',
  'summary': null,
  'source_url': 'https://legendstudy.com/1',
  'published_at': null,
  'source_updated_at': '2026-09-13T01:00:00Z',
  'feed_updated_at': '2026-09-13T01:00:00Z',
  'thumbnail_url': null,
  'is_active': true,
};

class FakeContentRepository implements ContentRepository {
  Future<List<ContentItem>> response = Future.value([]);
  String? lastQuery;
  @override
  Future<List<ContentItem>> fetchRecentContent({int limit = 30}) => response;
  @override
  Future<List<ContentItem>> searchContent(
    String query, {
    int limit = 30,
    String? contentType,
  }) {
    lastQuery = query;
    return response;
  }

  @override
  Future<ContentItem?> fetchContentBySlug(String slug) async => null;
}

void main() {
  late SupabaseClient client;
  late List<http.Request> requests;
  late String responseBody;
  late int status;
  setUp(() {
    requests = [];
    responseBody = '[]';
    status = 200;
    client = SupabaseClient(
      'https://example.invalid',
      'test-public-client',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          responseBody,
          status,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      }),
    );
  });
  tearDown(() => client.dispose());
  Future<void> signInFixture() => client.auth.setInitialSession(
    jsonEncode({
      // Nonfunctional synthetic strings; no real JWT, password or remote login.
      'access_token': 'unit-test-token', 'refresh_token': 'unit-test-refresh',
      'token_type': 'bearer', 'expires_in': 3600,
      'user': {
        'id': 'owner-a',
        'app_metadata': <String, dynamic>{},
        'user_metadata': <String, dynamic>{},
        'aud': 'authenticated',
        'created_at': '2026-09-13T00:00:00Z',
      },
    }),
  );
  test('public model parses nullable dates and general content type', () {
    final item = ContentItem.fromJson(sample);
    expect(item.contentType, 'education_column');
    expect(item.summary, isNull);
    expect(item.publishedAt, isNull);
    expect(item.feedUpdatedAt!.isUtc, isTrue);
    expect(item.sourceUrl, 'https://legendstudy.com/1');
  });
  test('missing and invalid config fails clearly without exposing key', () {
    expect(const AppConfig().validationErrors, hasLength(2));
    const config = AppConfig(
      supabaseUrl: 'http://wrong.invalid',
      supabasePublishableKey: 'server-only-test',
    );
    expect(config.validationErrors, hasLength(2));
    expect(config.validationErrors.join(), isNot(contains('server-only-test')));
    expect(
      const AppConfig(
        supabaseUrl: 'https://stlhijzpjfgwwdgunlsd.supabase.co',
        supabasePublishableKey: 'sb_publishable_unit_test',
      ).validationErrors,
      isEmpty,
    );
  });
  test(
    'recent request uses exact projection, ordering and empty success',
    () async {
      expect(
        await SupabaseContentRepository(client).fetchRecentContent(limit: 12),
        isEmpty,
      );
      final q = requests.single.url.queryParameters;
      expect(q['select'], SupabaseContentRepository.projection);
      expect(q['is_active'], 'eq.true');
      expect(q['limit'], '12');
      expect(q['order'], 'feed_updated_at.desc.nullslast,id.desc.nullslast');
    },
  );
  test('content rows parse and missing slug returns null', () async {
    final repo = SupabaseContentRepository(client);
    responseBody = jsonEncode([sample]);
    expect((await repo.fetchRecentContent()).single.title, '학습 안내');
    responseBody = '[]';
    expect(await repo.fetchContentBySlug('absent'), isNull);
    expect(requests.last.url.queryParameters['slug'], 'eq.absent');
  });
  test(
    'empty search does not issue requests; multi-token search is bounded',
    () async {
      final repo = SupabaseContentRepository(client);
      expect(await repo.searchContent('  '), isEmpty);
      expect(requests, isEmpty);
      await repo.searchContent('영어 모의고사');
      expect(requests.single.url.queryParametersAll['or'], hasLength(2));
      expect(
        requests.single.url.queryParameters['select'],
        SupabaseContentRepository.projection,
      );
      await expectLater(repo.searchContent('*'), throwsFormatException);
      await expectLater(
        repo.fetchRecentContent(limit: 101),
        throwsArgumentError,
      );
    },
  );
  test('search quotes delimiters and escapes literal LIKE wildcards', () async {
    await SupabaseContentRepository(client).searchContent('50%_"x,y)');
    final filter = requests.single.url.queryParameters['or']!;
    // Decode the independently quoted first pattern, excluding wrapper/operator.
    final first = filter.substring(
      '(title.ilike.'.length,
      filter.indexOf(',summary.ilike.'),
    );
    final decoded = jsonDecode(first) as String;
    final slash = String.fromCharCode(92);
    expect(decoded, '%50$slash%${slash}_"x,y)%');
  });
  test('HTTP errors remain errors rather than empty/mock results', () async {
    status = 401;
    responseBody = jsonEncode({'message': 'denied', 'code': '42501'});
    await expectLater(
      SupabaseContentRepository(client).fetchRecentContent(),
      throwsA(isA<PostgrestException>()),
    );
  });
  test('client and repository providers can be overridden', () async {
    final container = ProviderContainer(
      overrides: [supabaseClientProvider.overrideWithValue(client)],
    );
    addTearDown(container.dispose);
    expect(await container.read(recentContentProvider.future), isEmpty);
    final fake = FakeContentRepository();
    final injected = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(fake),
        searchRepositoryProvider.overrideWithValue(LegacySearchFake(fake)),
      ],
    );
    addTearDown(injected.dispose);
    expect(await injected.read(recentContentProvider.future), isEmpty);
  });
  test(
    'signed-out personal reads and writes never contact the network',
    () async {
      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);
      final profile = container.read(profileRepositoryProvider);
      final bookmarks = container.read(bookmarkRepositoryProvider);
      final recent = container.read(recentViewRepositoryProvider);
      expect(await profile.fetchCurrentProfile(), isNull);
      expect(await bookmarks.fetchOwnBookmarks(), isEmpty);
      expect(await bookmarks.isBookmarked('content-1'), isFalse);
      expect(await recent.fetchOwnRecentViews(), isEmpty);
      await expectLater(
        profile.upsertCurrentProfile(),
        throwsA(isA<SignedOutException>()),
      );
      await expectLater(
        bookmarks.addBookmark('content-1'),
        throwsA(isA<SignedOutException>()),
      );
      await expectLater(
        bookmarks.deleteBookmark('content-1'),
        throwsA(isA<SignedOutException>()),
      );
      await expectLater(
        recent.touchRecentView('content-1'),
        throwsA(isA<SignedOutException>()),
      );
      expect(requests, isEmpty);
    },
  );
  test(
    'personal payloads use current identity and exact DB write contracts',
    () async {
      await signInFixture();
      await SupabaseProfileRepository(
        client,
      ).upsertCurrentProfile(displayName: '학생', gradeLevel: 3);
      expect(jsonDecode(requests.last.body), {
        'id': 'owner-a',
        'display_name': '학생',
        'grade_level': 3,
      });
      expect(requests.last.url.queryParameters['on_conflict'], 'id');
      final bookmarks = SupabaseBookmarkRepository(client);
      await bookmarks.addBookmark('content-1');
      expect(
        requests.last.headers['prefer'],
        contains('resolution=ignore-duplicates'),
      );
      expect(jsonDecode(requests.last.body), {
        'user_id': 'owner-a',
        'content_item_id': 'content-1',
      });
      await bookmarks.deleteBookmark('content-1');
      expect(requests.last.method, 'DELETE');
      expect(requests.last.url.queryParameters['user_id'], 'eq.owner-a');
      expect(
        requests.last.url.queryParameters['content_item_id'],
        'eq.content-1',
      );
      await SupabaseRecentViewRepository(client).touchRecentView('content-1');
      expect(jsonDecode(requests.last.body), {
        'user_id': 'owner-a',
        'content_item_id': 'content-1',
      });
      expect(
        requests.last.url.queryParameters['on_conflict'],
        'user_id,content_item_id',
      );
      expect(
        requests.last.headers['prefer'],
        contains('resolution=merge-duplicates'),
      );
    },
  );
  test(
    'auth status subscribes to initial session and signed-out transition',
    () async {
      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);
      final states = <AuthStatus>[];
      container.listen(authStateProvider, (_, next) {
        if (next.hasValue) states.add(next.requireValue);
      });
      await signInFixture();
      await Future<void>.delayed(Duration.zero);
      expect(states.last.userId, 'owner-a');
      responseBody = '{}';
      await client.auth.signOut(scope: SignOutScope.local);
      await Future<void>.delayed(Duration.zero);
      expect(states.last.isAuthenticated, isFalse);
      requests.clear();
      expect(
        await SupabaseBookmarkRepository(client).fetchOwnBookmarks(),
        isEmpty,
      );
      expect(requests, isEmpty);
    },
  );
  testWidgets('Home repository empty state and Browse query are injectable', (
    tester,
  ) async {
    final fake = FakeContentRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(fake),
          searchRepositoryProvider.overrideWithValue(LegacySearchFake(fake)),
        ],
        child: const LegendStudyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('아직 등록된 자료가 없어요.'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('자료 검색'));
    await tester.tap(find.byTooltip('자료 검색'));
    await tester.pumpAndSettle();
    expect(find.text('아직 등록된 자료가 없어요.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '영어');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(fake.lastQuery, '영어');
    expect(find.text('조건에 맞는 자료가 없어요.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.text('아직 등록된 자료가 없어요.'), findsOneWidget);
  });
  testWidgets('Home distinguishes loading, data, failure and retry', (
    tester,
  ) async {
    final fake = FakeContentRepository();
    final pending = Completer<List<ContentItem>>();
    fake.response = pending.future;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentRepositoryProvider.overrideWithValue(fake),
          searchRepositoryProvider.overrideWithValue(LegacySearchFake(fake)),
        ],
        child: const LegendStudyApp(),
      ),
    );
    await tester.pump();
    expect(
      find.descendant(
        of: find.byType(ContentResults),
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    pending.completeError(Exception('internal-test-detail'));
    await tester.pumpAndSettle();
    expect(find.text('자료를 불러오지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.textContaining('internal-test-detail'), findsNothing);
    fake.response = Future.value([ContentItem.fromJson(sample)]);
    await tester.ensureVisible(find.text('다시 시도'));
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('학습 안내'), findsOneWidget);
  });
  testWidgets('missing defines render clear config messages without a crash', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: LegendStudyApp()));
    await tester.pumpAndSettle();
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
