import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/profile/presentation/aspirations_card.dart';
import 'package:legendstudy_app/features/profile/presentation/aspirations_page.dart';
import 'package:legendstudy_app/features/profile/presentation/school_page.dart';
import 'package:legendstudy_app/features/profile/data/intended_major_repository.dart';
import 'package:legendstudy_app/features/universities/application/university_providers.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';

import 'day7_school_test.dart' show Schools, schoolA;
import 'device_second_corrections_test.dart' show Saves, Pops, mountEditor;
import 'refinement_ui_test.dart' show Interests;

void main() {
  testWidgets('MY aspirations opens university editor, never school editor', (
    t,
  ) async {
    final repo = Saves()
      ..value = UserProfile(
        id: 'a',
        displayName: '학생',
        onboardingCompletedAt: DateTime(2026),
      );
    final c = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(const AuthStatus('a')),
        ),
        profileRepositoryProvider.overrideWithValue(repo),
        schoolRepositoryProvider.overrideWithValue(Schools()),
        interestedUniversitiesProvider.overrideWith(() => Interests([])),
        intendedMajorProvider.overrideWith((ref) async => null),
        applicationLabelsProvider.overrideWith((ref) async => []),
      ],
    );
    addTearDown(c.dispose);
    await t.pumpWidget(
      UncontrolledProviderScope(container: c, child: const LegendStudyApp()),
    );
    await t.pumpAndSettle();
    final router = c.read(routerProvider);
    router.go('/my');
    await t.pumpAndSettle();
    final edit = find
        .descendant(
          of: find.byType(AspirationsCard),
          matching: find.byType(TextButton),
        )
        .last;
    await t.ensureVisible(edit);
    await t.tap(edit);
    await t.pumpAndSettle();
    expect(find.byType(AspirationsPage), findsOneWidget);
    expect(
      GoRouterState.of(t.element(find.byType(AspirationsPage))).uri.path,
      '/my/aspirations',
    );
    expect(find.byType(SchoolPage), findsNothing);
    expect(find.text('재학 중인 고등학교'), findsNothing);
    expect(repo.schoolWrites, 0);
    expect(repo.writes, 0);
    router.pop();
    await t.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/my');
  });

  testWidgets(
    'school deletion requires explicit confirmation; cancel preserves school',
    (t) async {
      final repo = Saves()
        ..value = UserProfile(
          id: 'a',
          neisOfficeCode: schoolA.officeCode,
          neisSchoolCode: schoolA.schoolCode,
          gradeLevel: 2,
        );
      await mountEditor(t, const SchoolPage(), repo, Pops());
      expect(find.text('희망 학과·관심 전공'), findsNothing);
      expect(find.text('관심 대학'), findsNothing);
      await t.ensureVisible(find.text('선택 해제'));
      await t.tap(find.text('선택 해제'));
      await t.pumpAndSettle();
      expect(repo.schoolWrites, 0);
      await t.ensureVisible(find.text('저장'));
      await t.tap(find.text('저장'));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.text('저장한 고등학교를 해제할까요?'), findsOneWidget);
      await t.tap(find.text('취소'));
      await t.pumpAndSettle();
      expect(repo.schoolWrites, 0);
      expect(repo.writes, 0);
    },
  );
}
