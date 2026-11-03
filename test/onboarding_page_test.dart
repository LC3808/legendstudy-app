import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'core_ux_test.dart' as preview;

import 'package:legendstudy_app/features/universities/application/university_providers.dart';
import 'package:legendstudy_app/features/universities/domain/university_models.dart';

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
  UserProfile? initial;
  String? status;
  int? grade;
  bool clearedGrade = false;
  bool completed = false;
  int upserts = 0;
  int schoolWrites = 0;
  bool failWrite = false;
  bool failComplete = false;
  int completionAttempts = 0;
  @override
  Future<UserProfile?> fetchCurrentProfile() async =>
      initial ??
      UserProfile(id: 'u1', academicStatus: status, gradeLevel: grade);
  @override
  Future<void> updateSchoolSelection({
    String? officeCode,
    String? schoolCode,
  }) async {
    if (failWrite) throw StateError('offline');
    schoolWrites++;
  }

  @override
  Future<void> upsertCurrentProfile({
    String? displayName,
    int? gradeLevel,
    bool clearGrade = false,
    String? academicStatus,
    bool clearAcademicStatus = false,
  }) async {
    if (failWrite) throw StateError('offline');
    upserts++;
    if (academicStatus != null) status = academicStatus;
    if (gradeLevel != null || clearGrade) {
      grade = clearGrade ? null : gradeLevel;
    }
    clearedGrade = clearGrade;
  }

  @override
  Future<void> markOnboardingComplete() async {
    completionAttempts++;
    if (failComplete) throw StateError('offline completion');
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

class _PendingSchool extends _OneSchool {
  final result = Completer<List<School>>();
  @override
  Future<List<School>> search(String query) => result.future;
}

Future<GoRouter> _mount(
  WidgetTester tester,
  _Repo repo, {
  String? user,
  SchoolRepository? schools,
  bool reduceMotion = false,
  double textScale = 1,
  List<University> universityResults = const [],
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
        universitySearchProvider.overrideWith(
          (ref, query) async => query.isEmpty ? const [] : universityResults,
        ),
      ],
      child: MaterialApp.router(
        theme: const bool.fromEnvironment('CORE_RENDER')
            ? AppTheme.light.copyWith(
                textTheme: AppTheme.light.textTheme.apply(
                  fontFamily: 'CorePreview',
                ),
              )
            : AppTheme.light,
        routerConfig: router,
        builder: (context, child) => RepaintBoundary(
          key: preview.frame,
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              disableAnimations: reduceMotion,
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CORE_RENDER')) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      final font = File('/System/Library/Fonts/AppleSDGothicNeo.ttc');
      if (font.existsSync()) {
        await (FontLoader(
          'CorePreview',
        )..addFont(font.readAsBytes().then(ByteData.sublistView))).load();
      }
    }
  });
  for (final reduced in [false, true]) {
    testWidgets(
      'existing status selection animation honors Reduce Motion $reduced',
      (tester) async {
        await _mount(tester, _Repo(), user: 'u1', reduceMotion: reduced);
        final tile = find.ancestor(
          of: find.text('고등학교 재학생'),
          matching: find.byType(AnimatedContainer),
        );
        final before = tester.widget<AnimatedContainer>(tile).decoration;
        await tester.tap(find.text('고등학교 재학생'));
        await tester.pump();
        final after = tester.widget<AnimatedContainer>(tile);
        expect(
          after.duration,
          reduced ? Duration.zero : const Duration(milliseconds: 160),
        );
        expect(after.decoration, isNot(before));
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
      },
    );
  }

  for (final reduced in [false, true]) {
    testWidgets(
      'RC 360px 200% retains grade and guards rapid navigation $reduced',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = _Repo();
        await _mount(
          tester,
          repo,
          user: 'u1',
          reduceMotion: reduced,
          textScale: 2,
        );
        await tester.tap(find.text('고등학교 재학생'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('다음'));
        await tester.pump();
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();
        expect(find.text('학년과 학교'), findsOneWidget);
        final switcher = tester.widget<AnimatedSwitcher>(
          find.byType(AnimatedSwitcher).first,
        );
        expect(
          switcher.duration,
          reduced ? Duration.zero : const Duration(milliseconds: 300),
        );
        await tester.ensureVisible(find.text('2학년'));
        await tester.tap(find.text('2학년'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('이전'));
        await tester.pumpAndSettle();
        expect(find.text('학년과 학교'), findsOneWidget);
        await tester.tap(find.text('다음'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('나중에 설정할게요'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('설정 완료'));
        await tester.pumpAndSettle();
        expect(repo.grade, 2);
        expect(repo.status, 'student');
        expect(repo.upserts, greaterThanOrEqualTo(2));
        expect(repo.completed, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('guest cannot personalize', (tester) async {
    await _mount(tester, _Repo(), user: null);
    expect(find.text('개인화 설정은 로그인 후 이용할 수 있어요.'), findsOneWidget);
  });

  testWidgets('student → grade → finish persists canonical fields', (
    tester,
  ) async {
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

  testWidgets('retaker skips grade/school and clears grade on finish', (
    tester,
  ) async {
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

  testWidgets('skip completes onboarding without writing status', (
    tester,
  ) async {
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
    bool reduceMotion = false,
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

  testWidgets('D: selecting a result shows the confirmation card', (
    tester,
  ) async {
    await toSchoolStep(tester, schools: _OneSchool());
    await tester.enterText(find.byType(TextField), '레전드');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '검색'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('레전드고등학교'));
    await tester.pumpAndSettle();
    expect(find.text('선택한 학교'), findsNothing);
    expect(find.text('선택 해제'), findsNothing);
    expect(find.text('레전드고등학교로 설정하기'), findsOneWidget);
    expect(find.text('레전드고등학교'), findsWidgets);
  });

  testWidgets('E: 검색 does not finish onboarding or navigate Home', (
    tester,
  ) async {
    final (repo, router) = await toSchoolStep(tester, schools: _NoSchools());
    await tester.enterText(find.byType(TextField), '레전드');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '검색'));
    await tester.pumpAndSettle();
    expect(repo.completed, isFalse);
    expect(repo.upserts, 1);
    expect(router.routeInformationProvider.value.uri.path, '/onboarding');
  });
  testWidgets('school query cannot advance before result confirmation', (
    tester,
  ) async {
    final (repo, _) = await toSchoolStep(tester, schools: _NoSchools());
    await tester.tap(find.text('2학년'));
    await tester.enterText(find.byType(TextField), '레전드');
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('학년과 학교'), findsOneWidget);
    expect(repo.schoolWrites, 0);
    expect(repo.completed, isFalse);
  });

  testWidgets('pending and empty school search never advance or save', (
    tester,
  ) async {
    final schools = _PendingSchool();
    final (repo, _) = await toSchoolStep(tester, schools: schools);
    await tester.enterText(find.byType(TextField), '레전드');
    await tester.tap(find.widgetWithText(OutlinedButton, '검색'));
    await tester.pump();
    await tester.tap(find.text('다음'));
    await tester.pump();
    expect(find.text('학년과 학교'), findsOneWidget);
    schools.result.complete(const []);
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('학년과 학교'), findsOneWidget);
    expect(repo.schoolWrites, 0);
    expect(repo.completed, isFalse);
    // Optional profile remains optional via the explicit skip action.
    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();
    expect(repo.completed, isTrue);
    expect(repo.schoolWrites, 0);
  });

  testWidgets(
    'iPhone keyboard search stays until explicit school confirmation',
    (tester) async {
      final (repo, _) = await toSchoolStep(tester, schools: _OneSchool());
      tester.view.physicalSize = const Size(428, 926);
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '레전드');
      await tester.pumpAndSettle();
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      expect(find.text('학년과 학교'), findsOneWidget);
      expect(repo.schoolWrites, 0);
      expect(repo.completed, isFalse);
      expect(find.text('레전드고등학교로 설정하기'), findsOneWidget);
      await tester.tap(find.text('레전드고등학교로 설정하기'));
      await tester.pumpAndSettle();
      expect(repo.schoolWrites, 1);
      expect(find.text('관심 있는 대학을 선택해 주세요'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('iPhone on-screen search button never advances school step', (
    tester,
  ) async {
    final (repo, _) = await toSchoolStep(tester, schools: _OneSchool());
    tester.view.physicalSize = const Size(428, 926);
    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '레전드');
    await tester.pumpAndSettle();
    final search = find.widgetWithText(OutlinedButton, '검색');
    await tester.ensureVisible(search);
    await tester.pumpAndSettle();
    await tester.tap(search);
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding();
    await tester.pumpAndSettle();
    tester
        .state<ScrollableState>(find.byType(Scrollable).first)
        .position
        .jumpTo(0);
    await tester.pumpAndSettle();
    expect(find.text('학년과 학교'), findsOneWidget);
    expect(find.text('레전드고등학교로 설정하기'), findsOneWidget);
    expect(repo.schoolWrites, 0);
    expect(repo.completed, isFalse);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('compact school keyboard layout at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = Size(scale == 1 ? 428 : 360, 926);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final repo = _Repo();
      await _mount(
        tester,
        repo,
        user: 'u1',
        schools: _OneSchool(),
        textScale: scale,
      );
      await tester.tap(find.text('고등학교 재학생'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      final gradeY = tester.getCenter(find.text('1학년')).dy;
      expect(tester.getCenter(find.text('2학년')).dy, closeTo(gradeY, 1));
      expect(tester.getCenter(find.text('3학년')).dy, closeTo(gradeY, 1));
      await preview.capture(tester, 'school-compact-$scale');
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '레전드');
      await tester.pumpAndSettle();
      final search = find.widgetWithText(OutlinedButton, '검색');
      expect(
        tester
            .getRect(find.byType(TextField))
            .contains(tester.getCenter(search)),
        isTrue,
      );
      expect(find.text('다음'), findsNothing);
      expect(find.text('건너뛰기'), findsNothing);
      await preview.capture(tester, 'school-keyboard-$scale');
      await tester.tap(search);
      await tester.pumpAndSettle();
      expect(repo.completed, isFalse);
      expect(repo.schoolWrites, 0);
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.text('레전드고등학교로 설정하기'), findsOneWidget);
      await preview.capture(tester, 'school-result-$scale');
      expect(tester.takeException(), isNull);
    });
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('university inline search prevents keyboard skip at $scale', (
      tester,
    ) async {
      tester.view.physicalSize = Size(scale == 1 ? 428 : 360, 926);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      final repo = _Repo();
      final router = await _mount(
        tester,
        repo,
        user: 'u1',
        textScale: scale,
        universityResults: const [University(id: 'uni', name: '검수대학교')],
      );
      await tester.tap(find.text('고등학교 재학생'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '검수');
      await tester.pumpAndSettle();
      final skip = find.widgetWithText(FilledButton, '나중에 설정할게요');
      expect(tester.widget<FilledButton>(skip).onPressed, isNull);
      tester.view.viewInsets = const FakeViewPadding(bottom: 336);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.pumpAndSettle();
      final search = find.widgetWithText(OutlinedButton, '검색');
      expect(
        tester
            .getRect(find.byType(TextField))
            .contains(tester.getCenter(search)),
        isTrue,
      );
      expect(find.text('나중에 설정할게요'), findsNothing);
      await preview.capture(tester, 'university-keyboard-$scale');
      await tester.tap(search);
      await tester.pumpAndSettle();
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.text('검수대학교'), findsOneWidget);
      expect(repo.completed, isFalse);
      expect(router.routeInformationProvider.value.uri.path, '/onboarding');
      expect(tester.widget<FilledButton>(skip).onPressed, isNotNull);
      await preview.capture(tester, 'university-result-$scale');
      await tester.tap(skip);
      await tester.pumpAndSettle();
      expect(find.text('어떤 전공에 관심이 있나요?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('skip saves chosen status and grade but never temporary school', (
    tester,
  ) async {
    final (repo, _) = await toSchoolStep(tester, schools: _OneSchool());
    expect(repo.status, 'student');
    await tester.tap(find.text('2학년'));
    await tester.enterText(find.byType(TextField), '레전드');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '검색'));
    await tester.pumpAndSettle();
    expect(find.text('레전드고등학교로 설정하기'), findsOneWidget);
    expect(repo.schoolWrites, 0);
    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();
    expect(repo.grade, 2);
    expect(repo.completed, isTrue);
    expect(repo.schoolWrites, 0);
  });

  testWidgets('school confirmation waits for save and failure stays on step', (
    tester,
  ) async {
    final (repo, _) = await toSchoolStep(tester, schools: _OneSchool());
    await tester.enterText(find.byType(TextField), '레전드');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '검색'));
    await tester.pumpAndSettle();
    repo.failWrite = true;
    await tester.tap(find.text('레전드고등학교로 설정하기'));
    await tester.pumpAndSettle();
    expect(find.text('학년과 학교'), findsOneWidget);
    expect(repo.completed, isFalse);
    expect(repo.schoolWrites, 0);
    repo.failWrite = false;
    await tester.tap(find.text('레전드고등학교로 설정하기'));
    await tester.pumpAndSettle();
    expect(repo.schoolWrites, 1);
    expect(find.text('관심 있는 대학을 선택해 주세요'), findsOneWidget);
  });

  testWidgets('skip independently completes and reports unsaved fields', (
    tester,
  ) async {
    final repo = _Repo();
    final router = await _mount(tester, repo, user: 'u1');
    await tester.tap(find.text('고등학교 재학생'));
    await tester.pumpAndSettle();
    repo.failWrite = true;
    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();
    expect(repo.completed, isTrue);
    expect(repo.status, isNull);
    expect(find.text('일부 정보를 저장하지 못했어요'), findsOneWidget);
    await tester.tap(find.text('저장 없이 계속'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(repo.status, isNull);
  });

  testWidgets('best effort skip preserves grade draft for repeated retry', (
    tester,
  ) async {
    final (repo, router) = await toSchoolStep(tester);
    await tester.tap(find.text('2학년'));
    repo.failWrite = true;
    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다시 저장'));
    await tester.pumpAndSettle();
    expect(find.text('일부 정보를 저장하지 못했어요'), findsOneWidget);
    expect(repo.grade, isNull);
    repo.failWrite = false;
    await tester.tap(find.text('다시 저장'));
    await tester.pumpAndSettle();
    expect(repo.grade, 2);
    expect(repo.status, 'student');
    expect(repo.completionAttempts, 1);
    expect(router.routeInformationProvider.value.uri.path, '/home');
  });

  for (final draftFails in [false, true]) {
    testWidgets(
      'completion failure stays and retries; draft fails $draftFails',
      (tester) async {
        final repo = _Repo();
        final router = await _mount(tester, repo, user: 'u1');
        await tester.tap(find.text('고등학교 재학생'));
        await tester.pumpAndSettle();
        repo.failWrite = draftFails;
        repo.failComplete = true;
        await tester.tap(find.text('건너뛰기'));
        await tester.pumpAndSettle();
        expect(repo.completed, isFalse);
        expect(repo.completionAttempts, 1);
        expect(router.routeInformationProvider.value.uri.path, '/onboarding');
        expect(find.textContaining('온보딩 완료를 기록하지 못했어요'), findsOneWidget);
        expect(find.text('저장 없이 계속'), findsNothing);
        repo.failWrite = repo.failComplete = false;
        await tester.tap(find.text('건너뛰기'));
        await tester.pumpAndSettle();
        expect(repo.status, 'student');
        expect(repo.completed, isTrue);
        expect(router.routeInformationProvider.value.uri.path, '/home');
      },
    );
  }

  testWidgets('resumed profile values survive an untouched skip', (
    tester,
  ) async {
    final repo = _Repo()
      ..initial = const UserProfile(
        id: 'u1',
        academicStatus: 'student',
        gradeLevel: 3,
        neisOfficeCode: 'B10',
        neisSchoolCode: '7010001',
      );
    await _mount(tester, repo, user: 'u1');
    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();
    expect(repo.upserts, 0);
    expect(repo.schoolWrites, 0);
    expect(repo.completed, isTrue);
  });
}
