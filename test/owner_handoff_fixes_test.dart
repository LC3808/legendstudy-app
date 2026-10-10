import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/features/auth/auth_email.dart';
import 'package:go_router/go_router.dart';
import 'package:legendstudy_app/features/profile/presentation/settings_page.dart';

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/profile/avatar.dart';

import 'avatar_test.dart' show Photos, Picker, png;

class ReadAfterWritePhotos extends Photos {
  Completer<Uint8List?>? reload;
  @override
  Future<Uint8List?> load() async => reload == null ? value : reload!.future;
  @override
  Future<void> save(Uint8List bytes) async {
    await super.save(bytes);
    reload = Completer<Uint8List?>();
  }
}

void main() {
  testWidgets('integrated guest login entry reaches Home and public Materials', (t) async {
    final container = ProviderContainer(overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(const AuthStatus(null))),
    ]);
    final router = container.read(routerProvider)..go('/auth');
    await t.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const LegendStudyApp(),
    ));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('비회원으로 이용하기'));
    await t.tap(find.text('비회원으로 이용하기'));
    await t.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(container.read(authStateProvider).value?.isAuthenticated, false);
    router.go('/materials');
    await t.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/materials');
    expect(find.byType(NavigationBar), findsOneWidget);
    // Shared history resolves through the real router while private data stays gated.
    router.go('/lab/essay/history');
    await t.pumpAndSettle();
    expect(find.text('나의 첨삭 기록'), findsOneWidget);
    expect(find.text('로그인 상태를 확인해 주세요.'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
    container.dispose();
    await t.pump();
  });

  testWidgets('real five-tab shell selects Home after logout from Settings', (
    t,
  ) async {
    final events = StreamController<AuthStatus>.broadcast();
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith((ref) => events.stream),
        // Signed-in user under test is an onboarded returning user, so the
        // first-login gate does not intercept Settings/logout navigation.
        currentProfileProvider.overrideWith((ref) async {
          final id = ref.watch(authStateProvider).value?.userId;
          return id == null
              ? null
              : UserProfile(id: id, onboardingCompletedAt: DateTime(2026));
        }),
        localLogoutProvider.overrideWithValue(() async {
          events.add(const AuthStatus(null));
        }),
      ],
    );
    final router = container.read(routerProvider)..go('/my/settings');
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const LegendStudyApp(),
      ),
    );
    events.add(const AuthStatus('a'));
    await t.pumpAndSettle();
    await t.ensureVisible(find.widgetWithText(OutlinedButton, '로그아웃'));
    await t.tap(find.widgetWithText(OutlinedButton, '로그아웃'));
    await t.pumpAndSettle();
    await t.tap(find.widgetWithText(TextButton, '로그아웃'));
    await t.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(
      t.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
    expect(container.read(authStateProvider).value?.userId, isNull);
    await t.pumpWidget(const SizedBox());
    container.dispose();
    unawaited(events.close());
    await t.pump();
  });

  testWidgets(
    'logout cancel and failure stay; signedOut before completion still goes HOME',
    (t) async {
      final events = StreamController<AuthStatus>();
      final pending = Completer<void>();
      var calls = 0;
      var fail = true;
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(path: '/settings', builder: (_, _) => const SettingsPage()),
          GoRoute(
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('HOME selected')),
          ),
        ],
      );
      addTearDown(router.dispose);
      addTearDown(events.close);
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) async* {
              yield const AuthStatus('a');
              yield* events.stream;
            }),
            localLogoutProvider.overrideWithValue(() async {
              calls++;
              if (fail) throw StateError('fixture');
              events.add(const AuthStatus(null));
              await pending.future;
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await t.pumpAndSettle();
      Future<void> open() async {
        await t.ensureVisible(find.widgetWithText(OutlinedButton, '로그아웃'));
        await t.tap(find.widgetWithText(OutlinedButton, '로그아웃'));
        await t.pumpAndSettle();
      }

      await open();
      await t.tap(find.text('취소'));
      await t.pumpAndSettle();
      expect(calls, 0);
      expect(router.routeInformationProvider.value.uri.path, '/settings');
      await open();
      await t.tap(find.widgetWithText(TextButton, '로그아웃'));
      await t.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/settings');
      fail = false;
      await open();
      await t.tap(find.widgetWithText(TextButton, '로그아웃'));
      await t.pumpAndSettle();
      expect(find.widgetWithText(OutlinedButton, '로그아웃'), findsNothing);
      pending.complete();
      await t.pumpAndSettle();
      expect(calls, 2);
      expect(find.text('HOME selected'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/home');
    },
  );

  testWidgets(
    'first upload cannot announce success before refreshed bytes arrive',
    (t) async {
      final photos = ReadAfterWritePhotos();
      await t.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('a')),
            ),
            avatarRepositoryProvider.overrideWithValue(photos),
            avatarPickerProvider.overrideWithValue(Picker()),
          ],
          child: const MaterialApp(home: Scaffold(body: ProfileAvatar())),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('프로필 사진 변경'));
      await t.pumpAndSettle();
      await t.tap(find.text('사진 선택'));
      await t.pump(const Duration(milliseconds: 400));
      expect(photos.writes, 1);
      expect(find.text('프로필 사진을 변경했어요.'), findsNothing);
      photos.reload!.complete(png);
      await t.pumpAndSettle();
      expect(find.text('프로필 사진을 변경했어요.'), findsOneWidget);
      expect(
        t.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundImage,
        isA<MemoryImage>(),
      );
    },
  );
  testWidgets('write success with stale read never reports photo success', (
    t,
  ) async {
    final photos = ReadAfterWritePhotos();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('a')),
          ),
          avatarRepositoryProvider.overrideWithValue(photos),
          avatarPickerProvider.overrideWithValue(Picker()),
        ],
        child: const MaterialApp(home: Scaffold(body: ProfileAvatar())),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('프로필 사진 변경'));
    await t.pumpAndSettle();
    await t.tap(find.text('사진 선택'));
    await t.pump(const Duration(milliseconds: 400));
    expect(photos.writes, 1);
    expect(find.text('프로필 사진을 변경했어요.'), findsNothing);
    photos.reload!.complete(null);
    await t.pumpAndSettle();
    expect(find.text('프로필 사진을 변경했어요.'), findsNothing);
    expect(find.textContaining('사진을 변경하지 못했어요'), findsOneWidget);
    expect(
      t.widget<CircleAvatar>(find.byType(CircleAvatar)).backgroundImage,
      isNull,
    );
  });
}
