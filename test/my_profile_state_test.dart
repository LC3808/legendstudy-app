import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/profile/presentation/profile_page.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';

import 'day7_school_test.dart' show Schools, schoolA, schoolB;
import 'core_ux_test.dart' show ProfileFake;

class PersistedProfile extends ProfileFake {
  @override
  Future<void> updateSchoolSelection({
    String? officeCode,
    String? schoolCode,
  }) async {
    value = UserProfile(
      id: value.id,
      gradeLevel: value.gradeLevel,
      neisOfficeCode: officeCode,
      neisSchoolCode: schoolCode,
    );
  }

  @override
  Future<void> upsertCurrentProfile({
    String? displayName,
    int? gradeLevel,
  }) async {
    value = UserProfile(
      id: value.id,
      gradeLevel: gradeLevel ?? value.gradeLevel,
      neisOfficeCode: value.neisOfficeCode,
      neisSchoolCode: value.neisSchoolCode,
    );
  }
}

class Selection extends SchoolSelection {
  Selection(this.result);
  final Future<School?> Function() result;
  @override
  Future<School?> build() => result();
}

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('MY_RENDER')) {
      await (FontLoader('MyPreview')..addFont(
            File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                .readAsBytes()
                .then((b) => ByteData.sublistView(b)),
          ))
          .load();
    }
  });
  for (final mode in ['unset', 'set', 'loading', 'error']) {
    testWidgets('MY school/grade $mode at 360px 2x', (t) async {
      t.view.physicalSize = const Size(360, 640);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final c = ProviderContainer(
        retry: (_, _) => null,
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('a')),
          ),
          schoolSelectionProvider.overrideWith(
            () => Selection(() {
              if (mode == 'loading') return Completer<School?>().future;
              if (mode == 'error') return Future.error(StateError('offline'));
              return Future.value(mode == 'set' ? schoolA : null);
            }),
          ),
          currentProfileProvider.overrideWith((ref) {
            if (mode == 'loading') return Completer<UserProfile?>().future;
            if (mode == 'error') throw StateError('offline');
            return mode == 'set'
                ? const UserProfile(id: 'a', gradeLevel: 3)
                : null;
          }),
        ],
      );
      addTearDown(c.dispose);
      final frame = GlobalKey();
      await t.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            theme: AppTheme.light.copyWith(
              textTheme: AppTheme.light.textTheme.apply(
                fontFamily: 'MyPreview',
              ),
            ),
            home: Scaffold(
              body: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(2)),
                child: RepaintBoundary(key: frame, child: const ProfilePage()),
              ),
            ),
          ),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 50));
      if (mode == 'set') {
        expect(find.text(schoolA.name), findsOneWidget);
        expect(find.text('고등학교 3학년'), findsOneWidget);
        expect(find.text('변경'), findsNWidgets(2));
      } else if (mode == 'unset') {
        expect(find.text('학교를 설정해 주세요'), findsOneWidget);
        expect(find.text('학년을 설정해 주세요'), findsOneWidget);
        expect(find.text('설정'), findsNWidgets(2));
      } else {
        expect(find.text('학교를 설정해 주세요'), findsNothing);
        expect(find.text('학년을 설정해 주세요'), findsNothing);
        expect(find.text('설정'), findsNothing);
        if (mode == 'error') expect(find.text('재시도'), findsNWidgets(2));
        if (mode == 'loading') {
          expect(find.byType(LinearProgressIndicator), findsNWidgets(2));
        }
      }
      await t.pump();
      expect(t.takeException(), isNull);
      if (const bool.fromEnvironment('MY_RENDER') && mode == 'set') {
        await t.runAsync(() async {
          final boundary =
              frame.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          File('/private/tmp/my-configured-2x.png')
              .writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
      }
    });
  }
  test(
    'canonical providers update, logout/login and fresh container restore',
    () async {
      final repo = PersistedProfile();
      repo.value = UserProfile(
        id: 'a',
        gradeLevel: 2,
        neisOfficeCode: schoolA.officeCode,
        neisSchoolCode: schoolA.schoolCode,
      );
      final auth = StreamController<AuthStatus>.broadcast();
      final c = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith((ref) => auth.stream),
          profileRepositoryProvider.overrideWithValue(repo),
          schoolRepositoryProvider.overrideWithValue(Schools()),
        ],
      );
      addTearDown(() async {
        c.dispose();
        await auth.close();
      });
      c.listen(currentProfileProvider, (_, _) {});
      c.listen(schoolSelectionProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      auth.add(const AuthStatus('a'));
      await Future<void>.delayed(Duration.zero);
      expect((await c.read(currentProfileProvider.future))?.gradeLevel, 2);
      expect(
        (await c.read(schoolSelectionProvider.future))?.name,
        schoolA.name,
      );
      await c.read(schoolSelectionProvider.notifier).select(schoolB);
      expect(c.read(schoolSelectionProvider).value?.name, schoolB.name);
      await repo.upsertCurrentProfile(gradeLevel: 3);
      c.invalidate(currentProfileProvider);
      expect((await c.read(currentProfileProvider.future))?.gradeLevel, 3);
      auth.add(const AuthStatus(null));
      await Future<void>.delayed(Duration.zero);
      expect(await c.read(currentProfileProvider.future), isNull);
      expect(await c.read(schoolSelectionProvider.future), isNull);
      auth.add(const AuthStatus('a'));
      await Future<void>.delayed(Duration.zero);
      expect((await c.read(currentProfileProvider.future))?.gradeLevel, 3);
      expect(
        (await c.read(schoolSelectionProvider.future))?.name,
        schoolB.name,
      );
      final restored = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('a')),
          ),
          profileRepositoryProvider.overrideWithValue(repo),
          schoolRepositoryProvider.overrideWithValue(Schools()),
        ],
      );
      addTearDown(restored.dispose);
      final authSub = restored.listen(authStateProvider, (_, _) {});
      addTearDown(authSub.close);
      await restored.read(authStateProvider.future);
      expect(
        (await restored.read(schoolSelectionProvider.future))?.name,
        schoolB.name,
      );
      expect(
        (await restored.read(currentProfileProvider.future))?.gradeLevel,
        3,
      );
    },
  );
}
