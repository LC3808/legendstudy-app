import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/profile/presentation/profile_edit_page.dart';
import 'package:legendstudy_app/features/profile/presentation/school_page.dart';
import 'package:legendstudy_app/features/profile/avatar.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/study/trends/study_bar_chart.dart';
import 'package:legendstudy_app/features/study/trends/study_trends.dart';
import 'package:legendstudy_app/app/router.dart';
import 'package:legendstudy_app/features/lab/score_summary.dart';
import 'package:legendstudy_app/app/legendstudy_app.dart';

import 'core_ux_test.dart' show ProfileFake;
import 'day7_school_test.dart' show Schools, schoolA, schoolB;
import 'avatar_test.dart' show Photos, Picker, DelayedPicker, png;

class Saves extends ProfileFake {
  final pending = Completer<void>();
  int schoolWrites = 0;
  bool failSchool = false;
  @override
  Future<void> updateSchoolSelection({
    String? officeCode,
    String? schoolCode,
  }) async {
    schoolWrites++;
    if (failSchool) throw StateError('offline');
  }

  @override
  Future<void> upsertCurrentProfile({
    String? displayName,
    int? gradeLevel,
    bool clearGrade = false,
  }) async {
    writes++;
    await pending.future;
    if (this.fail) throw StateError('offline');
  }
}

class Pops extends NavigatorObserver {
  int count = 0;
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    count++;
  }
}

Future<void> mountEditor(
  WidgetTester t,
  Widget page,
  Saves repo,
  Pops pops, {
  Photos? photos,
  AvatarPicker? picker,
  Schools? schools,
}) async {
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(const AuthStatus('a')),
        ),
        profileRepositoryProvider.overrideWithValue(repo),
        schoolRepositoryProvider.overrideWithValue(schools ?? Schools()),
        avatarRepositoryProvider.overrideWithValue(photos ?? Photos()),
        avatarPickerProvider.overrideWithValue(picker ?? Picker()),
      ],
      child: MaterialApp(
        navigatorObservers: [pops],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => Scaffold(body: page)),
              ),
              child: const Text('편집 열기'),
            ),
          ),
        ),
      ),
    ),
  );
  await t.tap(find.text('편집 열기'));
  await t.pumpAndSettle();
}

