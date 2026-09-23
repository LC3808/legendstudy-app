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
          final study = StudyController(
            TestClock(),
            TestStore(),
            () => TestRepo('a'),
            ticking: false,
          );
          study.identity(null, resolved: true);
          await study.settled;
          if (screen == 'mock') study.selectMock(true);
          final page = switch (screen) {
            'my' || 'my-unset' => const ProfilePage(),
            'settings' => const SettingsPage(),
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
                  (ref) => Stream.value(const AuthStatus('a')),
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
          if (screen == 'my') {
            expect(find.text('프로필 편집'), findsNothing);
            expect(find.text('프로필 설정'), findsNothing);
            expect(find.text('공부하러 가기'), findsOneWidget);
            expect(find.text('공부 추이 보기'), findsOneWidget);
            expect(find.text('내신 성적 분석'), findsOneWidget);
            expect(find.text('저장한 자료'), findsOneWidget);
            final trend = t.getTopLeft(find.text('공부 추이 보기'));
            final timer = t.getTopLeft(find.text('공부하러 가기'));
            expect(
              trend.dy < timer.dy ||
                  (trend.dy == timer.dy && trend.dx < timer.dx),
              true,
            );
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
            expect(find.widgetWithText(OutlinedButton, '로그아웃'), findsOneWidget);
            expect(
              t.getTopLeft(find.text('계정 관리')).dy,
              lessThan(t.getTopLeft(find.text('약관 및 개인정보')).dy),
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
              final chart = t.widget<StudyBarChart>(find.byType(StudyBarChart));
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
