import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:legendstudy_app/app/navigation_shell.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/brand/brand_frame.dart';
import 'package:legendstudy_app/features/brand/brand_wordmark.dart';
import 'package:legendstudy_app/features/home/guide/home_menu_guide.dart';
import 'package:legendstudy_app/features/learning/learning_repository.dart';
import 'package:legendstudy_app/features/learning/learning_widgets.dart';
import 'package:legendstudy_app/features/learning/school_rank_feed.dart';
import 'package:legendstudy_app/features/learning/study_percentile.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';

import 'learning_integration_test.dart'
    show school, SelectedSchool, row, ranking;
import 'core_ux_test.dart' as preview;

Map<String, Object?> rankPage(
  Map<String, dynamic> params, {
  bool next = false,
  int start = 1,
  int count = 10,
  bool outside = false,
}) => {
  'version': 'student-school-ranking-page-v1',
  'period': params['p_period'] ?? 'all',
  'metric': params['p_metric'] ?? 'total',
  'scope': params['p_scope'] ?? 'ranked',
  'offset': params['p_offset'] ?? 0,
  'limit': 10,
  'as_of': params['p_as_of'] ?? '2026-11-12T00:00:00Z',
  'revision': 'public-projection-test',
  'min_recorders': 3,
  'min_rank_recorders': 3,
  'rows': List.generate(count, (i) => row(start + i, 1, ms: 3600000)),
  'my_school': outside ? null : row(12, 1, own: true, ms: 3600000),
  'next_offset': next ? (params['p_offset'] as int? ?? 0) + 10 : null,
  'unranked_next_offset': null,
  'unranked': outside
      ? [
          {
            'office_code': 'B10',
            'school_code': '100',
            'rank': null,
            'ms': null,
            'avg_ms': null,
            'active_users': null,
          },
          {
            'office_code': 'B10',
            'school_code': '12',
            'rank': null,
            'ms': null,
            'avg_ms': null,
            'active_users': 2,
          },
        ]
      : [],
};

Map<String, Object?> percentile({String status = 'ready'}) => {
  'version': 'study-percentile-v1',
  'source': 'completed_synced_sessions',
  'method': 'ceil_tie_upper_bound',
  'as_of': '2026-11-12T00:00:00Z',
  'minimum_sample': 20,
  'status': status,
  'population': status == 'ready' ? 40 : null,
  'rank': status == 'ready' ? 1 : null,
  'tie_count': status == 'ready' ? 3 : null,
  'top_percent': status == 'ready' ? 8 : null,
};

void screen(WidgetTester t, {double width = 360, double height = 780}) {
  t.view.physicalSize = Size(width, height);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.resetPhysicalSize);
  addTearDown(t.view.resetDevicePixelRatio);
}

