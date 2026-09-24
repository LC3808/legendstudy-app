import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';

import 'my_profile_state_test.dart' show Selection;
import 'day7_school_test.dart' show Schools, schoolA;

import 'package:flutter/material.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';
import 'package:legendstudy_app/features/school/presentation/home_meal_card.dart';

import 'meal_owner_policy_test.dart' show m, at;

class CalendarMeals extends Schools {
  final queried = <String>[];
  @override
  Future<List<Meal>> meals(School school, String date) async {
    queried.add(date);
    return ['20260925', '20260928'].contains(date)
        ? [m(date, '조식'), m(date, '중식')]
        : [];
  }
}

void main() {
  test(
    'provider re-evaluates cached today at KST 14 and finds Monday',
    () async {
      var clock = DateTime.utc(2026, 9, 25, 4, 59);
      final repo = CalendarMeals();
      final c = ProviderContainer(
        overrides: [
          schoolSelectionProvider.overrideWith(
            () => Selection(() async => schoolA),
          ),
          mealNowProvider.overrideWithValue(() => clock),
          schoolRepositoryProvider.overrideWithValue(repo),
        ],
      );
      final sub = c.listen(nextHomeMealsProvider, (_, _) {});
      expect(await c.read(nextHomeMealsProvider.future), isEmpty);
      expect(repo.queried, containsAll(['20260925', '20260926']));
      expect(repo.queried, isNot(contains('20260928')));
      clock = DateTime.utc(2026, 9, 25, 5);
      c.invalidate(koreanMealClockProvider);
      final next = await c.read(nextHomeMealsProvider.future);
      expect(next.first.date, '20260928');
      expect(next.any((m) => m.mealType == '조식'), true);
      sub.close();
      c.dispose();
    },
  );

  final friday = DateTime.utc(2026, 9, 25, 10); // KST Friday 19:00
  for (final offset in [0, 1, 2, 3, 6]) {
    test(
      'fallback D+$offset includes tomorrow/weekend/holiday/closure/D+6',
      () async {
        final base = friday.add(const Duration(days: 1));
        final expected = koreanDateOffset(base, offset);
        final queried = <String>[];
        final rows = await nextAvailableHomeMeals(base, (date) async {
          queried.add(date);
          return date == expected
              ? [m(date, '조식'), m(date, '중식'), m(date, '석식')]
              : [];
        });
        expect(rows.first.date, expected);
        expect(queried.length, offset + 1);
        final plan = mealDisplayPlan(
          now: friday,
          today: [m('20260925', '석식')],
          tomorrow: rows,
        );
        expect(plan.primary.single.mealType, '중식');
        expect(plan.secondary.length, 3);
      },
    );
  }
  test('breakfast-only candidates skipped; never fetch D+7', () async {
    final queried = <String>[];
    final result = await nextAvailableHomeMeals(friday, (date) async {
      queried.add(date);
      return [m(date, '조식')];
    });
    expect(result, isEmpty);
    expect(queried.length, 7);
    expect(queried.last, koreanDateOffset(friday, 6));
  });
  test('failed request is an error, not a holiday', () async {
    await expectLater(
      nextAvailableHomeMeals(friday, (_) async => throw StateError('offline')),
      throwsStateError,
    );
  });
  testWidgets(
    'fallback Monday expands full selected date and still opens today',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MealSummary(
              now: friday,
              meals: [m('20260925', '중식')],
              tomorrowMeals: [
                m('20260928', '조식'),
                m('20260928', '중식'),
                m('20260928', '석식'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('다음 급식'), findsOneWidget);
      expect(find.text('9월 28일'), findsOneWidget);
      await t.tap(find.byKey(const Key('meal-expand')));
      await t.pump();
      expect(find.text('20260928 조식 메뉴'), findsOneWidget);
      expect(find.text('20260928 석식 메뉴'), findsOneWidget);
      expect(
        t
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .map((w) => (w.label as Text).data),
        ['9월 25일(금)', '9월 28일(월)'],
      );
      expect(
        t
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .map((w) => w.selected),
        [false, true],
      );
      await t.tap(find.text('9월 25일(금)'));
      await t.pump();
      expect(find.text('20260925 중식 메뉴'), findsOneWidget);
    },
  );
  test('14:00 and 19:00 keep time policy before search', () {
    final today = [m('20260921', '중식'), m('20260921', '석식')];
    expect(
      mealDisplayPlan(
        now: at(13, 59),
        today: today,
        tomorrow: [],
      ).primary.single.mealType,
      '중식',
    );
    expect(
      mealDisplayPlan(
        now: at(14),
        today: today,
        tomorrow: [],
      ).primary.single.mealType,
      '석식',
    );
    expect(
      mealDisplayPlan(
        now: at(19),
        today: today,
        tomorrow: [],
      ).primaryIsTomorrow,
      true,
    );
  });
}
