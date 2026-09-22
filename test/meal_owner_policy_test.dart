import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';
import 'package:legendstudy_app/features/school/presentation/home_meal_card.dart';
import 'package:legendstudy_app/features/profile/presentation/profile_page.dart';
import 'package:legendstudy_app/features/profile/presentation/settings_page.dart';
import 'package:legendstudy_app/shared/widgets/nested_page.dart';

import 'my_profile_state_test.dart' show Selection;
import 'day7_school_test.dart' show Schools, schoolA;

Meal m(String day, String type) =>
    Meal(date: day, mealType: type, menuItems: ['$day $type 메뉴']);
DateTime at(int hour, [int minute = 0]) =>
    DateTime.utc(2026, 9, 21, hour - 9, minute);

class RawMeals extends Schools {
  final queries = <String>[];
  @override
  Future<List<Meal>> meals(School school, String date) async {
    queries.add(date);
    return [m(date, '조식'), m(date, '중식')];
  }
}

void main() {
  for (final failure in [false, true]) {
    testWidgets('tomorrow ${failure ? 'error' : 'loading'} is not empty', (
      t,
    ) async {
      await t.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            schoolSelectionProvider.overrideWith(
              () => Selection(() => Future.value(schoolA)),
            ),
            koreanMealClockProvider.overrideWithValue(at(14)),
            mealBoundaryRefreshEnabledProvider.overrideWithValue(false),
            todayMealsProvider.overrideWith(
              (ref) async => [m('20260921', '중식')],
            ),
            tomorrowMealsProvider.overrideWith(
              (ref) => failure
                  ? Future<List<Meal>>.error(StateError('offline'))
                  : Completer<List<Meal>>().future,
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: HomeMealCard())),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 20));
      expect(find.text('등록된 중식·석식 정보가 없어요.'), findsNothing);
      expect(find.text('오늘 중식'), findsNothing);
      if (failure) {
        expect(find.text('급식 정보를 불러오지 못했어요.'), findsOneWidget);
      } else {
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      }
      await t.pumpWidget(const SizedBox());
    });
  }

  final tomorrow = [
    m('20260922', '조식'),
    m('20260922', '중식'),
    m('20260922', '석식'),
  ];
  for (final types in [
    ['중식'],
    ['조식', '중식'],
    ['중식', '석식'],
    ['조식', '중식', '석식'],
  ]) {
    for (final time in [
      (7, 59),
      (8, 0),
      (13, 59),
      (14, 0),
      (18, 59),
      (19, 0),
    ]) {
      test('$types KST ${time.$1}:${time.$2} breakfast excluded', () {
        final p = mealDisplayPlan(
          now: at(time.$1, time.$2),
          today: types.map((t) => m('20260921', t)).toList(),
          tomorrow: tomorrow,
        );
        final next = time.$1 >= 19 || (time.$1 >= 14 && !types.contains('석식'));
        expect(p.primaryIsTomorrow, next);
        expect(p.primary.single.mealType, !next && time.$1 >= 14 ? '석식' : '중식');
        expect(p.primary.single.date, next ? '20260922' : '20260921');
      });
    }
  }
  test('tomorrow dinner fallback, breakfast-only empty, no expired dinner fallback', () {
    final today = [m('20260921', '석식')];
    expect(
      mealDisplayPlan(
        now: at(19),
        today: today,
        tomorrow: [m('20260922', '석식')],
      ).primary.single.mealType,
      '석식',
    );
    expect(
      mealDisplayPlan(
        now: at(19),
        today: today,
        tomorrow: [m('20260922', '조식')],
      ).isEmpty,
      true,
    );
    expect(
      mealDisplayPlan(now: at(19), today: today, tomorrow: []).isEmpty,
      true,
    );
    expect(nextMealBoundary(at(13, 59)), at(14));
    expect(nextMealBoundary(at(14)), at(19));
    expect(nextMealBoundary(at(19)), at(24));
  });
  testWidgets(
    'Owner lunch-only 14 boundary and resume midnight query new dates',
    (t) async {
      var now = at(13, 59);
      final repo = RawMeals();
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            schoolSelectionProvider.overrideWith(
              () => Selection(() => Future.value(schoolA)),
            ),
            schoolRepositoryProvider.overrideWithValue(repo),
            mealNowProvider.overrideWithValue(() => now),
          ],
          child: const MaterialApp(home: Scaffold(body: HomeMealCard())),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('오늘 중식'), findsOneWidget);
      now = at(14);
      await t.pump(const Duration(minutes: 1));
      await t.pumpAndSettle();
      expect(find.text('내일 중식'), findsOneWidget);
      expect(find.text('9월 22일'), findsOneWidget);
      now = at(24);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pumpAndSettle();
      expect(find.text('오늘 중식'), findsOneWidget);
      expect(repo.queries, containsAll(['20260921', '20260922', '20260923']));
      expect(find.text('9월 22일'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'detail exposes breakfast and today after tomorrow preview at 2x',
    (t) async {
      t.view.physicalSize = const Size(360, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: MealSummary(
                now: at(19),
                meals: [m('20260921', '석식')],
                tomorrowMeals: tomorrow,
              ),
            ),
          ),
        ),
      );
      final semantics = t.ensureSemantics();

      expect(find.bySemanticsLabel(RegExp('급식 상세 펼치기')), findsOneWidget);
      expect(find.textContaining('조식'), findsNothing);
      await t.tap(find.text('내일 중식'));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel(RegExp('급식 상세 접기')), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.text('조식'), findsOneWidget);
      expect(find.text('중식'), findsOneWidget);
      expect(find.text('석식'), findsOneWidget);
      await t.tap(find.text('9월 21일 급식 보기'));
      await t.pumpAndSettle();
      expect(find.text('20260921 석식 메뉴'), findsOneWidget);
      await t.tap(find.text('오늘 급식'));
      await t.pumpAndSettle();
      expect(find.text('내일 중식'), findsOneWidget);
      expect(find.text('20260921 석식 메뉴'), findsNothing);
      semantics.dispose();
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'Home revisit reevaluates cached raw meals; midnight timer advances dates',
    (t) async {
      var now = at(13, 59);
      final active = ValueNotifier(true);
      addTearDown(active.dispose);
      final repo = RawMeals();
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            schoolSelectionProvider.overrideWith(
              () => Selection(() => Future.value(schoolA)),
            ),
            schoolRepositoryProvider.overrideWithValue(repo),
            mealNowProvider.overrideWithValue(() => now),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: active,
                builder: (_, enabled, _) =>
                    TickerMode(enabled: enabled, child: const HomeMealCard()),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      active.value = false;
      await t.pump();
      now = at(19);
      active.value = true;
      await t.pumpAndSettle();
      expect(find.text('내일 중식'), findsOneWidget);
      now = at(24);
      await t.pump(const Duration(hours: 5));
      await t.pumpAndSettle();
      expect(find.text('오늘 중식'), findsOneWidget);
      expect(find.text('9월 22일'), findsOneWidget);
      expect(repo.queries, contains('20260923'));
      await t.pumpWidget(const SizedBox());
    },
  );
  testWidgets('MY gear Settings back, actions absent from MY', (t) async {
    final router = GoRouter(
      initialLocation: '/my',
      routes: [
        GoRoute(
          path: '/my',
          builder: (_, _) => const ProfilePage(),
          routes: [
            GoRoute(
              path: 'settings',
              builder: (_, _) =>
                  const NestedPage(title: '설정', child: SettingsPage()),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    await t.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await t.pumpAndSettle();
    expect(find.text('앱 정보'), findsNothing);
    expect(find.text('개인정보처리방침'), findsNothing);
    expect(t.getSize(find.byTooltip('설정')).height, greaterThanOrEqualTo(48));
    await t.tap(find.byTooltip('설정'));
    await t.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.text('앱 정보'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.byType(ProfilePage), findsOneWidget);
  });
}