Widget app(Widget child, {double scale = 1}) => MaterialApp(
  theme: AppTheme.light.copyWith(
    chipTheme: AppTheme.light.chipTheme.copyWith(
      labelStyle: AppTheme.light.chipTheme.labelStyle?.copyWith(
        fontFamily: 'CorePreview',
      ),
    ),
    textTheme: AppTheme.light.textTheme.apply(fontFamily: 'CorePreview'),
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: RepaintBoundary(key: preview.frame, child: child),
);

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CORE_RENDER')) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader('CorePreview')..addFont(
            File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
      await (FontLoader(
        'Pretendard',
      )..addFont(rootBundle.load('fonts/Pretendard-SemiBold.otf'))).load();
    }
  });

  test('rank page validates snapshot, filter, limits and unranked masking', () {
    final valid = rankPage({}, outside: true);
    expect(
      SchoolRankPage.parse(
        valid,
        defaultRankQuery,
        'ranked',
        0,
      ).outside.first.active,
      isNull,
    );
    for (final patch in [
      {'version': 'bad'},
      {'period': 'week'},
      {'metric': 'participation'},
      {'scope': 'unranked'},
      {'offset': 10},
      {'limit': 20},
      {'as_of': 'bad'},
      {'revision': null},
      {'next_offset': 1},
      {'rows': List.generate(11, (i) => row(i, 1))},
      {
        'unranked': [row(1, 1)],
      },
    ]) {
      expect(
        () => SchoolRankPage.parse(
          {...valid, ...patch},
          defaultRankQuery,
          'ranked',
          0,
        ),
        throwsA(isA<LearningFailure>()),
      );
    }
  });
  test('missing additive RPC preserves old TOP10; ordinary network errors do not fallback', () async {
    final calls = <String>[];
    final repo = SchoolRankPageRepository((n, p) async {
      calls.add(n);
      if (n == 'student_school_ranking_page') {
        throw const PostgrestException(message: 'missing', code: 'PGRST202');
      }
      return ranking(
        defaultRankQuery,
        top: [row(1, 1)],
        around: [row(12, 11)],
        mine: row(12, 11),
      );
    });
    final page = await repo.load(defaultRankQuery);
    expect(page.legacy, true);
    expect(page.nextOffset, isNull);
    expect(page.around.single.rank, 11);
    expect(calls, ['student_school_ranking_page', 'student_school_ranking']);
    var errors = 0;
    await expectLater(
      SchoolRankPageRepository((n, p) async {
        errors++;
        throw const PostgrestException(message: 'timeout', code: '57014');
      }).load(defaultRankQuery),
      throwsA(isA<PostgrestException>()),
    );
    expect(errors, 1);
  });
  test('page loading preserves snapshot/ties, deduplicates, prevents concurrent requests and retries', () async {
    var calls = 0;
    final pending = Completer<Object?>();
    var fail = true;
    final container = ProviderContainer(
      overrides: [
        schoolSelectionProvider.overrideWith(() => SelectedSchool(school)),
        schoolRankPageRepositoryProvider.overrideWithValue(
          SchoolRankPageRepository((n, p) async {
            calls++;
            if (p['p_offset'] == 0) return rankPage(p, next: true);
            expect(p['p_as_of'], '2026-11-12T00:00:00Z');
            expect(p['p_revision'], 'public-projection-test');
            if (fail) return pending.future;
            return rankPage(p, start: 10, count: 10);
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(
      schoolRankFeedProvider(defaultRankQuery),
      (_, _) {},
    );
    addTearDown(sub.close);
    await container.read(schoolRankFeedProvider(defaultRankQuery).future);
    final controller = container.read(
      schoolRankFeedProvider(defaultRankQuery).notifier,
    );
    final work = controller.more();
    await controller.more();
    expect(calls, 2);
    expect(
      container
          .read(schoolRankFeedProvider(defaultRankQuery))
          .value!
          .page
          .rows
          .length,
      10,
    );
    pending.completeError(Exception('offline'));
    await work;
    expect(
      container
          .read(schoolRankFeedProvider(defaultRankQuery))
          .value!
          .moreFailed,
      true,
    );
    fail = false;
    await controller.more();
    final page = container
        .read(schoolRankFeedProvider(defaultRankQuery))
        .value!
        .page;
    expect(page.rows.length, 19);
    expect(page.rows.every((r) => r.rank == 1), true);
    expect(page.nextOffset, isNull);
    await controller.refresh();
    expect(
      container
          .read(schoolRankFeedProvider(defaultRankQuery))
          .value!
          .page
          .rows
          .length,
      10,
    );
  });
  test('snapshot revision conflict keeps rows and asks refresh', () async {
    final c = ProviderContainer(
      overrides: [
        schoolSelectionProvider.overrideWith(() => SelectedSchool(school)),
        schoolRankPageRepositoryProvider.overrideWithValue(
          SchoolRankPageRepository((n, p) async {
            if (p['p_offset'] == 0) return rankPage(p, next: true);
            throw const PostgrestException(message: 'changed', code: 'PT409');
          }),
        ),
      ],
    );
    addTearDown(c.dispose);
    final sub = c.listen(schoolRankFeedProvider(defaultRankQuery), (_, _) {});
    addTearDown(sub.close);
    await c.read(schoolRankFeedProvider(defaultRankQuery).future);
    await c.read(schoolRankFeedProvider(defaultRankQuery).notifier).more();
    expect(
      c.read(schoolRankFeedProvider(defaultRankQuery)).value!.changed,
      true,
    );
    expect(
      c.read(schoolRankFeedProvider(defaultRankQuery)).value!.page.rows.length,
      10,
    );
  });
  test(
    'late pagination response cannot reintroduce a previous school',
    () async {
      final schoolState = StateProviderForTest(school);
      final pending = Completer<Object?>();
      final c = ProviderContainer(
        overrides: [
          schoolSelectionProvider.overrideWith(() => schoolState),
          schoolRankPageRepositoryProvider.overrideWithValue(
            SchoolRankPageRepository(
              (n, p) async =>
                  p['p_offset'] == 0 ? rankPage(p, next: true) : pending.future,
            ),
          ),
        ],
      );
      addTearDown(c.dispose);
      final sub = c.listen(schoolRankFeedProvider(defaultRankQuery), (_, _) {});
      addTearDown(sub.close);
      await c.read(schoolRankFeedProvider(defaultRankQuery).future);
      final work = c
          .read(schoolRankFeedProvider(defaultRankQuery).notifier)
          .more();
      schoolState.clear();
      await Future<void>.delayed(Duration.zero);
      pending.complete(rankPage({'p_offset': 10}, start: 11));
      await work;
      expect(c.read(schoolRankFeedProvider(defaultRankQuery)).hasError, true);
    },
  );

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'rank filters/ten-row increments/outside/privacy at 360px scale $scale',
      (t) async {
        screen(t);
        final requests = <Map<String, dynamic>>[];
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (_) => Stream.value(const AuthStatus('A')),
              ),
              schoolSelectionProvider.overrideWith(
                () => SelectedSchool(school),
              ),
              schoolRankPageRepositoryProvider.overrideWithValue(
                SchoolRankPageRepository((n, p) async {
                  requests.add(p);
                  final offset = p['p_offset'] as int;
                  return rankPage(
                    p,
                    start: offset + 1,
                    count: offset == 20 ? 3 : 10,
                    next: offset < 20,
                    outside: offset == 0,
                  );
                }),
              ),
              rankSchoolNameProvider.overrideWith(
                (_, k) async => '테스트 ${k.$2}고등학교',
              ),
            ],
            child: app(const SchoolRankingPage(), scale: scale),
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        final chips = t
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .toList();
        expect((chips[0].label as Text).data, '총 공부 시간');
        expect(chips[0].selected, true);
        expect(chips[0].side!.width, 1.75);
        expect(chips[0].elevation, 2);
        expect(find.byType(RankTile), findsNWidgets(10));
        expect(find.text('참여 학생 수 비공개'), findsOneWidget);
        expect(find.text('참여 학생 2명'), findsOneWidget);
        expect(find.textContaining('공동 순위와 표시 순서'), findsNothing);
        await preview.capture(t, 'post-rc-ranking-$scale');
        for (final count in [20, 23]) {
          final more = find.byKey(const ValueKey('rank-load-more'));
          await t.ensureVisible(more);
          await t.tap(more);
          await t.pumpAndSettle();
          expect(find.byType(RankTile), findsNWidgets(count));
        }
        expect(find.byKey(const ValueKey('rank-load-more')), findsNothing);
        final period = find.widgetWithText(ChoiceChip, '이번 주');
        await t.ensureVisible(period);
        await t.tap(period);
        await t.pumpAndSettle();
        expect(requests.last['p_offset'], 0);
        expect(requests.last['p_period'], 'week');
        final metric = find.widgetWithText(ChoiceChip, '참여 학생 수');
        await t.ensureVisible(metric);
        await t.tap(metric);
        await t.pumpAndSettle();
        expect(requests.last['p_period'], 'week');
        expect(requests.last['p_metric'], 'participation');
        expect(find.byType(RankTile), findsNWidgets(10));
        expect(t.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'home card uses same all/total feed and 16dp padding plus 1dp border',
    (t) async {
      screen(t);
      var calls = 0;
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (_) => Stream.value(const AuthStatus('A')),
            ),
            schoolSelectionProvider.overrideWith(() => SelectedSchool(school)),
            schoolRankPageRepositoryProvider.overrideWithValue(
              SchoolRankPageRepository((n, p) async {
                calls++;
                if (calls > 1) throw const LearningFailure();
                expect(p['p_metric'], 'total');
                expect(p['p_period'], 'all');
                return rankPage(p);
              }),
            ),
          ],
          child: app(const Scaffold(body: HomeSchoolRankCard())),
        ),
      );
      await t.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('1위'), findsOneWidget);
      expect(
        t.getTopLeft(find.text('학교별 공부 순위')).dx -
            t.getTopLeft(find.byType(HomeSchoolRankCard)).dx,
        17,
      );
      expect(t.widget<Text>(find.text('학교별 공부 순위')).style!.fontSize, 18);
      await preview.capture(t, 'post-rc-home-rank');
      final container = ProviderScope.containerOf(
        t.element(find.byType(HomeSchoolRankCard)),
      );
      await container
          .read(schoolRankFeedProvider(defaultRankQuery).notifier)
          .refresh();
      await t.pumpAndSettle();
      expect(find.text('1위'), findsNothing);
      expect(find.text('학교별 공부 순위'), findsOneWidget);
      expect(
        container
            .read(schoolRankFeedProvider(defaultRankQuery))
            .value!
            .page
            .rows
            .length,
        10,
      );
    },
  );

  test(
    'percentile rejects fabricated or malformed values; no local calculation',
    () {
      expect(StudyPercentile.parse(percentile()).topPercent, 8);
      for (final patch in [
        {'top_percent': 0},
        {'top_percent': 101},
        {'population': 19},
        {'rank': 0},
        {'tie_count': 0},
        {'rank': 40, 'tie_count': 2},
        {'status': 'ready', 'top_percent': null},
        {'method': 'estimate'},
        {'status': 'no_records'},
        {'as_of': 'invalid'},
      ]) {
        expect(
          () => StudyPercentile.parse({...percentile(), ...patch}),
          throwsA(isA<LearningFailure>()),
        );
      }
    },
  );
  for (final status in ['no_records', 'insufficient_sample', 'ready']) {
    testWidgets('personal percentile state $status', (t) async {
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            studyPercentileProvider.overrideWith(
              (_) async => StudyPercentile.parse(percentile(status: status)),
            ),
          ],
          child: app(
            const Scaffold(body: StudyPercentileCard(allTime: 3600000)),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(
        find.text(
          status == 'ready'
              ? '🏆 나의 공부시간은 상위 8%'
              : status == 'no_records'
              ? '나의 공부시간은 상위 몇 %일까?'
              : '공부 기록이 더 모이면 나의 학습 순위를 알려드릴게요.',
        ),
        findsOneWidget,
      );
    });
  }
  testWidgets(
    'zero total does not request server percentile or add start button',
    (t) async {
      var calls = 0;
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            studyPercentileProvider.overrideWith((_) async {
              calls++;
              throw Exception();
            }),
          ],
          child: app(const Scaffold(body: StudyPercentileCard(allTime: 0))),
        ),
      );
      await t.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('나의 공부시간은 상위 몇 %일까?'), findsOneWidget);
      expect(find.byType(FilledButton), findsNothing);
    },
  );
  testWidgets(
    'percentile loading/failure/retry and missing RPC never invent value',
    (t) async {
      final pending = Completer<StudyPercentile>();
      var calls = 0;
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            studyPercentileProvider.overrideWith((_) async {
              calls++;
              return calls == 1
                  ? pending.future
                  : StudyPercentile.parse(percentile());
            }),
          ],
          child: app(const Scaffold(body: StudyPercentileCard(allTime: 1))),
        ),
      );
      await t.pump();
      expect(find.text('나의 공부시간 순위를 계산하고 있어요.'), findsOneWidget);
      pending.completeError(Exception('offline'));
      await t.pumpAndSettle();
      expect(find.text('🏆 나의 공부시간은 상위 8%'), findsNothing);
      await t.tap(find.text('순위 다시 확인'));
      await t.pumpAndSettle();
      expect(find.text('🏆 나의 공부시간은 상위 8%'), findsOneWidget);
    },
  );

  test('guide excludes existing users, persists claim before display and survives restart', () async {
    SharedPreferences.setMockInitialValues({});
    final now = DateTime.utc(2026, 11, 12);
    final store = (await HomeGuideStore.initialize(
      now: now,
      freshGuest: false,
    ))!;
    expect(store.eligible(guest: true), false);
    expect(
      store.eligible(
        guest: false,
        accountCreatedAt: now.subtract(const Duration(days: 1)),
      ),
      false,
    );
    expect(store.eligible(guest: false), false);
    expect(
      store.eligible(
        guest: false,
        accountCreatedAt: now.add(const Duration(minutes: 1)),
      ),
      true,
    );
    expect(await store.claim(), true);
    expect(await store.claim(), false);
    final restarted = (await HomeGuideStore.initialize(
      now: now.add(const Duration(days: 1)),
      freshGuest: true,
    ))!;
    expect(restarted.eligible(guest: true), false);
    expect(
      restarted.eligible(
        guest: false,
        accountCreatedAt: now.add(const Duration(days: 2)),
      ),
      false,
    );
  });
  test(
    'guide fresh guest eligible; existing intro install is never new guest',
    () async {
      SharedPreferences.setMockInitialValues({});
      final now = DateTime.utc(2026, 11, 12);
      final fresh = (await HomeGuideStore.initialize(
        now: now,
        freshGuest: true,
      ))!;
      expect(fresh.eligible(guest: true), true);
      await fresh.claim();
      expect(fresh.eligible(guest: true), false);
    },
  );
  for (final size in [const Size(320, 568), const Size(440, 956)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'native menu guide five real targets ${size.width}px scale $scale',
        (t) async {
          screen(t, width: size.width, height: size.height);
          SharedPreferences.setMockInitialValues({});
          final store = (await HomeGuideStore.initialize(
            now: DateTime.now(),
            freshGuest: true,
          ))!;
          final routes = ['/home', '/materials', '/study', '/lab', '/my'];
          final router = GoRouter(
            initialLocation: '/home',
            routes: [
              StatefulShellRoute.indexedStack(
                builder: (_, _, shell) => NavigationShell(shell: shell),
                branches: routes
                    .map(
                      (p) => StatefulShellBranch(
                        routes: [
                          GoRoute(
                            path: p,
                            builder: (_, _) => Center(child: Text('실제 화면 $p')),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ],
          );
          addTearDown(router.dispose);
          await t.pumpWidget(
            ProviderScope(
              overrides: [
                authStateProvider.overrideWith(
                  (_) => Stream.value(const AuthStatus(null)),
                ),
                homeGuideStoreProvider.overrideWithValue(store),
                homeGuideEligibleProvider.overrideWith(
                  (_) => store.eligible(guest: true),
                ),
              ],
              child: MaterialApp.router(
                routerConfig: router,
                theme: AppTheme.light.copyWith(
                  textTheme: AppTheme.light.textTheme.apply(
                    fontFamily: 'CorePreview',
                  ),
                ),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    padding: const EdgeInsets.only(top: 44, bottom: 34),
                  ),
                  child: RepaintBoundary(key: preview.frame, child: child!),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(find.byType(HomeMenuGuide), findsOneWidget);
          expect(await store.claim(), false);
          expect(find.byType(NavigationDestination), findsNWidgets(5));
          for (var i = 0; i < 5; i++) {
            expect(find.text(homeGuideSteps[i].description), findsOneWidget);
            expect(t.takeException(), isNull);
            await preview.capture(
              t,
              'post-rc-guide-${size.width.toInt()}-$scale-$i',
            );
            final cta = find.text(i == 4 ? '시작하기' : '다음');
            await t.ensureVisible(cta);
            await t.tap(cta);
            await t.pumpAndSettle();
            expect(router.routeInformationProvider.value.uri.path, '/home');
          }
          expect(find.byType(HomeMenuGuide), findsNothing);
          await t.tap(find.byIcon(Icons.timer_outlined));
          await t.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, '/study');
          router.go('/home');
          await t.pumpAndSettle();
          expect(find.byType(HomeMenuGuide), findsNothing);
        },
      );
    }
  }
  testWidgets('guide skip immediately exits without changing navigation', (
    t,
  ) async {
    var closed = false;
    final keys = List.generate(5, (_) => GlobalKey());
    await t.pumpWidget(
      app(
        StatefulBuilder(
          builder: (context, setState) => Stack(
            children: [
              Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  children: [
                    for (final k in keys)
                      Expanded(child: SizedBox(key: k, height: 80)),
                  ],
                ),
              ),
              if (!closed)
                Positioned.fill(
                  child: HomeMenuGuide(
                    targets: keys,
                    onDone: () => setState(() => closed = true),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.text('건너뛰기'));
    await t.pumpAndSettle();
    expect(closed, true);
  });
  for (final size in [const Size(320, 568), const Size(440, 956)]) {
    testWidgets('splash lockup upper third/navy plus/safe area ${size.width}', (
      t,
    ) async {
      screen(t, width: size.width, height: size.height);
      await t.pumpWidget(app(const BrandSplashFrame()));
      await t.pumpAndSettle();
      final symbol = find.byKey(const ValueKey('brand-visible-symbol'));
      final word = find.byType(BrandWordmark);
      expect(
        t.getTopLeft(word).dy - t.getBottomLeft(symbol).dy,
        closeTo(20, 0.1),
      );
      expect(
        (t.getTopLeft(symbol).dy + t.getBottomLeft(word).dy) / 2,
        closeTo(size.height / 3, 1),
      );
      expect(t.widget<BrandWordmark>(word).plusColor, BrandWordmark.brandNavy);
      expect(t.takeException(), isNull);
      await preview.capture(t, 'post-rc-splash-${size.width.toInt()}');
    });
  }
}

class StateProviderForTest extends SelectedSchool {
  StateProviderForTest(super.school);
  void clear() => state = const AsyncData(null);
}
