import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/onboarding/presentation/onboarding_page.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/personal/domain/personal_repositories.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';

// Phase 1.1 restyle guard: the onboarding visuals changed but the FUNCTION must
// not. These tests exercise the flow through the redesigned widgets.
class _Repo implements ProfileRepository {
  String? status;
  int? grade;
  bool clearedGrade = false;
  bool completed = false;
  int upserts = 0;
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
  }) async {
    upserts++;
    status = academicStatus;
    grade = gradeLevel;
    clearedGrade = clearGrade;
  }

  @override
  Future<void> markOnboardingComplete() async {
    completed = true;
  }
}

const _fixtureSchool = School(
  officeCode: 'B10',
  schoolCode: '7010001',
  name: '레전드고등학교',
  schoolType: '고등학교',
  address: '서울특별시',
);

class _NoSchools implements SchoolRepository {
  int searches = 0;
  @override
  Future<List<School>> search(String query) async {
    searches++;
    return const [];
  }

  @override
  Future<School?> find(String officeCode, String schoolCode) async => null;
  @override
  Future<List<Meal>> meals(School school, String date) async => const [];
}

class _OneSchool implements SchoolRepository {
  @override
  Future<List<School>> search(String query) async => const [_fixtureSchool];
  @override
  Future<School?> find(String officeCode, String schoolCode) async =>
      _fixtureSchool;
  @override
  Future<List<Meal>> meals(School school, String date) async => const [];
}

Future<GoRouter> _mount(
  WidgetTester tester,
  _Repo repo, {
  String? user,
  SchoolRepository? schools,
}) async {
  final router = GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(
        path: '/home',
        builder: (_, _) => const Scaffold(body: Text('HOME')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(AuthStatus(user))),
        profileRepositoryProvider.overrideWithValue(repo),
        schoolRepositoryProvider.overrideWithValue(schools ?? _NoSchools()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  testWidgets('guest cannot personalize', (tester) async {
    await _mount(tester, _Repo(), user: null);
    expect(find.text('개인화 설정은 로그인 후 이용할 수 있어요.'), findsOneWidget);
  });

  testWidgets('student → grade → finish persists canonical fields',
      (tester) async {
    final repo = _Repo();
    final router = await _mount(tester, repo, user: 'u1');

    expect(find.text('지금의 나를 알려주세요'), findsOneWidget);
    // Advance is gated until a status is chosen.
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('고등학교 재학생'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.text('학년과 학교'), findsOneWidget);
    await tester.tap(find.text('2학년'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음')); // 학년/학교 → 관심 대학
    await tester.pumpAndSettle();
    await tester.tap(find.text('나중에 설정할게요')); // 관심 대학(0개) → 희망 전공
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정 완료'));
    await tester.pumpAndSettle();

    expect(repo.status, 'student');
    expect(repo.grade, 2);
    expect(repo.completed, isTrue);
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(tester.takeException(), isNull);
  });

  testWidgets('retaker skips grade/school and clears grade on finish',
      (tester) async {
    final repo = _Repo();
    await _mount(tester, repo, user: 'u1');
    await tester.tap(find.text('N수생 · 검정고시 등'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.text('학년·학교는 재학생 전용이에요'), findsOneWidget);
    expect(find.text('학년'), findsNothing);
    await tester.tap(find.text('다음')); // 확인 → 관심 대학
    await tester.pumpAndSettle();
    await tester.tap(find.text('나중에 설정할게요')); // 관심 대학(0개) → 희망 전공
    await tester.pumpAndSettle();
    await tester.tap(find.text('설정 완료'));
    await tester.pumpAndSettle();

    expect(repo.status, 'retaker');
    expect(repo.grade, isNull);
    expect(repo.clearedGrade, isTrue);
    expect(repo.completed, isTrue);
  });

  testWidgets('skip completes onboarding without writing status', (tester) async {
    final repo = _Repo();
    final router = await _mount(tester, repo, user: 'u1');
    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();
    expect(repo.completed, isTrue);
    expect(repo.upserts, 0);
    expect(router.routeInformationProvider.value.uri.path, '/home');
  });

  testWidgets('renders without overflow on a small phone', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _mount(tester, _Repo(), user: 'u1');
    await tester.tap(find.text('고등학교 재학생'));
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  // --- School Search UX hotfix (Owner device QA) ---
  // A tall surface so the lazy ListView builds the 검색 button and results.

  Future<(_Repo, GoRouter)> toSchoolStep(
    WidgetTester tester, {
    SchoolRepository? schools,
  }) async {
    tester.view.physicalSize = const Size(1000, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = _Repo();
    final router = await _mount(tester, repo, user: 'u1', schools: schools);
    await tester.tap(find.text('고등학교 재학생'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    return (repo, router);
  }

  testWidgets('C: empty query disables the 검색 button', (tester) async {
    await toSchoolStep(tester);
    final button = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '검색'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('A: on-screen 검색 button runs the search', (tester) async {
    final schools = _NoSchools();
    await toSchoolStep(tester, schools: schools);
    await tester.enterText(find.byType(TextField), '레전드');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '검색'));
    await tester.pumpAndSettle();
    expect(schools.searches, greaterThan(0));
    expect(find.text('검색 결과가 없어요.'), findsOneWidget);
  });

  testWidgets('B: keyboard search key runs the same search', (tester) async {
    final schools = _NoSchools();
    await toSchoolStep(tester, schools: schools);
    await tester.enterText(find.byType(TextField), '레전드');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(schools.searches, greaterThan(0));
    expect(find.text('검색 결과가 없어요.'), findsOneWidget);
  });

  testWidgets('D: selecting a result shows the confirmation card',
      (tester) async {
    await toSchoolStep(tester, schools: _OneSchool());
    await tester.enterText(find.byType(TextField), '레전드');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '검색'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('레전드고등학교'));
    await tester.pumpAndSettle();
    expect(find.text('선택한 학교'), findsOneWidget);
    expect(find.text('레전드고등학교'), findsWidgets);
  });

  testWidgets('E: 검색 does not finish onboarding or navigate Home',
      (tester) async {
    final (repo, router) = await toSchoolStep(tester, schools: _NoSchools());
    await tester.enterText(find.byType(TextField), '레전드');
    await tester.tap(find.widgetWithText(OutlinedButton, '검색'));
    await tester.pumpAndSettle();
    expect(repo.completed, isFalse);
    expect(repo.upserts, 0);
    expect(router.routeInformationProvider.value.uri.path, '/onboarding');
  });
}
