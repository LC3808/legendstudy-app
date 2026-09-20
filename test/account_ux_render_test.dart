import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/auth/auth_email.dart';
import 'package:legendstudy_app/features/auth/auth_oauth.dart';
import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';
import 'package:legendstudy_app/features/auth/presentation/password_recovery_page.dart';
import 'package:legendstudy_app/features/auth/presentation/new_password_page.dart';
import 'package:legendstudy_app/features/profile/presentation/profile_page.dart';

import 'core_ux_test.dart' as preview;

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
  for (final scenario in [
    'login',
    'signup',
    'social',
    'recovery',
    'new-password',
    'my',
  ]) {
    testWidgets('account 360x640 2x $scenario keyboard and long text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final page = switch (scenario) {
        'recovery' => const PasswordRecoveryPage(linkFailed: true),
        'new-password' => const NewPasswordPage(),
        'my' => const ProfilePage(),
        _ => const AuthPage(),
      };
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(
                scenario == 'my' || scenario == 'new-password'
                    ? const AuthStatus('a')
                    : const AuthStatus(null),
              ),
            ),
            currentAccountEmailProvider.overrideWithValue(
              'very.long.student.email.for.wrapping@example.test',
            ),
            availableOAuthProvidersProvider.overrideWithValue(
              scenario == 'social' ? supportedOAuthProviders : [],
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            locale: const Locale('ko'),
            supportedLocales: const [Locale('ko')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: AppTheme.light.copyWith(
              textTheme: AppTheme.light.textTheme.apply(
                fontFamily: 'CorePreview',
              ),
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: RepaintBoundary(
              key: preview.frame,
              child: Scaffold(body: SafeArea(child: page)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (scenario == 'signup') {
        await tester.ensureVisible(find.text('처음이신가요? 회원가입'));
        await tester.tap(find.text('처음이신가요? 회원가입'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.widgetWithText(FilledButton, '회원가입'));
        await tester.tap(find.widgetWithText(FilledButton, '회원가입'));
        await tester.pumpAndSettle();
      }
      if (scenario == 'social') {
        await tester.ensureVisible(find.text('Kakao로 계속하기'));
        await tester.pumpAndSettle();
      }
      await preview.capture(tester, 'account-$scenario-2x');
      if (scenario != 'my' && scenario != 'social') {
        await tester.ensureVisible(find.byType(TextField).first);
        await tester.enterText(
          find.byType(TextField).first,
          'very.long.student.email.for.wrapping@example.test',
        );
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(FilledButton).first);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byType(FilledButton).first).bottom,
          lessThanOrEqualTo(380),
        );
        await preview.capture(tester, 'account-$scenario-keyboard-2x');
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
