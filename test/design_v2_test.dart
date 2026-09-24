import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/shared/widgets/shell_widgets.dart';

// Palette fills are not automatically safe for text. Test actual semantic pairs.
double contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
}

void main() {
  test('v2 text/action roles preserve readable contrast', () {
    for (final pair in [
      (AppTokens.textPrimary, AppTokens.background),
      (AppTokens.textSecondary, AppTokens.surface),
      (AppTokens.primaryInk, AppTokens.primarySoft),
      (AppTokens.textPrimary, AppTokens.primary),
      (AppTokens.dangerInk, AppTokens.surface),
    ]) {
      expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
    }
    final nav = AppTheme.light.navigationBarTheme;
    expect(
      nav.labelTextStyle!.resolve({WidgetState.selected})!.fontWeight,
      FontWeight.w700,
    );
    expect(nav.labelTextStyle!.resolve({})!.color, AppTokens.textSecondary);
    expect(AppTheme.light.scaffoldBackgroundColor, AppTokens.background);
    expect(AppTheme.light.colorScheme.surface, AppTokens.surface);
    expect(AppTokens.background, isNot(AppTokens.surface));
  });
  for (final route in ['/my', '/my/settings']) {
    testWidgets('Guest $route visible login reaches existing Auth', (t) async {
      final c = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus(null)),
          ),
        ],
      );
      c.read(routerProvider).go(route);
      await t.pumpWidget(
        UncontrolledProviderScope(container: c, child: const LegendStudyApp()),
      );
      await t.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, '로그인');
      expect(button, findsOneWidget);
      expect(t.getSize(button).height, greaterThanOrEqualTo(48));
      expect(find.text('프로필 수정'), findsNothing);
      if (route == '/my') {
        expect(find.text('공부하러 가기'), findsNothing);
        expect(find.text('모의고사 성적 분석'), findsNothing);
      }
      await t.tap(button);
      await t.pumpAndSettle();
      expect(find.byType(AuthPage), findsOneWidget);
      expect(c.read(routerProvider).canPop(), isTrue);
      expect(find.text('나의 학습 기록을 이어가세요.'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    });
  }
  testWidgets(
    'section header is semantic plain title, card owns neutral surface',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: LsCard(child: SectionHeader('학습'))),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(SectionHeader),
          matching: find.byType(Container),
        ),
        findsNothing,
      );
      final surface =
          t.widget<Container>(find.byType(Container)).decoration!
              as BoxDecoration;
      expect(surface.color, AppTokens.surface);
      expect(surface.border, isNull);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.header == true,
        ),
        findsOneWidget,
      );
    },
  );
}
