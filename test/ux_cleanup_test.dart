import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';
import 'package:legendstudy_app/features/credits/credit_balance.dart';

void main() {
  for (final width in [360.0, 375.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('login footer and compact credit $width at $scale', (
        t,
      ) async {
        t.view.physicalSize = Size(width, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        Widget wrap(Widget child) => ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus(null)),
            ),
            appConfigProvider.overrideWithValue(
              const AppConfig(
                privacyUrl: 'https://lab.legendstudy.com/privacy/',
                termsUrl: 'https://lab.legendstudy.com/terms/',
              ),
            ),
            creditBalanceProvider.overrideWith(
              (ref) async => CreditBalance.fromJson({
                'dto_version': 'credit-v1',
                'spendable': 6,
                'paid': 0,
                'free': 3,
                'other': 3,
                'next_expiry': null,
              }),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(body: child),
          ),
        );
        await t.pumpWidget(wrap(const AuthPage()));
        await t.pumpAndSettle();
        final hero = t.widget<Text>(find.text('나의 가능성을\n더 선명하게 만드세요.'));
        expect(hero.style?.fontSize, AppTokens.sectionTitle.fontSize);
        expect(hero.style?.fontWeight, AppTokens.sectionTitle.fontWeight);
        expect(hero.textAlign, TextAlign.center);
        await t.ensureVisible(find.text('이용약관'));
        await t.pumpAndSettle();
        expect(
          t.getTopLeft(find.text('개인정보처리방침')).dy,
          greaterThan(t.getTopLeft(find.text('비회원으로 이용하기')).dy),
        );
        expect(t.takeException(), isNull);
        await t.pumpWidget(
          wrap(
            const Padding(
              padding: EdgeInsets.all(20),
              child: CreditBalanceCard(showTopUp: true, compact: true),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text('사용 가능 Credit 6개'), findsOneWidget);
        expect(find.textContaining('가입 무료'), findsNothing);
        expect(t.takeException(), isNull);
      });
    }
  }
  test('primary and secondary use existing navy and neutral tokens', () {
    final theme = AppTheme.light;
    expect(
      theme.filledButtonTheme.style!.backgroundColor!.resolve({}),
      AppTokens.textPrimary,
    );
    expect(
      theme.filledButtonTheme.style!.foregroundColor!.resolve({}),
      AppTokens.surface,
    );
    expect(
      theme.outlinedButtonTheme.style!.side!.resolve({})!.color,
      AppTokens.cardBorder,
    );
  });
}
