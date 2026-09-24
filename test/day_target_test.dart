import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/home/presentation/day_target_card.dart';
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
    testWidgets(
      'D-Day hierarchy long label and all badge widths at ${scale}x',
      (tester) async {
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
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(
                body: Padding(
                  padding: EdgeInsets.all(20),
                  child: DayTargetCard(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        for (final days in [0, 1, 23, 999, 7300, -1]) {
          final target = DayTarget(
            date: now.add(Duration(days: days)),
            label: '아주 긴 중간고사 일정 이름과 메모를 끝까지 입력한 경우',
          );
          await container.read(dayTargetProvider.notifier).setTarget(target);
          await tester.pumpAndSettle();
          final status = days < 0
              ? '지난 일정'
              : days == 0
              ? 'D-DAY'
              : 'D-$days';
          final nameRect = tester.getRect(find.text(target.label));
          final statusRect = tester.getRect(find.text(status));
          final settingsRect = tester.getRect(
            find.widgetWithText(TextButton, '설정'),
          );
          expect(nameRect.bottom, lessThanOrEqualTo(statusRect.top));
          expect(
            statusRect.right,
            lessThanOrEqualTo(tester.getRect(find.byType(DayTargetCard)).right),
          );
          expect(nameRect.right, lessThan(settingsRect.left));
          expect(statusRect.right, lessThan(settingsRect.left));
          expect(settingsRect.height, greaterThanOrEqualTo(48));
          expect(settingsRect.width, greaterThanOrEqualTo(48));
          expect(
            tester.getTopLeft(find.text(target.formattedDate)).dy,
            greaterThanOrEqualTo(settingsRect.bottom),
          );
          expect(
            tester.widget<Text>(find.text(target.label)).overflow,
            TextOverflow.ellipsis,
          );
          final style = tester.widget<Text>(find.text(status)).style!;
          expect(
            style.color,
            days < 0 ? AppTokens.textSecondary : AppTokens.primaryInk,
          );
          if (days >= 0) expect(style.fontWeight, FontWeight.w800);
          expect(
            tester.getBottomRight(find.text(target.formattedDate)).dy -
                nameRect.top,
            lessThan(360),
          );
          expect(tester.takeException(), isNull, reason: 'day offset $days');
        }
      },
    );
  }
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
        await tester.tap(find.widgetWithText(TextButton, '설정'));
        await tester.pumpAndSettle();
        expect(find.text('앱을 종료하면 초기화돼요. 계정에는 저장되지 않아요.'), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), '수능');
        await tester.tap(find.text('적용'));
        await tester.pumpAndSettle();
        expect(find.text('수능'), findsOneWidget);
        expect(find.text('D-DAY'), findsOneWidget);
        expect(find.text('2026.09.13'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.widgetWithText(TextButton, '설정'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('해제'));
        await tester.pumpAndSettle();
        expect(container.read(dayTargetProvider).value, isNull);
        await tester.ensureVisible(study);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
