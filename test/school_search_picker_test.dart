import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'core_ux_test.dart' as preview;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/school/domain/school.dart';
import 'package:legendstudy_app/features/school/presentation/school_search_picker.dart';
import 'package:legendstudy_app/features/school/school_providers.dart';

import 'day7_school_test.dart' show schoolA, schoolB, Schools;

class PendingSchools extends Schools {
  final pending = Completer<List<School>>();
  @override
  Future<List<School>> search(String query) => pending.future;
}

void main() {
  Future<void> mount(
    WidgetTester t,
    Schools repo,
    ValueChanged<School?> changed, {
    bool reduce = false,
  }) async {
    await t.pumpWidget(
      ProviderScope(
        overrides: [schoolRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SchoolSearchPicker(onChanged: changed),
              ),
            ),
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets(
    'first result, alternate, edit reset, empty and address omission',
    (t) async {
      School? draft;
      final repo = Schools();
      await mount(t, repo, (s) => draft = s);
      await t.enterText(find.byType(TextField), '테스트');
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.pumpAndSettle();
      expect(draft, schoolA);
      expect(find.text(schoolA.address), findsNothing);
      expect(find.text(schoolA.name), findsOneWidget);
      await t.tap(find.text(schoolB.name));
      await t.pumpAndSettle();
      expect(draft, schoolB);
      await t.enterText(find.byType(TextField), '없음');
      await t.pumpAndSettle();
      expect(draft, isNull);
      expect(find.text(schoolA.name), findsNothing);
      repo.results = [];
      await t.testTextInput.receiveAction(TextInputAction.search);
      await t.pumpAndSettle();
      expect(draft, isNull);
      expect(find.text('검색 결과가 없어요.'), findsOneWidget);
    },
  );

  testWidgets('late response cannot select a school after query changes', (
    t,
  ) async {
    School? draft;
    final repo = PendingSchools();
    await mount(t, repo, (s) => draft = s);
    await t.enterText(find.byType(TextField), '테스트');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await t.pump();
    await t.enterText(find.byType(TextField), '새 검색');
    repo.pending.complete([schoolA]);
    await t.pumpAndSettle();
    expect(draft, isNull);
    expect(find.text(schoolA.name), findsNothing);
  });

  for (final reduce in [false, true]) {
    testWidgets(
      'placeholder motion obeys reduce motion $reduce and stops on touch',
      (t) async {
        await mount(t, Schools(), (_) {}, reduce: reduce);
        expect(find.text('서울고등학교'), findsOneWidget);
        await t.pump(const Duration(seconds: 3));
        await t.pump(const Duration(milliseconds: 400));
        expect(find.text(reduce ? '서울고등학교' : '별내고등학교'), findsOneWidget);
        await t.tap(find.byType(TextField));
        await t.pumpAndSettle();
        await t.pump(const Duration(seconds: 6));
        expect(find.text('학교 이름을 검색해 주세요'), findsOneWidget);
        expect(find.text('진접고등학교'), findsNothing);
      },
    );
  }
  testWidgets('school cards fit a phone and expose one selected result', (
    t,
  ) async {
    t.view.physicalSize = const Size(360, 800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    if (const bool.fromEnvironment('CORE_RENDER')) {
      await t.runAsync(() async {
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
        final font = File('/System/Library/Fonts/AppleSDGothicNeo.ttc');
        await (FontLoader(
          'CorePreview',
        )..addFont(font.readAsBytes().then(ByteData.sublistView))).load();
      });
    }
    await t.pumpWidget(
      ProviderScope(
        overrides: [schoolRepositoryProvider.overrideWithValue(Schools())],
        child: preview.app(
          Padding(
            padding: const EdgeInsets.all(20),
            child: SchoolSearchPicker(onChanged: (_) {}),
          ),
        ),
      ),
    );
    await t.enterText(find.byType(TextField), '테스트');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    await preview.capture(t, 'school-search-v2');
    expect(t.takeException(), isNull);
  });
}
