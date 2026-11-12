// Isolated native UI smoke. No Supabase initialization, HTTP, login, production
// records or installed-user preferences. This is not live-service acceptance.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legendstudy_app/app/navigation_shell.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/brand/brand_frame.dart';
import 'package:legendstudy_app/features/home/guide/home_menu_guide.dart';
import 'package:legendstudy_app/features/learning/learning_repository.dart';
import 'package:legendstudy_app/features/learning/learning_widgets.dart';
import 'package:legendstudy_app/features/learning/school_rank_feed.dart';
import 'package:legendstudy_app/features/learning/study_percentile.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';

import '../test/app82_post_rc_ux_test.dart' show rankPage, percentile;
import '../test/learning_integration_test.dart' show SelectedSchool, school;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Post-RC native isolated UI (no live backend)', (t) async {
    var surfaceConverted = false;
    Future<void> capture(String name) async {
      // Real devices raster asynchronously after the widget tree settles.
      // Allow the final animation/image frame to reach the native compositor.
      await t.pump(const Duration(milliseconds: 350));
      await t.pumpAndSettle();
      if (Platform.isAndroid && !surfaceConverted) {
        await binding.convertFlutterSurfaceToImage();
        surfaceConverted = true;
        await t.pump();
      }
      await binding.takeScreenshot(name);
    }

    await t.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const BrandSplashFrame()),
    );
    await t.pumpAndSettle();
    await t.runAsync(
      () => precacheImage(
        const AssetImage('assets/brand/generated/legendstudy_symbol.png'),
        t.element(find.byType(BrandSplashFrame)),
      ),
    );
    await t.pumpAndSettle();
    await capture('post-rc-native-splash');
    SharedPreferences.setMockInitialValues({});
    final store = (await HomeGuideStore.initialize(
      now: DateTime.now(),
      freshGuest: true,
    ))!;
    final routes = ['/home', '/materials', '/study', '/lab', '/my'];
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/study/schools',
          builder: (_, _) => const SchoolRankingPage(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => NavigationShell(shell: shell),
          branches: routes
              .map(
                (p) => StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: p,
                      builder: (_, _) => ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          const Text('격리 UI 검증 · 실제 회원 데이터 아님'),
                          if (p == '/home') const HomeSchoolRankCard(),
                          if (p == '/study') ...[
                            const StudySummaryMetrics(
                              today: 3600000,
                              week: 7200000,
                              allTime: 36000000,
                            ),
                            const SizedBox(height: 16),
                            const StudyPercentileCard(allTime: 36000000),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    );
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (_) => Stream.value(const AuthStatus('isolated-fixture')),
          ),
          schoolSelectionProvider.overrideWith(() => SelectedSchool(school)),
          rankSchoolNameProvider.overrideWith(
            (_, key) async => '검증 ${key.$2}고등학교',
          ),
          schoolRankPageRepositoryProvider.overrideWithValue(
            SchoolRankPageRepository((_, p) async {
              final offset = p['p_offset'] as int;
              return rankPage(
                p,
                start: offset + 1,
                count: 10,
                next: offset == 0,
                outside: offset == 0,
              );
            }),
          ),
          studyPercentileProvider.overrideWith(
            (_) async => StudyPercentile.parse(percentile()),
          ),
          homeGuideStoreProvider.overrideWithValue(store),
          homeGuideEligibleProvider.overrideWith(
            (_) => store.eligible(guest: true),
          ),
        ],
        child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
      ),
    );
    await t.pumpAndSettle();
    for (
      var attempt = 0;
      attempt < 50 && find.byType(HomeMenuGuide).evaluate().isEmpty;
      attempt++
    ) {
      await t.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(HomeMenuGuide), findsOneWidget);
    await capture('post-rc-native-guide');
    for (var i = 0; i < 5; i++) {
      final cta = find.text(i == 4 ? '시작하기' : '다음');
      await t.ensureVisible(cta);
      await t.tap(cta);
      await t.pumpAndSettle();
    }
    expect(find.byType(HomeMenuGuide), findsNothing);
    await capture('post-rc-native-home');
    await t.tap(find.text('학교별 공부 순위'));
    await t.pumpAndSettle();
    expect(find.byType(RankTile), findsNWidgets(10));
    await capture('post-rc-native-ranking');
    final more = find.byKey(const ValueKey('rank-load-more'));
    await t.ensureVisible(more);
    await t.tap(more);
    await t.pumpAndSettle();
    expect(find.byType(RankTile), findsNWidgets(20));
    expect(find.byKey(const ValueKey('rank-load-more')), findsNothing);
    router.pop();
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.timer_outlined));
    await t.pumpAndSettle();
    expect(find.text('🏆 나의 공부시간은 상위 8%'), findsOneWidget);
    await capture('post-rc-native-percentile');
    router.go('/home');
    await t.pumpAndSettle();
    expect(find.byType(HomeMenuGuide), findsNothing);
    expect(t.takeException(), isNull);
    (binding.reportData ??= {}).addAll({
      'isolated': true,
      'production_calls': 0,
      'checks': [
        'splash',
        'guide_5_steps',
        'home_rank',
        'rank_10_20',
        'percentile',
        'guide_not_repeated',
      ],
    });
    await t.pumpWidget(const SizedBox());
    router.dispose();
  });
}
