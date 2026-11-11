import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/home/customization/home_configuration.dart';
import 'package:legendstudy_app/features/home/customization/home_editor.dart';
import 'package:legendstudy_app/features/home/university_news/university_news.dart';
import 'package:legendstudy_app/features/home/university_news/university_news_widgets.dart';

import 'core_ux_test.dart' as preview;
import 'university_news_test.dart' as fixtures;
import 'support/home_test_support.dart';

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CORE_RENDER')) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final font = File('/System/Library/Fonts/AppleSDGothicNeo.ttc');
      if (font.existsSync()) {
        await (FontLoader(
          'CorePreview',
        )..addFont(font.readAsBytes().then(ByteData.sublistView))).load();
      }
    }
  });
  for (final scale in [1.0, 2.0]) {
    for (final screen in ['editor', 'news']) {
      testWidgets('task04 $screen 360px $scale native render', (t) async {
        t.view.physicalSize = const Size(360, 800);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        await t.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) =>
                    Stream.value(AuthStatus(screen == 'editor' ? null : 'a')),
              ),
              homeCacheProvider.overrideWithValue(MemoryHomeCache()),
              universityNewsProvider.overrideWith(
                (ref) async => UniversityNewsFeed(
                  [
                    UniversityNewsItem({
                      ...fixtures.news(scope: 'university'),
                      'expires_at': '2200-01-01T00:00:00Z',
                    }),
                  ],
                  [fixtures.application()],
                  [fixtures.interest],
                ),
              ),
            ],
            child: MaterialApp(
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
              home: screen == 'editor'
                  ? const HomeEditor()
                  : const UniversityNewsPage(),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
        await preview.capture(t, 'task04-$screen-$scale');
        await t.pumpWidget(const SizedBox());
      });
    }
  }
}