void main() {
  for (final school in [false, true]) {
    for (final fail in [false, true]) {
      testWidgets(
        '${school ? 'school' : 'profile'} save ${fail ? 'failure stays' : 'success pops once'}',
        (t) async {
          final repo = Saves()..fail = fail;
          final pops = Pops();
          await mountEditor(
            t,
            school ? const SchoolPage() : const ProfileEditPage(),
            repo,
            pops,
          );
          if (school) {
            await t.enterText(find.byType(TextField), '테스트');
            await t.testTextInput.receiveAction(TextInputAction.search);
            await t.pumpAndSettle();
            expect(
              t.getTopLeft(find.text('검색 결과')).dy,
              greaterThan(t.getTopLeft(find.byType(TextField)).dy),
            );
            expect(
              t.getTopLeft(find.text(schoolB.name)).dy,
              lessThan(t.getTopLeft(find.text('학년 (선택)')).dy),
            );
            expect(
              t.getTopLeft(find.text(schoolB.name)).dy,
              lessThan(t.getTopLeft(find.text('저장')).dy),
            );
            await t.tap(find.text(schoolB.name));
            await t.pumpAndSettle();
            expect(find.text(schoolB.name), findsNWidgets(2));
            expect(repo.schoolWrites, 0); // Selection is a draft until Save.
            await t.ensureVisible(find.text('설정 안 함'));
            await t.tap(find.text('설정 안 함'));
          }
          await t.ensureVisible(find.text('저장'));
          await t.tap(find.text('저장'));
          await t.pump();
          expect(pops.count, 0);
          final button = t.widget<FilledButton>(find.byType(FilledButton).last);
          expect(button.onPressed, isNull);
          repo.pending.complete();
          await t.pumpAndSettle();
          expect(repo.writes, 1);
          expect(pops.count, fail ? 0 : 1);
          if (fail) expect(find.textContaining('저장하지 못했어요'), findsOneWidget);
          if (school) expect(repo.schoolWrites, 1);
        },
      );
    }
  }
  testWidgets('school write failure does not save grade or pop', (t) async {
    final repo = Saves()..failSchool = true;
    final pops = Pops();
    await mountEditor(t, const SchoolPage(), repo, pops);
    await t.enterText(find.byType(TextField), '테스트');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await t.pumpAndSettle();
    await t.tap(find.text(schoolA.name));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('저장'));
    await t.tap(find.text('저장'));
    await t.pumpAndSettle();
    expect(repo.writes, 0);
    expect(pops.count, 0);
    expect(find.textContaining('학교·학년을 저장하지 못했어요'), findsOneWidget);
  });
  testWidgets(
    'photo pending/failure cannot cause partial-save pop; retry can finish',
    (t) async {
      final repo = Saves(), pops = Pops(), photos = Photos()..fail = true;
      final picker = DelayedPicker();
      await mountEditor(
        t,
        const ProfileEditPage(),
        repo,
        pops,
        photos: photos,
        picker: picker,
      );
      await t.tap(find.byTooltip('프로필 사진 변경'));
      await t.pumpAndSettle();
      await t.tap(find.text('사진 선택'));
      await t.pump();
      expect(
        t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      picker.result.complete(png);
      await t.pumpAndSettle();
      expect(
        t.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(pops.count, 1); // Bottom sheet only, not the editor.
      expect(find.byType(ProfileEditPage), findsOneWidget);
      await t.tap(find.byTooltip('프로필 사진 변경'));
      await t.pumpAndSettle();
      await t.tap(find.text('기본 이미지로 변경'));
      await t.pumpAndSettle();
      await t.tap(find.text('저장'));
      await t.pump();
      repo.pending.complete();
      await t.pumpAndSettle();
      expect(find.byType(ProfileEditPage), findsNothing);
      expect(pops.count, 3); // Two sheets and exactly one editor.
    },
  );

  testWidgets(
    'configured school search stays above Save with long name and 2x keyboard',
    (t) async {
      t.view.physicalSize = const Size(360, 640);
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      const longSchool = School(
        officeCode: 'B10',
        schoolCode: '7010001',
        name: '아주긴이름을가진테스트국제고등학교',
        schoolType: '고등학교',
        address: '테스트 주소',
      );
      final repo = Saves()
        ..value = UserProfile(
          id: 'a',
          neisOfficeCode: schoolA.officeCode,
          neisSchoolCode: schoolA.schoolCode,
          gradeLevel: 2,
        );
      await mountEditor(
        t,
        const SchoolPage(),
        repo,
        Pops(),
        schools: Schools()..results = [longSchool],
      );
      await t.enterText(find.byType(TextField), '테스트');
      await t.showKeyboard(find.byType(TextField));
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.pumpAndSettle();
      expect(
        t.getTopLeft(find.text(longSchool.name)).dy,
        lessThan(t.getTopLeft(find.text('선택한 학교')).dy),
      );
      await t.ensureVisible(find.text(longSchool.name));
      await t.tap(find.text(longSchool.name));
      await t.pumpAndSettle();
      expect(find.text(longSchool.name), findsNWidgets(2));
      await t.ensureVisible(find.text('저장'));
      await t.pump();
      expect(t.takeException(), isNull);
      expect(
        t.getTopLeft(find.text(longSchool.name).first).dy,
        lessThan(t.getTopLeft(find.text('저장')).dy),
      );
    },
  );
  testWidgets(
    'rendered bars preserve 180/90/45/0 ratios and all-zero has no paint',
    (t) async {
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyBarChart(
              labels: ['월', '화', '수', '목'],
              totals: [180, 90, 45, 0],
            ),
          ),
        ),
      );
      for (final entry in {0: 160.0, 1: 80.0, 2: 40.0, 3: 0.0}.entries) {
        expect(
          t.getSize(find.byKey(ValueKey('study-bar-${entry.key}'))).height,
          entry.value,
        );
      }
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StudyBarChart(labels: ['월', '화'], totals: [0, 0]),
          ),
        ),
      );
      for (var i = 0; i < 2; i++) {
        expect(t.getSize(find.byKey(ValueKey('study-bar-$i'))).height, 0);
        expect(
          t.widget<SizedBox>(find.byKey(ValueKey('study-bar-$i'))).child,
          isNull,
        );
      }
    },
  );
  test('seven days, weekday order, compact weekly/monthly labels and dynamic zero-safe ratios', () {
    final day = DateTime.utc(2026, 9, 23);
    final days = trendDates(TrendPeriod.daily, day);
    expect(days.length, 7);
    expect(days.first, DateTime.utc(2026, 9, 17));
    expect(days.last, day);
    expect(trendLabels(TrendPeriod.daily, days), [
      '목',
      '금',
      '토',
      '일',
      '월',
      '화',
      '수',
    ]);
    final weeks = trendLabels(
      TrendPeriod.weekly,
      trendDates(TrendPeriod.weekly, day),
    );
    expect(weeks.where((s) => s.isNotEmpty).toList(), ['8월', '9월']);
    expect(
      trendLabels(TrendPeriod.monthly, trendDates(TrendPeriod.monthly, day)),
      ['4월', '5월', '6월', '7월', '8월', '9월'],
    );
    final max = studyChartCeiling([0, 30, 60, 120, 180]);
    expect(max, 180);
    expect(studyBarHeight(180, max), 160);
    expect(studyBarHeight(90, max), 80);
    expect(studyBarHeight(45, max), 40);
    expect(studyBarHeight(0, max), 0);
    expect(studyBarHeight(0, studyChartCeiling([0, 0])), 0);
  });
  testWidgets(
    'LAB detail routes are independent and old scores URL remains valid',
    (t) async {
      final c = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus(null)),
          ),
        ],
      );
      final router = c.read(routerProvider)..go('/lab');
      await t.pumpWidget(
        UncontrolledProviderScope(container: c, child: const LegendStudyApp()),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('내신 분석'));
      await t.pumpAndSettle();
      expect(find.byType(SchoolScorePage), findsOneWidget);
      expect(find.text('모의고사'), findsNothing);
      expect(find.text('내신 성적 입력과 상세 분석은 아직 지원하지 않아요.'), findsOneWidget);
      router.pop();
      await t.pumpAndSettle();
      await t.tap(find.text('모의고사 분석'));
      await t.pumpAndSettle();
      expect(find.byType(ScoreOverviewPage), findsOneWidget);
      router.go('/lab/scores');
      await t.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/lab/scores');
      expect(find.text('내신'), findsNothing);
      expect(find.text('성적 분석'), findsNothing);
      expect(find.text('모의고사 분석'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      c.dispose();
    },
  );
}
