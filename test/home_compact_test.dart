import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';
import 'package:legendstudy_app/features/school/presentation/home_meal_card.dart';
import 'package:legendstudy_app/shared/widgets/shell_widgets.dart';

import 'core_ux_test.dart' as preview;
import 'neis_attribution_test.dart' show FixedSchool;
import 'day7_school_test.dart' show schoolA;

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
    }
  });
  for (final size in [const Size(360, 640), const Size(428, 926)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Home compact inline keeps route and tabs ${size.width} $scale',
        (t) async {
          t.view.physicalSize = size;
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final container = ProviderContainer(
            overrides: [
              homeRecentContentProvider.overrideWith((ref) async => []),
              schoolSelectionProvider.overrideWith(() => FixedSchool(schoolA)),
              koreanMealClockProvider.overrideWithValue(
                DateTime.utc(2026, 9, 22, 3),
              ),
              mealBoundaryRefreshEnabledProvider.overrideWithValue(false),
              todayMealsProvider.overrideWith(
                (ref) async => [
                  const Meal(
                    date: '20260922',
                    mealType: '조식',
                    menuItems: ['토스트와 우유'],
                  ),
                  const Meal(
                    date: '20260922',
                    mealType: '중식',
                    menuItems: ['현미밥', '소고기미역국', '돼지고기김치볶음', '제철 과일과 요구르트'],
                  ),
                ],
              ),
              tomorrowMealsProvider.overrideWith((ref) async => []),
            ],
          );
          addTearDown(container.dispose);
          final router = container.read(routerProvider);
          await t.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: RepaintBoundary(
                key: preview.frame,
                child: MaterialApp.router(
                  debugShowCheckedModeBanner: false,
                  locale: const Locale('ko'),
                  supportedLocales: const [Locale('ko')],
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  routerConfig: router,
                  theme: AppTheme.light.copyWith(
                    chipTheme: AppTheme.light.chipTheme.copyWith(
                      labelStyle: AppTheme.light.chipTheme.labelStyle?.copyWith(
                        fontFamily: 'CorePreview',
                      ),
                    ),
                    textTheme: AppTheme.light.textTheme.apply(
                      fontFamily: 'CorePreview',
                    ),
                  ),
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(find.byType(DailyUtilityCard), findsNWidgets(2));
          expect(find.text('학교 설정'), findsNothing);
          expect(
            t.getTopLeft(find.text('오늘 중식')).dx,
            lessThan(t.getTopLeft(find.text(schoolA.name)).dx),
          );
          expect(find.byType(NavigationBar), findsOneWidget);
          await preview.capture(t, 'home-compact-${size.width.toInt()}-$scale');
          await t.ensureVisible(find.byType(MealSummary));
          await t.tap(find.text('오늘 중식'));
          await t.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, '/home');
          expect(find.byType(NavigationBar), findsOneWidget);
          expect(find.text('조식'), findsOneWidget);
          await preview.capture(t, 'home-inline-${size.width.toInt()}-$scale');
          await t.ensureVisible(find.text('오늘 급식'));
          await t.tap(find.text('오늘 급식'));
          await t.pumpAndSettle();
          expect(find.text('조식'), findsNothing);
          expect(router.routeInformationProvider.value.uri.path, '/home');
          expect(t.takeException(), isNull);
          await t.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
