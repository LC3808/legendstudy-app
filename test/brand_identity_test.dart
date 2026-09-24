import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/config/app_information.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';
import 'package:legendstudy_app/features/home/presentation/home_page.dart';
import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';
import 'package:legendstudy_app/features/profile/presentation/settings_page.dart';

import 'day5_shell_test.dart' show ShellContent;

void main() {
  const render = bool.fromEnvironment('BRAND_RENDER');
  setUpAll(() async {
    if (render) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader('BrandPreview')..addFont(
            File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
    }
  });
  for (final size in [const Size(360, 640), const Size(428, 926)]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('brand surfaces ${size.width} at $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final key = GlobalKey();
        Future<void> capture(String surface) async {
          expect(tester.takeException(), isNull);
          if (!render) return;
          await tester.runAsync(() async {
            final image =
                await (key.currentContext!.findRenderObject()!
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final dir = Directory('/private/tmp/legendstudy-brand-ui')
              ..createSync(recursive: true);
            File('${dir.path}/$surface-${size.width.toInt()}-$scale.png')
                .writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }

        Future<void> mount(Widget page) async {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                appConfigProvider.overrideWithValue(const AppConfig()),
                authStateProvider.overrideWith(
                  (ref) => Stream.value(const AuthStatus(null)),
                ),
                contentRepositoryProvider.overrideWithValue(ShellContent()),
                appVersionProvider.overrideWith((ref) async => '2.4.1 (37)'),
              ],
              child: RepaintBoundary(
                key: key,
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  locale: const Locale('ko'),
                  supportedLocales: const [Locale('ko')],
                  localizationsDelegates: GlobalMaterialLocalizations.delegates,
                  theme: render
                      ? AppTheme.light.copyWith(
                          textTheme: AppTheme.light.textTheme.apply(
                            fontFamily: 'BrandPreview',
                          ),
                        )
                      : AppTheme.light,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                  home: Scaffold(body: SafeArea(child: page)),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await mount(const HomePage());
        expect(find.text('레전드스터디+'), findsNothing);
        expect(find.text('오늘도 공부를 시작해 볼까요?'), findsOneWidget);
        await capture('home');
        await mount(const AuthPage());
        await capture('auth');
        await mount(const SettingsPage());
        await capture('my');
        await tester.ensureVisible(find.text('앱 정보'));
        await tester.tap(find.text('앱 정보'));
        await tester.pumpAndSettle();
        expect(find.text('레전드스터디+'), findsOneWidget);
        expect(find.text('버전 2.4.1 (37)'), findsOneWidget);
        await capture('about');
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
