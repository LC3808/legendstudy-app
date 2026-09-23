import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/core/config/app_config.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/content/content_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/personal/domain/personal_repositories.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/school/data/neis_school_repository.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';

import 'day5_shell_test.dart' show ShellContent;

const schoolA = School(
  officeCode: 'J10',
  schoolCode: '7530932',
  name: '테스트고등학교',
  schoolType: '고등학교',
  address: '경기도 테스트 주소',
);
const schoolB = School(
  officeCode: 'B10',
  schoolCode: '7010001',
  name: '다른 테스트학교',
  schoolType: '고등학교',
  address: '서울특별시 테스트 주소',
);
const meal = Meal(
  date: '20260911',
  mealType: '중식',
  menuItems: ['쌀밥', '미역국', '김치'],
);
const schoolRow = {
  'ATPT_OFCDC_SC_CODE': 'J10',
  'SD_SCHUL_CODE': '7530932',
  'SCHUL_NM': '테스트고등학교',
  'SCHUL_KND_SC_NM': '고등학교',
  'ORG_RDNMA': '경기도 테스트 주소',
};

class Schools implements SchoolRepository {
  List<School> results = [schoolA, schoolB];
  bool failSearch = false, failMeals = false;
  Completer<List<Meal>>? pendingMeals;
  int searches = 0, mealCalls = 0;
  final dates = <String>[];
  final identities = <String>[];
  @override
  Future<List<School>> search(String query) async {
    if (query.isEmpty) return [];
    searches++;
    if (failSearch) throw const SchoolServiceException();
    return results;
  }

  @override
  Future<School?> find(String officeCode, String schoolCode) async =>
      schoolCode == schoolA.schoolCode ? schoolA : schoolB;
  @override
  Future<List<Meal>> meals(School school, String date) async {
    mealCalls++;
    dates.add(date);
    identities.add(school.identity);
    if (failMeals) throw const SchoolServiceException();
    return pendingMeals?.future ?? [meal];
  }
}

class Profiles implements ProfileRepository {
  UserProfile? profile;
  int writes = 0;
  Completer<void>? pending;
  @override
  Future<UserProfile?> fetchCurrentProfile() async => profile;
  @override
  Future<void> upsertCurrentProfile({
    String? displayName,
    int? gradeLevel,
    bool clearGrade = false,
  }) async {}
  @override
  Future<void> updateSchoolSelection({
    String? officeCode,
    String? schoolCode,
  }) async {
    writes++;
    await pending?.future;
  }
}

