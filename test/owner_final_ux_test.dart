import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/profile/avatar.dart';
import 'package:legendstudy_app/features/auth/presentation/auth_page.dart';
import 'package:legendstudy_app/features/study/trends/study_bar_chart.dart';
import 'package:legendstudy_app/features/study/trends/study_trends.dart';

import 'study_repository_test.dart' show login, owner, config;

void main() {
  test('applied storage is usable without a compile-time photo flag', () async {
    final client = SupabaseClient(
      'https://example.invalid',
      'offline',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await login(client, owner, 'offline');
    final c = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        supabaseClientProvider.overrideWithValue(client),
        authStateProvider.overrideWith(
          (ref) => Stream.value(const AuthStatus(owner)),
        ),
      ],
    );
    final sub = c.listen(authStateProvider, (_, _) {});
    await c.read(authStateProvider.future).timeout(const Duration(seconds: 3));
    expect(c.read(avatarRepositoryProvider), isA<StorageAvatarRepository>());
    sub.close();
    c.dispose();
    await client.dispose();
  });
  for (final provider in ['Email', 'Apple', 'Google', 'Kakao']) {
    testWidgets('$provider sign-in from MY lands directly on selected Home', (
      t,
    ) async {
      final events = StreamController<AuthStatus>.broadcast();
      final c = ProviderContainer(
        overrides: [authStateProvider.overrideWith((ref) => events.stream)],
      );
      final router = c.read(routerProvider)..go('/my');
      await t.pumpWidget(
        UncontrolledProviderScope(container: c, child: const LegendStudyApp()),
      );
      events.add(const AuthStatus(null));
      await t.pumpAndSettle();
      unawaited(router.push('/auth'));
      await t.pumpAndSettle();
      expect(find.text('나의 학습 기록을 이어가세요.'), findsOneWidget);
      expect(find.text('LegendStudy Account'), findsNothing);
      expect(find.text('레전드스터디+'), findsNothing);
      events.add(const AuthStatus(owner, event: AuthChangeEvent.signedIn));
      await t.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      expect(
        t.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        0,
      );
      events.add(const AuthStatus(null, event: AuthChangeEvent.signedOut));
      await t.pumpAndSettle();
      unawaited(router.push('/auth?returnTo=https://example.invalid'));
      await t.pumpAndSettle();
      events.add(const AuthStatus(owner, event: AuthChangeEvent.signedIn));
      await t.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/home');
      await t.pumpWidget(const SizedBox());
      c.dispose();
      unawaited(events.close());
      await t.pump();
    });
  }
  testWidgets(
    'explicit in-app protected return preserved; restore does not navigate',
    (t) async {
      final events = StreamController<AuthStatus>.broadcast();
      final c = ProviderContainer(
        overrides: [authStateProvider.overrideWith((ref) => events.stream)],
      );
      final router = c.read(routerProvider)..go('/my/saved');
      await t.pumpWidget(
        UncontrolledProviderScope(container: c, child: const LegendStudyApp()),
      );
      events.add(const AuthStatus(null));
      await t.pumpAndSettle();
      unawaited(router.push('/auth', extra: true));
      await t.pumpAndSettle();
      events.add(const AuthStatus(owner, event: AuthChangeEvent.signedIn));
      await t.pumpAndSettle();
      expect(find.byType(AuthPage), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, '/my/saved');
      events.add(
        const AuthStatus(owner, event: AuthChangeEvent.initialSession),
      );
      await t.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/my/saved');
      await t.pumpWidget(const SizedBox());
      c.dispose();
      unawaited(events.close());
      await t.pump();
    },
  );
  for (final p in TrendPeriod.values) {
    test(
      'chart ${p.name} chronological order, zero and proportional height',
      () {
        final dates = trendDates(p, DateTime.utc(2026, 9, 23));
        for (var i = 1; i < dates.length; i++) {
          expect(dates[i].isAfter(dates[i - 1]), true);
        }
        final ceiling = studyChartCeiling([0, 1800000, 3600000, 7200000]);
        expect(studyBarHeight(0, ceiling), 0);
        expect(studyBarHeight(7200000, ceiling), 160);
        expect(studyBarHeight(3600000, ceiling), 80);
        expect(studyBarHeight(1800000, ceiling), 40);
        expect(studyBarHeight(60000, studyChartCeiling([60000])), lessThan(3));
      },
    );
  }
}
