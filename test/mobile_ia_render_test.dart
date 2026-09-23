import 'dart:io';

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
        'settings',
        'school',
        'profile',
        'lab',
        'mock',
      ]) {
        testWidgets('mobile IA $screen ${size.width} $scale', (t) async {
          t.view.physicalSize = size;
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          final repo = preview.ProfileFake()
            ..value = UserProfile(
              id: 'a',
              displayName: '아주긴나만의레전드스터디닉네임',
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
            'my' => const ProfilePage(),
            'settings' => const SettingsPage(),
            'school' => const SchoolPage(),
            'profile' => const ProfileEditPage(),
            'lab' => const LabPage(),
            _ => const StudyPage(),
          };
          await t.pumpWidget(
            ProviderScope(
              overrides: [
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