void main() {
  test('Korean date changes at UTC 15:00 regardless of device timezone', () {
    expect(koreanDate(DateTime.parse('2026-09-12T14:59:59Z')), '20260912');
    expect(koreanDate(DateTime.parse('2026-09-12T15:00:00Z')), '20260913');
    expect(koreanDate(DateTime.parse('2026-09-13T00:00:00+09:00')), '20260913');
  });
  group('proxy adapter', () {
    late NeisSchoolRepository repository;
    late List<http.Request> requests;
    late List<Map<String, Object?>> rows;
    int status = 200;
    setUp(() {
      requests = [];
      rows = [schoolRow];
      status = 200;
      repository = NeisSchoolRepository(
        MockClient((request) async {
          requests.add(request);
          return http.Response(
            jsonEncode({'rows': rows}),
            status,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }),
        const AppConfig(
          supabaseUrl: 'https://stlhijzpjfgwwdgunlsd.supabase.co',
          supabasePublishableKey: 'sb_publishable_unit_test',
        ),
      );
    });
    test(
      'search maps official fields and bounds requests without NEIS key or JWT',
      () async {
        final result = await repository.search(' 테스트 ');
        expect(result.single.identity, schoolA.identity);
        expect(result.single.address, schoolA.address);
        expect(requests.single.url.path, '/functions/v1/neis');
        expect(requests.single.url.queryParameters, {
          'action': 'search',
          'q': '테스트',
        });
        expect(requests.single.headers.containsKey('authorization'), isFalse);
        expect(requests.single.url.queryParameters.containsKey('KEY'), isFalse);
      },
    );
    test(
      'blank search does not call API; multiple and empty results preserved',
      () async {
        expect(await repository.search('  '), isEmpty);
        expect(requests, isEmpty);
        rows = [
          schoolRow,
          {...schoolRow, 'SD_SCHUL_CODE': 'other'},
        ];
        expect(await repository.search('테스트'), hasLength(2));
        rows = [];
        expect(await repository.search('없는학교'), isEmpty);
        await expectLater(repository.search('a' * 101), throwsFormatException);
      },
    );
    test('API error is a safe domain failure', () async {
      status = 502;
      await expectLater(
        repository.search('테스트'),
        throwsA(isA<SchoolServiceException>()),
      );
    });
    test('exact school lookup refuses unrelated response', () async {
      expect(await repository.find('J10', '7530932'), isNotNull);
      expect(await repository.find('B10', 'other'), isNull);
    });
    test(
      'meal normalizes br variants/newlines but preserves allergy/source text',
      () async {
        rows = [
          {
            ...schoolRow,
            'MLSV_YMD': '20260911',
            'MMEAL_SC_NM': '중식',
            'DDISH_NM': '쌀밥<br/>국 (1.2)<BR />김치\n주스',
          },
        ];
        // Replace literal fixture escape with an actual newline.
        rows[0]['DDISH_NM'] = '쌀밥<br/>국 (1.2)<BR />김치\n주스'.replaceAll(
          r'\n',
          '\n',
        );
        final items = (await repository.meals(schoolA, '20260911')).single;
        expect(items.mealType, '중식');
        expect(items.menuItems, ['쌀밥', '국 (1.2)', '김치', '주스']);
        expect(await repository.meals(schoolA, '20260912'), isEmpty);
        rows = [];
        expect(await repository.meals(schoolA, '20260911'), isEmpty);
      },
    );
  });

  Future<ProviderContainer> mount(
    WidgetTester tester,
    Schools schools, {
    Profiles? profiles,
    Stream<AuthStatus>? auth,
    Stream<String>? clock,
  }) async {
    final c = ProviderContainer(
      overrides: [
        contentRepositoryProvider.overrideWithValue(ShellContent()),
        schoolRepositoryProvider.overrideWithValue(schools),
        profileRepositoryProvider.overrideWithValue(profiles ?? Profiles()),
        authStateProvider.overrideWith(
          (ref) => auth ?? Stream.value(const AuthStatus(null)),
        ),
        koreanTodayProvider.overrideWith(
          (ref) => clock ?? Stream.value('20260911'),
        ),
        tomorrowMealsProvider.overrideWith((ref) async => []),
        koreanMealClockProvider.overrideWithValue(DateTime.utc(2026, 9, 11, 3)),
        mealBoundaryRefreshEnabledProvider.overrideWithValue(false),
      ],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const LegendStudyApp()),
    );
    await tester.pumpAndSettle();
    return c;
  }

  Future<void> search(WidgetTester tester) async {
    await tester.ensureVisible(find.text('학교 설정'));
    await tester.tap(find.text('학교 설정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '테스트');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'guest search submit, select, session notice and save login guidance',
    (tester) async {
      final repo = Schools();
      final profile = Profiles();
      final c = await mount(tester, repo, profiles: profile);
      await tester.tap(find.text('학교 설정'));
      await tester.pumpAndSettle();
      expect(find.text('학교·학년 설정'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '테스트');
      await tester.pumpAndSettle();
      expect(repo.searches, 0);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(find.text(schoolB.name), findsOneWidget);
      await tester.tap(find.text(schoolA.name));
      await tester.pumpAndSettle();
      expect(c.read(schoolSelectionProvider).value?.identity, schoolA.identity);
      expect(profile.writes, 0);
      await tester.ensureVisible(find.text('학교 설정 저장'));
      await tester.tap(find.text('학교 설정 저장'));
      await tester.pumpAndSettle();
      expect(find.text('로그인하면 학교 설정을 저장할 수 있어요.'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('D-DAY'), findsOneWidget);
      expect(find.textContaining('쌀밥'), findsOneWidget);
      expect(
        c.read(routerProvider).routeInformationProvider.value.uri.path,
        '/home',
      );
    },
  );
  testWidgets('school empty and API error retry', (tester) async {
    final repo = Schools()..failSearch = true;
    await mount(tester, repo);
    await search(tester);
    expect(find.text('학교를 불러오지 못했어요.'), findsOneWidget);
    repo.failSearch = false;
    repo.results = [];
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(find.text('검색 결과가 없어요.'), findsOneWidget);
  });
  testWidgets(
    'Home no school, loading, empty and error retry stay inside card',
    (tester) async {
      final repo = Schools()..pendingMeals = Completer<List<Meal>>();
      final c = await mount(tester, repo);
      expect(find.text('학교를 설정하면 오늘 급식을 볼 수 있어요.'), findsOneWidget);
      await c.read(schoolSelectionProvider.notifier).select(schoolA);
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repo.pendingMeals!.complete([]);
      await tester.pumpAndSettle();
      expect(find.text('예정된 급식이 없어요.'), findsOneWidget);
      repo.pendingMeals = null;
      repo.failMeals = true;
      c.invalidate(todayMealsProvider);
      await tester.pumpAndSettle();
      expect(find.text('급식 정보를 불러오지 못했어요.'), findsOneWidget);
      expect(find.text('D-DAY'), findsOneWidget);
      repo.failMeals = false;
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.textContaining('쌀밥'), findsOneWidget);
    },
  );
  testWidgets(
    'school and date changes refresh meals, same state reuses cache',
    (tester) async {
      final clock = StreamController<String>();
      addTearDown(clock.close);
      final repo = Schools();
      final c = await mount(tester, repo, clock: clock.stream);
      clock.add('20260911');
      await tester.pumpAndSettle();
      await c.read(schoolSelectionProvider.notifier).select(schoolA);
      await tester.pumpAndSettle();
      final calls = repo.mealCalls;
      c.read(todayMealsProvider);
      c.read(todayMealsProvider);
      await tester.pumpAndSettle();
      expect(repo.mealCalls, calls);
      await c.read(schoolSelectionProvider.notifier).select(schoolB);
      await tester.pumpAndSettle();
      expect(repo.identities.last, schoolB.identity);
      clock.add('20260912');
      await tester.pumpAndSettle();
      expect(repo.dates.last, '20260912');
      await c.read(schoolSelectionProvider.notifier).select(null);
      await tester.pumpAndSettle();
      expect(find.textContaining('쌀밥'), findsNothing);
    },
  );
  testWidgets(
    'auth save, sign-out clear and late save cannot restore prior owner school',
    (tester) async {
      final auth = StreamController<AuthStatus>();
      addTearDown(auth.close);
      final profiles = Profiles();
      final repo = Schools();
      final c = await mount(
        tester,
        repo,
        profiles: profiles,
        auth: auth.stream,
      );
      auth.add(const AuthStatus('owner-a'));
      await tester.pumpAndSettle();
      await c.read(schoolSelectionProvider.notifier).select(schoolA);
      await tester.pumpAndSettle();
      expect(profiles.writes, 1);
      profiles.pending = Completer<void>();
      final pending = c.read(schoolSelectionProvider.notifier).select(schoolB);
      auth.add(const AuthStatus(null));
      await tester.pumpAndSettle();
      expect(c.read(schoolSelectionProvider).value, isNull);
      profiles.pending!.complete();
      expect(await pending, isFalse);
      await tester.pumpAndSettle();
      expect(c.read(schoolSelectionProvider).value, isNull);
      auth.add(const AuthStatus('owner-b'));
      await tester.pumpAndSettle();
      expect(c.read(schoolSelectionProvider).value, isNull);
    },
  );
  testWidgets(
    'authenticated restored school and guest new session do not share state',
    (tester) async {
      final profiles = Profiles()
        ..profile = const UserProfile(
          id: 'owner-a',
          neisOfficeCode: 'J10',
          neisSchoolCode: '7530932',
        );
      final c = await mount(
        tester,
        Schools(),
        profiles: profiles,
        auth: Stream.value(const AuthStatus('owner-a')),
      );
      expect(c.read(schoolSelectionProvider).value?.identity, schoolA.identity);
      final fresh = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus(null)),
          ),
        ],
      );
      addTearDown(fresh.dispose);
      fresh.listen(authStateProvider, (_, _) {});
      await fresh.read(authStateProvider.future);
      expect(await fresh.read(schoolSelectionProvider.future), isNull);
    },
  );
  testWidgets('school screen fits 360x640 with 2x text', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await mount(tester, Schools());
    await search(tester);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text(schoolA.name));
    await tester.tap(find.text(schoolA.name));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
