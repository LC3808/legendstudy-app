import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/materials/application/search_controller.dart';

import 'support/search_fake.dart';

import 'package:legendstudy_app/shared/widgets/shell_widgets.dart';
import 'package:legendstudy_app/features/home/presentation/home_page.dart';
import 'package:legendstudy_app/features/materials/presentation/materials_page.dart';

import 'dart:io';

import 'package:legendstudy_app/features/study/trends/study_bar_chart.dart';

import 'package:legendstudy_app/features/study/domain/study_models.dart';

import 'package:legendstudy_app/features/study/trends/study_trend_page.dart';
import 'package:legendstudy_app/features/study/trends/study_trends.dart';
import 'package:legendstudy_app/features/lab/score_summary.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/profile/presentation/profile_page.dart';
import 'package:legendstudy_app/features/profile/presentation/profile_edit_page.dart';
import 'package:legendstudy_app/features/profile/presentation/settings_page.dart';
import 'package:legendstudy_app/features/profile/presentation/school_page.dart';
import 'package:legendstudy_app/features/lab/lab_page.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';
import 'package:legendstudy_app/features/study/study_providers.dart';
import 'package:legendstudy_app/features/study/presentation/study_page.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';

import 'core_ux_test.dart' as preview;
import 'day7_school_test.dart' show Schools, schoolA;
import 'study_core_test.dart' show TestClock, TestStore, TestRepo;

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('CORE_RENDER')) return;
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('CorePreview')..addFont(
          File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
              .readAsBytes()
              .then(ByteData.sublistView),
        ))
        .load();
  });
  for (final size in [const Size(360, 640), const Size(428, 926)]) {
    for (final scale in [1.0, 2.0]) {
      for (final screen in [
        'home',
        'materials',
        'timer',
        'guest-my',
        'guest-settings',
        'my',
        'my-unset',
        'settings',
        'school',
        'profile',
        'lab',
        'mock',
        'trend',
        'trend-data',
        'scores',
      ]) {
        testWidgets('mobile IA $screen ${size.width} $scale', (t) async {
          t.view.physicalSize = size;
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final repo = preview.ProfileFake()
            ..value = UserProfile(
              id: 'a',
              displayName: screen == 'my-unset' ? null : '아주긴나만의레전드스터디닉네임',
              gradeLevel: 3,
              neisOfficeCode: schoolA.officeCode,
              neisSchoolCode: schoolA.schoolCode,
            );
          final clock = TestClock();
          final study = StudyController(
            clock,
            TestStore(),
            () => TestRepo('a'),
            ticking: false,
          );
          study.identity(null, resolved: true);
          await study.settled;
          if (screen == 'mock') study.selectMock(true);
          if (screen == 'home') {
            await study.start();
            clock.advance(11 * 60000);
            await study.end();
          }
          final page = switch (screen) {
            'my' || 'my-unset' || 'guest-my' => const ProfilePage(),
            'home' => const HomePage(),
            'materials' => const MaterialsPage(),
            'settings' || 'guest-settings' => const SettingsPage(),
            'school' => const SchoolPage(),
            'profile' => const ProfileEditPage(),
            'lab' => const LabPage(),
            'trend' || 'trend-data' => const StudyTrendPage(),
            'scores' => const ScoreOverviewPage(),
            _ => const StudyPage(),
          };
          await t.pumpWidget(
            ProviderScope(
              overrides: [
                searchRepositoryProvider.overrideWithValue(
                  FakeSearchRepository()..pageSize = 5,
                ),
                trendRemoteProvider.overrideWith(
                  (ref, bounds) async => screen != 'trend-data'
                      ? []
                      : [
                          for (var i = 0; i < 14; i++)
                            StudyRecord(
                              id: 'fixture-$i',
                              startedMs:
                                  dayStartMs(
                                    koreanDay(study.nowMs)
                                        .subtract(Duration(days: i)),
                                  ) +
                                  3600000,
                              endedMs:
                                  dayStartMs(
                                    koreanDay(study.nowMs)
                                        .subtract(Duration(days: i)),
                                  ) +
                                  3600000 +
                                  (i + 1) * 60000,
                              segments: [ActiveSegment(0, (i + 1) * 60000)],
                            ),
                        ],
                ),
                authStateProvider.overrideWith(
                  (ref) => Stream.value(
                    AuthStatus(screen.startsWith('guest-') ? null : 'a'),
                  ),
                ),
                profileRepositoryProvider.overrideWithValue(repo),
                schoolRepositoryProvider.overrideWithValue(Schools()),
                studyControllerProvider.overrideWith((ref) => study),
              ],
              child: preview.app(page, scale: scale),
            ),
          );
          await t.pumpAndSettle();
          expect(t.takeException(), isNull);
          // Shared surface audit on every responsive fixture, including offscreen groups.
          for (final element in find.byType(LsCard).evaluate()) {
            final card = element.widget as LsCard;
            final container = element.findRenderObject();
            expect(container, isNotNull);
            final decorated = find.descendant(of: find.byWidget(card), matching: find.byType(Container)).first;
            final surface = t.widget<Container>(decorated).decoration! as BoxDecoration;
            final major = card.level == LsSurfaceLevel.major &&
                element.findAncestorWidgetOfExactType<LsCard>() == null;
            expect(surface.color, AppTokens.surface);
            expect(surface.border, Border.all(color: major ? AppTokens.majorSurfaceBorder : AppTokens.cardBorder));
            expect(surface.boxShadow, major ? AppTokens.majorSurfaceShadow : isNull);
          }
          if (screen == 'materials') {
            expect(find.byKey(const Key('materials-search-surface')), findsOneWidget);
            for (final tile in find.byType(SearchResultTile).evaluate()) {
              final card = t.widget<LsCard>(find.descendant(of: find.byWidget(tile.widget), matching: find.byType(LsCard)));
              expect(card.level, LsSurfaceLevel.nested);
            }
            expect(find.text('검색·필터'), findsNothing);
            expect(find.text('최신 시험순 · 첨부 종류는 등록 정보 기준'), findsNothing);
            await t.ensureVisible(find.byType(SearchResultTile).first);
            await t.pumpAndSettle();
            await preview.capture(
              t,
              'ia-material-results-${size.width.toInt()}-${scale.toInt()}x',
            );
            await t.drag(
              find.byType(SingleChildScrollView).first,
              const Offset(0, 2000),
            );
            await t.pumpAndSettle();
          }
          if (screen == 'my') {
            expect(find.text('프로필 편집'), findsNothing);
            expect(find.text('프로필 설정'), findsNothing);
            expect(find.text('공부하러 가기'), findsOneWidget);
            expect(find.text('공부 추이 보기'), findsOneWidget);
            expect(find.text('내신'), findsOneWidget);
            expect(find.text('저장한 자료'), findsOneWidget);
            final trend = t.getTopLeft(find.text('공부 추이 보기'));
            expect(find.widgetWithText(LsListRow, '공부하러 가기'), findsOneWidget);
            expect(find.byType(Divider), findsWidgets);
            final timer = t.getTopLeft(find.text('공부하러 가기'));
            expect(
              trend.dy < timer.dy ||
                  (trend.dy == timer.dy && trend.dx < timer.dx),
              true,
            );
          }
          if (screen.startsWith('guest-')) {
            expect(find.widgetWithText(FilledButton, '로그인'), findsOneWidget);
            expect(
              t.getBottomRight(find.widgetWithText(FilledButton, '로그인')).dy,
              lessThanOrEqualTo(size.height),
            );
            if (screen == 'guest-my') {
              expect(find.text('공부 추이 보기'), findsNothing);
              expect(find.text('저장한 자료'), findsNothing);
            }
          }
          if (screen == 'home') {
            expect(find.text('오늘 공부'), findsOneWidget);
            expect(find.text('11분'), findsOneWidget);
            final labelRect = t.getRect(find.text('오늘 공부'));
            final valueRect = t.getRect(find.text('11분'));
            // Row alignment centers the smaller label; large fonts may wrap.
            expect(
              labelRect.right <= valueRect.left ||
                  labelRect.bottom <= valueRect.top,
              isTrue,
            );
            expect(find.text('학습으로 이동'), findsOneWidget);
          }
          if (screen == 'my-unset') {
            expect(find.text('프로필 설정'), findsOneWidget);
          }
          if (screen == 'lab') {
            expect(find.text('내신 분석'), findsOneWidget);
            expect(find.text('모의고사 분석'), findsOneWidget);
            expect(find.text('논술 준비'), findsOneWidget);
            expect(find.text('성적 분석'), findsNothing);
          }
          if (screen == 'settings') {
            expect(find.text('프로필 수정'), findsOneWidget);
            expect(find.text('기본 정보'), findsOneWidget);
            expect(find.text('계정 관리'), findsNothing);
            expect(find.widgetWithText(OutlinedButton, '로그아웃'), findsOneWidget);
            expect(
              t.getTopLeft(find.text('로그아웃')).dy,
              greaterThan(t.getTopLeft(find.text('약관 및 개인정보')).dy),
            );
            expect(
              t.getTopLeft(find.text('약관 및 개인정보')).dy,
              lessThan(t.getTopLeft(find.text('회원 탈퇴')).dy),
            );
          }
          if (screen.startsWith('trend')) {
            for (final label in ['주별', '월별', '일별']) {
              await t.tap(find.text(label));
              await t.pumpAndSettle();
              expect(t.takeException(), isNull);
              await preview.capture(
                t,
                'ia-$screen-${size.width.toInt()}-${scale.toInt()}x-$label',
              );
              final chart = t.widget<StudyBarChart>(find.byType(StudyBarChart));
              expect(
                t
                    .widgetList<SingleChildScrollView>(
                      find.byType(SingleChildScrollView),
                    )
                    .every((w) => w.scrollDirection == Axis.vertical),
                true,
              );
              final first = t.getTopLeft(
                find.byKey(const ValueKey('study-bar-0')),
              );
              final last = t.getBottomRight(
                find.byKey(ValueKey('study-bar-${chart.totals.length - 1}')),
              );
              expect(first.dx, greaterThanOrEqualTo(0));
              expect(last.dx, lessThanOrEqualTo(size.width));
              expect(first.dx, lessThan(last.dx));
              if (label == '일별') expect(chart.totals.length, 7);
              if (screen == 'trend') {
                expect(chart.totals.every((n) => n == 0), true);
              }
              for (var i = 0; i < chart.totals.length; i++) {
                final bar = t.widget<SizedBox>(
                  find.byKey(ValueKey('study-bar-$i')),
                );
                expect(
                  bar.height,
                  studyBarHeight(
                    chart.totals[i],
                    studyChartCeiling(chart.totals),
                  ),
                );
              }
            }
          }
          await preview.capture(
            t,
            'ia-$screen-${size.width.toInt()}-${scale.toInt()}x',
          );
          if (screen == 'settings') {
            await t.ensureVisible(find.text('회원 탈퇴'));
            await t.pumpAndSettle();
            await preview.capture(
              t,
              'ia-settings-bottom-${size.width.toInt()}-${scale.toInt()}x',
            );
          }
          if (screen == 'timer') {
            await t.ensureVisible(find.byType(StudyBarChart));
            await t.pumpAndSettle();
            final chart = t.widget<StudyBarChart>(find.byType(StudyBarChart));
            expect(chart.totals, study.week);
            expect(chart.labels.length, 7);
            expect(chart.descriptions!.first, '2026.9.8');
            expect(chart.descriptions!.last, '2026.9.14');
            await preview.capture(
              t,
              'ia-timer-chart-${size.width.toInt()}-${scale.toInt()}x',
            );
          }
          if (screen == 'mock') {
            final subject = find.byKey(const ValueKey('mock-subject-국어'));
            await t.ensureVisible(subject);
            await t.tap(subject);
            await t.pumpAndSettle();
            expect(find.text('과목 (선택)'), findsWidgets);
            await t.tap(find.text('수학').last);
            await t.pumpAndSettle();
            expect(t.takeException(), isNull);
            await preview.capture(
              t,
              'ia-mock-subject-${size.width.toInt()}-${scale.toInt()}x',
            );
          }
          if (screen == 'profile') {
            await t.showKeyboard(find.byType(TextField));
            await t.pump();
            await t.ensureVisible(find.text('저장'));
            await t.pump();
            expect(t.takeException(), isNull);
          }
          await t.pumpWidget(const SizedBox());
        });
      }
    }
  }
}
