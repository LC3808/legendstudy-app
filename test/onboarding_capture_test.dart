import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/brand/brand_wordmark.dart';
import 'package:legendstudy_app/features/onboarding/presentation/onboarding_page.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/personal/domain/personal_repositories.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';

import 'core_ux_test.dart' as preview;

/// Small-screen render guard + visual capture for the redesigned brand intro
/// (centred, single brand symbol per slide). Run with
/// `--dart-define=CORE_RENDER=true` to emit PNGs to /private/tmp/legendstudy-core-ui.
class _Repo implements ProfileRepository {
  @override
  Future<UserProfile?> fetchCurrentProfile() async =>
      const UserProfile(id: 'u1');
  @override
  Future<void> updateSchoolSelection({
    String? officeCode,
    String? schoolCode,
  }) async {}
  @override
  Future<void> upsertCurrentProfile({
    String? displayName,
    int? gradeLevel,
    bool clearGrade = false,
    String? academicStatus,
    bool clearAcademicStatus = false,
  }) async {}
  @override
  Future<void> markOnboardingComplete() async {}
}

class _NoSchools implements SchoolRepository {
  @override
  Future<List<School>> search(String query) async => const [];
  @override
  Future<School?> find(String officeCode, String schoolCode) async => null;
  @override
  Future<List<Meal>> meals(School school, String date) async => const [];
}

void main() {
  testWidgets('brand intro renders centred, no overflow at 360x640', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1280); // 360x640 @2x
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('u1')),
          ),
          profileRepositoryProvider.overrideWithValue(_Repo()),
          schoolRepositoryProvider.overrideWithValue(_NoSchools()),
        ],
        child: preview.app(const OnboardingPage()),
      ),
    );
    await tester.pumpAndSettle();

    // Slide 1: the brand logotype (레전드스터디⁺ via BrandWordmark).
    expect(find.byType(BrandWordmark), findsOneWidget);
    await preview.capture(tester, 'onboarding-1');

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('나의 학습을 기록하고 관리하세요'), findsOneWidget);
    await preview.capture(tester, 'onboarding-2');

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('내신 · 수능 · 논술을 하나로'), findsOneWidget);
    expect(find.text('나의 가능성을 선명하게 만드세요.'), findsOneWidget);
    await preview.capture(tester, 'onboarding-3');

    expect(tester.takeException(), isNull);
  });
}
