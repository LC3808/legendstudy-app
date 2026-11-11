import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';
import 'package:legendstudy_app/features/home/customization/home_configuration.dart';
import 'package:legendstudy_app/features/home/customization/home_editor.dart';
import 'package:legendstudy_app/features/home/presentation/home_page.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';

import 'core_ux_test.dart' as preview;
import 'support/home_test_support.dart';

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
  for (final (width, scale) in [(428.0, 1.0), (320.0, 2.0)]) {
    for (final reverse in [false, true]) {
      testWidgets(
        'home actions share row and reordered cards share spacing $width $scale $reverse',
        (t) async {
          t.view.physicalSize = Size(width, 926);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final ids = [
            'study_summary',
            'dday',
            'essay_lab',
            'materials_search',
            'school_meals',
            'school_ranking',
            'university_news',
            'recent_documents',
            'recent_updates',
          ];
          final order = reverse ? ids.reversed.toList() : ids;
          final config = HomeConfiguration(
            order.map((id) => HomeCardChoice(id, true)),
          );
          final cache = MemoryHomeCache();
          await t.pumpWidget(
            ProviderScope(
              overrides: [
                authStateProvider.overrideWith(
                  (ref) => Stream.value(const AuthStatus(null)),
                ),
                homeCacheProvider.overrideWithValue(cache),
                homeConfigurationProvider.overrideWith(
                  (ref) => Stream.value(
                    HomeConfigurationState(
                      config,
                      confirmed: true,
                      exists: true,
                    ),
                  ),
                ),
                homeRecentContentProvider.overrideWith((ref) async => []),
                mealBoundaryRefreshEnabledProvider.overrideWithValue(false),
              ],
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light.copyWith(
                  chipTheme: AppTheme.light.chipTheme.copyWith(
                    labelStyle: AppTheme.light.chipTheme.labelStyle?.copyWith(
                      fontFamily: const bool.fromEnvironment('CORE_RENDER')
                          ? 'CorePreview'
                          : null,
                    ),
                  ),
                  textTheme: AppTheme.light.textTheme.apply(
                    fontFamily: const bool.fromEnvironment('CORE_RENDER')
                        ? 'CorePreview'
                        : null,
                  ),
                ),
                builder: (context, child) => RepaintBoundary(
                  key: preview.frame,
                  child: MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                ),
                home: const Scaffold(body: SafeArea(child: HomePage())),
              ),
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          final edit = t.getRect(find.byTooltip('홈 편집'));
          final bell = t.getRect(find.byTooltip('알림'));
          expect(edit.center.dy, closeTo(bell.center.dy, 0.01));
          expect(edit.right, lessThanOrEqualTo(bell.left));
          for (var i = 1; i < order.length; i++) {
            final before = t.getRect(find.byKey(ValueKey(order[i - 1])));
            final after = t.getRect(find.byKey(ValueKey(order[i])));
            expect(
              after.top - before.bottom,
              closeTo(16, 0.01),
              reason: '${order[i - 1]} -> ${order[i]}',
            );
          }
          await preview.capture(
            t,
            'task04c-home-${width.toInt()}-$scale-$reverse',
          );
          await t.tap(find.byTooltip('홈 편집'));
          await t.pumpAndSettle();
          expect(find.byType(HomeEditor), findsOneWidget);
          expect(cache.values, isEmpty);
          await t.pumpWidget(const SizedBox());
          await t.pump();
        },
      );
    }
  }
}
