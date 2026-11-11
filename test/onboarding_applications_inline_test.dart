import 'dart:io';

import 'package:flutter/services.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/applications/application_editor.dart';

import 'core_ux_test.dart' as preview;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/applications/onboarding_applications.dart';
import 'package:legendstudy_app/features/applications/application_repository.dart';
import 'package:legendstudy_app/features/universities/data/university_repository.dart';

import 'application_management_test.dart' show FakeUniversities;

class Ledger {
  final rows = <String, Map<String, dynamic>>{};
  int saves = 0, deletes = 0, events = 0;
  Future<Object?> rpc(String name, Map<String, dynamic> p) async {
    if (name == 'my_applications') {
      return {
        'version': 'applications-v1',
        'has_more': false,
        'items': rows.values.toList(),
      };
    }
    if (name == 'my_application_save') {
      final id = p['p_id'] as String? ?? 'row-${++saves}';
      rows[id] = {
        'id': id,
        'university_id': p['p_university'],
        'university_name_snapshot': '테스트대학교',
        'intended_division': p['p_division'],
        'admission_year': p['p_year'],
        'admission_type': p['p_admission_type'],
        'admission_name': p['p_admission_name'],
        'revision': 1,
        'latest_event': rows[id]?['latest_event'],
      };
      return id;
    }
    if (name == 'my_application_event') {
      events++;
      rows[p['p_id']]!['latest_event'] = {'kind': p['p_kind']};
      return 'event';
    }
    if (name == 'my_application_delete') {
      deletes++;
      rows.remove(p['p_id']);
      return null;
    }
    throw StateError(name);
  }
}

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CORE_RENDER')) {
      final font = File('/System/Library/Fonts/AppleSDGothicNeo.ttc');
      await (FontLoader(
        'Roboto',
      )..addFont(font.readAsBytes().then(ByteData.sublistView))).load();
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    }
  });
  Future<void> mount(
    WidgetTester t,
    Ledger ledger, {
    String owner = 'u',
  }) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          applicationRepositoryProvider.overrideWithValue(
            ApplicationRepository(ledger.rpc, () => owner, owner),
          ),
          universityRepositoryProvider.overrideWithValue(FakeUniversities()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: OnboardingApplications()),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String text) async {
    final f = text == '검색' ? find.byTooltip('검색') : find.text(text).last;
    await t.ensureVisible(f);
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Future<void> field(WidgetTester t, String hint, String value) async {
    final f = find.widgetWithText(TextFormField, hint);
    await t.ensureVisible(f);
    await t.enterText(f, value);
    await t.pumpAndSettle();
  }

  Future<void> add(WidgetTester t, String track) async {
    await tap(t, '지원 대학 추가하기');
    await t.enterText(find.byType(TextField).first, '테스트');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await t.pumpAndSettle();
    await tap(t, '테스트대학교');
    final year = find.byType(DropdownButtonFormField<int>);
    await t.ensureVisible(year);
    await t.tap(year);
    await t.pumpAndSettle();
    await t.tap(find.text('2028학년도').last);
    await t.pumpAndSettle();
    final season = find.byType(DropdownButtonFormField<String>).first;
    await t.ensureVisible(season);
    await t.tap(season);
    await t.pumpAndSettle();
    await t.tap(find.text('정시').last);
    await t.pumpAndSettle();
    await field(t, '모집단위·학과', '경영학과');
    await field(t, '전형명', track);
    await tap(t, '저장');
  }

  testWidgets(
    'inline multiple create edit cancel/delete and persisted remount',
    (t) async {
      final ledger = Ledger();
      await mount(t, ledger);
      await add(t, '논술');
      expect(find.text('지원 내역을 저장했어요.'), findsOneWidget);
      expect(find.text('테스트대학교'), findsOneWidget);
      await add(t, '학생부');
      expect(ledger.rows.length, 2);
      expect(
        ledger.rows.values.every(
          (row) =>
              row['admission_year'] == 2028 && row['admission_type'] == '정시',
        ),
        isTrue,
      );
      await tap(t, '수정');
      await field(t, '모집단위·학과', '경제학과');
      await tap(t, '저장');
      expect(
        ledger.rows.values.any((r) => r['intended_division'] == '경제학과'),
        isTrue,
      );
      expect(
        ledger.events,
        2,
        reason: 'editing details never adds an unrequested status event',
      );
      await tap(t, '수정');
      final status = find.byType(DropdownButtonFormField<String>).last;
      await t.ensureVisible(status);
      await t.tap(status);
      await t.pumpAndSettle();
      await t.tap(find.text('최초합격').last);
      await t.pumpAndSettle();
      await tap(t, '저장');
      expect(
        ledger.events,
        3,
        reason: 'explicit status change appends through the existing event API',
      );
      await tap(t, '삭제');
      await tap(t, '취소');
      expect(ledger.rows.length, 2);
      await tap(t, '삭제');
      await tap(t, '삭제');
      expect(ledger.rows.length, 1);
      await t.pumpWidget(const SizedBox.shrink());
      await mount(t, ledger);
      expect(find.text('테스트대학교'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );
  testWidgets('unsaved close requires confirmation and cancel retains input', (
    t,
  ) async {
    final ledger = Ledger();
    await mount(t, ledger);
    await tap(t, '지원 대학 추가하기');
    await t.enterText(find.byType(TextField).first, '미저장');
    await tap(t, '입력 닫기');
    await tap(t, '계속 입력');
    expect(find.text('미저장'), findsOneWidget);
    await tap(t, '입력 닫기');
    await tap(t, '입력 닫기');
    expect(find.text('지원 대학 추가하기'), findsOneWidget);
    expect(ledger.rows, isEmpty);
  });
  testWidgets('MY shared editor renders external labels and accessible save', (
    t,
  ) async {
    t.view.physicalSize = const Size(430, 932);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    final ledger = Ledger();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          applicationRepositoryProvider.overrideWithValue(
            ApplicationRepository(ledger.rpc, () => 'u', 'u'),
          ),
          universityRepositoryProvider.overrideWithValue(FakeUniversities()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          builder: (context, child) =>
              RepaintBoundary(key: preview.frame, child: child!),
          home: const ApplicationEditor(),
        ),
      ),
    );
    await t.pumpAndSettle();
    await preview.capture(t, 'my-application-form-top');
    await t.ensureVisible(find.text('저장'));
    await t.pumpAndSettle();
    await preview.capture(t, 'my-application-form-bottom');
    expect(t.takeException(), isNull);
  });
}
