import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/personal/domain/personal_models.dart';
import 'package:legendstudy_app/features/personal/personal_providers.dart';
import 'package:legendstudy_app/features/profile/presentation/school_page.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';

import 'day7_school_test.dart' show Schools, schoolA, schoolB;
import 'device_second_corrections_test.dart' show Saves, Pops, mountEditor;

class StoredProfile extends Saves {
  final pairs = <(String?, String?)>[];
  @override
  Future<void> updateSchoolSelection({
    String? officeCode,
    String? schoolCode,
  }) async {
    if (failSchool) throw StateError('offline');
    pairs.add((officeCode, schoolCode));
    value = UserProfile(
      id: value.id,
      displayName: value.displayName,
      academicStatus: value.academicStatus,
      gradeLevel: value.gradeLevel,
      neisOfficeCode: officeCode,
      neisSchoolCode: schoolCode,
    );
  }
}

StoredProfile existing() => StoredProfile()
  ..value = UserProfile(
    id: 'a',
    displayName: '기존 학생',
    academicStatus: 'student',
    gradeLevel: 2,
    neisOfficeCode: schoolA.officeCode,
    neisSchoolCode: schoolA.schoolCode,
  );

void main() {
  testWidgets(
    'MY unset requires confirmation, clears both codes and preserves profile',
    (t) async {
      final repo = existing();
      await mountEditor(t, const SchoolPage(), repo, Pops());
      await t.ensureVisible(find.text('학교 미설정으로 변경'));
      await t.tap(find.text('학교 미설정으로 변경'));
      await t.pump(const Duration(milliseconds: 400));
      expect(repo.pairs, isEmpty);
      await t.tap(find.text('취소'));
      await t.pumpAndSettle();
      expect(repo.pairs, isEmpty);
      await t.tap(find.text('학교 미설정으로 변경'));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('미설정으로 변경'));
      await t.pumpAndSettle();
      expect(repo.pairs, [(null, null)]);
      expect(repo.value.displayName, '기존 학생');
      expect(repo.value.academicStatus, 'student');
      expect(repo.value.gradeLevel, 2);
      expect(repo.writes, 0);
      expect(find.text('학교 미설정으로 변경'), findsNothing);
    },
  );

  testWidgets('failed unset keeps school and can retry', (t) async {
    final repo = existing()..failSchool = true;
    await mountEditor(t, const SchoolPage(), repo, Pops());
    for (final fail in [true, false]) {
      repo.failSchool = fail;
      await t.ensureVisible(find.text('학교 미설정으로 변경'));
      await t.tap(find.text('학교 미설정으로 변경'));
      await t.pump(const Duration(milliseconds: 400));
      await t.tap(find.text('미설정으로 변경'));
      await t.pumpAndSettle();
      expect(repo.value.neisSchoolCode, fail ? schoolA.schoolCode : null);
    }
    expect(repo.pairs, [(null, null)]);
  });

  testWidgets(
    'named CTA follows first and alternate choice; saved pair restores in fresh container',
    (t) async {
      final repo = existing();
      await mountEditor(t, const SchoolPage(), repo, Pops());
      await t.enterText(find.byType(TextField), '테스트');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.pumpAndSettle();
      expect(find.text('${schoolA.name}로 설정하기'), findsOneWidget);
      expect(repo.pairs, isEmpty);
      await t.ensureVisible(find.text(schoolB.name));
      await t.tap(find.text(schoolB.name));
      await t.pumpAndSettle();
      expect(find.text('${schoolB.name}로 설정하기'), findsOneWidget);
      expect(repo.pairs, isEmpty);
      await t.ensureVisible(find.text('${schoolB.name}로 설정하기'));
      await t.tap(find.text('${schoolB.name}로 설정하기'));
      repo.pending.complete();
      await t.pumpAndSettle();
      expect(repo.pairs, [(schoolB.officeCode, schoolB.schoolCode)]);
      await t.pumpWidget(const SizedBox());
      final container = ProviderContainer(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('a')),
          ),
          profileRepositoryProvider.overrideWithValue(repo),
          schoolRepositoryProvider.overrideWithValue(Schools()),
        ],
      );
      addTearDown(container.dispose);
      final auth = container.listen(authStateProvider, (_, _) {});
      await container.read(authStateProvider.future);
      final selection = container.listen(schoolSelectionProvider, (_, _) {});
      expect(
        (await container.read(schoolSelectionProvider.future))?.identity,
        schoolB.identity,
      );
      expect(repo.value.displayName, '기존 학생');
      auth.close();
      selection.close();
    },
  );
}
