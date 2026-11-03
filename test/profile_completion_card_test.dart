import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/profile/presentation/profile_completion_card.dart';

void main() {
  Future<void> mount(
    WidgetTester t,
    FutureOr<UserProfile?> Function() profile, {
    String? owner = 'u',
    double scale = 1,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: SingleChildScrollView(child: ProfileCompletionCard()),
          ),
        ),
        GoRoute(
          path: '/my/school',
          builder: (_, _) => const Scaffold(body: Text('기존 학교 프로필 수정')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(AuthStatus(owner)),
          ),
          currentProfileProvider.overrideWith((ref) => profile()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  for (final status in ['retaker', 'other']) {
    testWidgets('$status never prompted to add school', (t) async {
      await mount(t, () => UserProfile(id: 'u', academicStatus: status));
      expect(find.text('정보 설정하기'), findsNothing);
    });
  }
  testWidgets(
    'status takes priority over legacy grade/school and opens existing editor',
    (t) async {
      await mount(
        t,
        () => const UserProfile(
          id: 'u',
          gradeLevel: 2,
          neisOfficeCode: 'J10',
          neisSchoolCode: '1',
        ),
      );
      expect(find.text('현재 상태를 먼저 설정해 주세요.'), findsOneWidget);
      await t.tap(find.text('정보 설정하기'));
      await t.pumpAndSettle();
      expect(find.text('기존 학교 프로필 수정'), findsOneWidget);
    },
  );
  for (final kind in ['both', 'school', 'grade', 'complete']) {
    testWidgets('student missing $kind fields only', (t) async {
      await mount(
        t,
        () => UserProfile(
          id: 'u',
          academicStatus: 'student',
          gradeLevel: kind == 'both' || kind == 'grade' ? null : 2,
          neisOfficeCode: kind == 'both' || kind == 'school' ? null : 'J10',
          neisSchoolCode: kind == 'both' || kind == 'school' ? null : '1',
        ),
      );
      if (kind == 'complete') {
        expect(find.text('정보 설정하기'), findsNothing);
      } else {
        expect(
          find.text(
            kind == 'both'
                ? '학교와 학년을 설정해 주세요.'
                : kind == 'school'
                ? '학교를 설정해 주세요.'
                : '학년을 설정해 주세요.',
          ),
          findsOneWidget,
        );
      }
    });
  }
  testWidgets(
    'guest, loading, errors and stale owner never imply missing data',
    (t) async {
      await mount(t, () => null, owner: null);
      expect(find.text('정보 설정하기'), findsNothing);
      await t.pumpWidget(const SizedBox());
      await mount(t, () => Completer<UserProfile?>().future);
      expect(find.text('정보 설정하기'), findsNothing);
      await t.pumpWidget(const SizedBox());
      await mount(t, () => throw StateError('offline'));
      expect(find.text('정보 설정하기'), findsNothing);
      await t.pumpWidget(const SizedBox());
      await mount(t, () => const UserProfile(id: 'another'));
      expect(find.text('정보 설정하기'), findsNothing);
    },
  );
  testWidgets(
    'stored completion hides prompt automatically, no NEIS lookup required',
    (t) async {
      UserProfile value = const UserProfile(id: 'u', academicStatus: 'student');
      final c = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('u')),
          ),
          currentProfileProvider.overrideWith((ref) async => value),
        ],
      );
      addTearDown(c.dispose);
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: const MaterialApp(
            home: Scaffold(body: ProfileCompletionCard()),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('정보 설정하기'), findsOneWidget);
      value = const UserProfile(
        id: 'u',
        academicStatus: 'student',
        gradeLevel: 3,
        neisOfficeCode: 'J10',
        neisSchoolCode: '1',
      );
      c.invalidate(currentProfileProvider);
      await t.pumpAndSettle();
      expect(find.text('정보 설정하기'), findsNothing);
    },
  );
  testWidgets('optional card fits 360px at 200 percent text', (t) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await mount(
      t,
      () => const UserProfile(id: 'u', academicStatus: 'student'),
      scale: 2,
    );
    expect(t.takeException(), isNull);
    expect(find.text('정보 설정하기'), findsOneWidget);
  });
}
