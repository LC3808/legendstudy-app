import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/content/data/supabase_content_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('LegendStudy anonymous empty-database smoke', (tester) async {
    final config = AppConfig.fromEnvironment();
    expect(
      config.validationErrors,
      isEmpty,
      reason: 'Inject local public configuration; never credentials in source.',
    );
    final transport = _ReadOnlyTransport();
    addTearDown(transport.close);
    await Supabase.initialize(
      httpClient: transport,
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
      debug: false,
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        autoRefreshToken: false,
      ),
    );
    debugPrint('SMOKE: initialized');
    final client = Supabase.instance.client;
    addTearDown(() => Supabase.instance.dispose());
    expect(client.auth.currentSession, isNull);
    final rows = await SupabaseContentRepository(
      client,
    ).fetchRecentContent().timeout(const Duration(seconds: 30));
    debugPrint('SMOKE: public read complete');
    expect(
      rows,
      isEmpty,
      reason:
          'Day 3 fixtures were cleaned up; no seed is inserted by this test.',
    );
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        supabaseClientProvider.overrideWithValue(client),
        backendIssueProvider.overrideWithValue(null),
      ],
    );
    addTearDown(container.dispose);
    // Match a mounted UI consumer: keep the stream actively observed while waiting.
    final authSubscription = container.listen(authStateProvider, (_, _) {});
    addTearDown(authSubscription.close);
    expect(
      (await container
              .read(authStateProvider.future)
              .timeout(const Duration(seconds: 15)))
          .isAuthenticated,
      isFalse,
    );
    debugPrint('SMOKE: signedOut confirmed');
    final beforePersonal = transport.requestCount;
    final profile = container.read(profileRepositoryProvider);
    final bookmarks = container.read(bookmarkRepositoryProvider);
    final recent = container.read(recentViewRepositoryProvider);
    expect(await profile.fetchCurrentProfile(), isNull);
    expect(await bookmarks.fetchOwnBookmarks(), isEmpty);
    expect(await bookmarks.isBookmarked('not-sent'), isFalse);
    expect(await recent.fetchOwnRecentViews(), isEmpty);
    await expectLater(
      profile.upsertCurrentProfile(),
      throwsA(isA<SignedOutException>()),
    );
    await expectLater(
      bookmarks.addBookmark('not-sent'),
      throwsA(isA<SignedOutException>()),
    );
    await expectLater(
      bookmarks.deleteBookmark('not-sent'),
      throwsA(isA<SignedOutException>()),
    );
    await expectLater(
      recent.touchRecentView('not-sent'),
      throwsA(isA<SignedOutException>()),
    );
    expect(transport.requestCount, beforePersonal);

    // Gate transport dispatch only to observe loading deterministically.
    // Responses still come from the actual server, with no fixture/fake data.
    transport.gate = Completer<void>();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LegendStudyApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    transport.gate!.complete();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 45),
    );
    expect(find.text('아직 등록된 자료가 없어요.'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsNothing);

    await tester.ensureVisible(find.text('모의고사, 논술, 학습자료 검색'));
    await tester.tap(find.text('모의고사, 논술, 학습자료 검색'));
    await tester.pumpAndSettle();
    expect(find.text('검색어를 입력해 주세요.'), findsOneWidget);
    transport.gate = Completer<void>();
    await tester.enterText(find.byType(TextField), '영어');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    transport.gate!.complete();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 45),
    );
    expect(find.text('검색 결과가 없어요.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(transport.requestCount, 3);
    expect(transport.statuses, everyElement(200));
    debugPrint(
      'SMOKE PASS: initialization; dedicated content GET x3 HTTP 200; '
      '0 rows; Home/Browse loading to empty; signedOut; personal calls no network.',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

/// Allows only public read requests and records status/count, never headers/tokens.
class _ReadOnlyTransport extends http.BaseClient {
  final http.Client _inner = http.Client();
  Completer<void>? gate;
  int requestCount = 0;
  final statuses = <int>[];
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method != 'GET' ||
        request.url.host != 'stlhijzpjfgwwdgunlsd.supabase.co' ||
        request.url.path != '/rest/v1/content_items') {
      throw StateError('Smoke transport rejected a non-public-read request.');
    }
    requestCount++;
    debugPrint('SMOKE: public GET dispatched');
    if (gate != null) await gate!.future;
    final response = await _inner.send(request);
    statuses.add(response.statusCode);
    debugPrint('SMOKE: public GET status ${response.statusCode}');
    return response;
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
