import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';
import 'package:legendstudy_app/features/home/day_target_providers.dart';
import 'package:legendstudy_app/features/home/domain/day_target.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';

import 'neis_attribution_test.dart' show FixedSchool;
import 'day7_school_test.dart' show schoolA, meal;

void main() {
  final now = DateTime.utc(2026, 9, 13);
  test('Korean midnight, calendar boundaries, today and expired target', () {
    final target = DayTarget(date: DateTime(2026, 9, 14), label: ' 수능 ');
    expect(target.label, '수능');
    expect(
      target.description(DateTime.utc(2026, 9, 13, 14, 59)),
      'D-1 · 2026.09.14',
    );
    expect(
      target.description(DateTime.utc(2026, 9, 13, 15)),
      'D-DAY · 2026.09.14',
    );
    expect(
      target.description(DateTime.utc(2026, 9, 14, 15)),
      '지난 일정 · 2026.09.14',
    );
    expect(
      DayTarget(
        date: DateTime(2028, 3, 1),
        label: '시험',
      ).daysFrom(DateTime.utc(2028, 2, 28)),
      2,
    );
    expect(
      DayTarget(
        date: DateTime(2027, 1, 1),
        label: '시험',
      ).daysFrom(DateTime.utc(2026, 12, 31)),
      1,
    );
    expect(() => DayTarget(date: now, label: ' '), throwsFormatException);
    expect(() => DayTarget(date: now, label: '가' * 81), throwsFormatException);
  });
  test(
    'session target clears when auth identity changes and never persists',
    () async {
      final auth = StreamController<AuthStatus>();
      final container = ProviderContainer(
        overrides: [authStateProvider.overrideWith((ref) => auth.stream)],
      );
      final subscription = container.listen(dayTargetProvider, (_, _) {});
      auth.add(const AuthStatus(null));
      await Future<void>.delayed(Duration.zero);
      await container.read(dayTargetProvider.future);
      await container
          .read(dayTargetProvider.notifier)
          .setTarget(DayTarget(date: now, label: '시험'));
      expect(container.read(dayTargetProvider).value?.label, '시험');
      auth.add(const AuthStatus('A'));
      await Future<void>.delayed(Duration.zero);
      await container.read(dayTargetProvider.future);
      expect(container.read(dayTargetProvider).value, isNull);
      subscription.close();
      container.dispose();
      await auth.close();
      final fresh = ProviderContainer();
      expect(await fresh.read(dayTargetProvider.future), isNull);
      fresh.dispose();
    },
  );
  for (final scale in [1.0, 2.0]) {
    for (final state in ['none', 'data', 'empty']) {
      testWidgets('Home $state and D-Day editor at 360x640 / ${scale}x', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final container = ProviderContainer(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus(null)),
            ),
            dayTargetClockProvider.overrideWith((ref) => Stream.value(now)),
            recentContentProvider.overrideWith((ref) async => []),
            schoolSelectionProvider.overrideWith(
              () => FixedSchool(state == 'none' ? null : schoolA),
            ),
            todayMealsProvider.overrideWith(
              (ref) async => state == 'data' ? [meal] : [],
            ),
            tomorrowMealsProvider.overrideWith((ref) async => []),
            mealBoundaryRefreshEnabledProvider.overrideWithValue(false),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const LegendStudyApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('오늘의 공부'), findsNothing);
        if (state == 'none') {
          final sectionLabels = [
            'D-DAY',
            '나의 공부 시간',
            '우리 학교 · 오늘 급식',
            '자료 검색',
            '최근 본 자료',
            '최근 업데이트',
          ];
          final tops = sectionLabels
              .map((label) => tester.getTopLeft(find.text(label)).dy)
              .toList();
          expect(tops, orderedEquals([...tops]..sort()));
          expect(
            tester.getTopLeft(find.text('최근 본 자료')).dy,
            lessThan(tester.getTopLeft(find.text('최근 업데이트')).dy),
          );
        }
        expect(find.text('D-DAY'), findsOneWidget);
        expect(find.textContaining('NEIS'), findsNothing);
        final study = find.widgetWithText(TextButton, '학습으로 이동');
        expect(tester.getSize(study).height, greaterThanOrEqualTo(48));
        final row = find.ancestor(of: study, matching: find.byType(Row)).first;
        expect(
          find.descendant(of: row, matching: find.text('나의 공부 시간')),
          findsOneWidget,
        );
        // Actual dashboard extent; long meal data and accessibility text may scroll.
        // ignore: avoid_print
        print(
          'Home $state ${scale}x study bottom: ${tester.getBottomLeft(find.text("오늘 공부 기록이 아직 없어요.")).dy}',
        );
        // Multi D-Day UX: 설정 opens the manage sheet; add an event via the form.
        await tester.tap(find.widgetWithText(TextButton, '설정'));
        await tester.pumpAndSettle();
        expect(find.text('D-Day 관리'), findsOneWidget);
        await tester.tap(find.widgetWithText(TextButton, '일정 추가'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), '수능');
        await tester.tap(find.text('적용'));
        await tester.pumpAndSettle();
        // Close the manage sheet to reveal the Home representative card.
        Navigator.of(tester.element(find.text('D-Day 관리'))).pop();
        await tester.pumpAndSettle();
        expect(find.textContaining('수능 · 2026.09.13'), findsOneWidget);
        expect(find.text('D-DAY'), findsOneWidget);
        await tester.ensureVisible(study);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
