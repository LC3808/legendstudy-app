import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';

/// §3 자연·수리논술 첨삭 공개 보류 안내.
/// Verifies the whole flow the Owner asked for: select exam/track → publication
/// state is read from the existing policy (Math evaluation availability +
/// published leaf, by Registry question id, never by name) → the preparing
/// notice shows on the SELECTION screen, before any question is picked or
/// written. A published TEXT question in the same flow shows no notice.
void main() {
  Widget host(SourceCatalog catalog) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async => null);
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          (ref) => Stream.value(const AuthStatus('owner')),
        ),
      ],
      child: MaterialApp(home: SourceCatalogPage(catalog: Future.value(catalog))),
    );
  }

  SourceCatalog catalogWith(String inputMode) => SourceCatalog(
    [
      {'sourceUniversityId': 'u', 'name': '시험 대학'},
    ],
    [
      {
        'sourceUniversityId': 'u',
        'key': 'exam',
        'year': 2024,
        'kind': 'admission',
        'track': '자연',
        'verification': 'VERIFIED',
        'questions': [
          {
            'key': 'q1',
            'dbQuestionId': 'canonical-q1',
            'label': '문제 1',
            'inputMode': inputMode,
          },
        ],
      },
    ],
  );

  Future<void> openSelection(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    await tester.tap(find.text('시험 대학'));
    await tester.pumpAndSettle();
  }

  testWidgets('photo/math exam shows the preparing notice on the selection '
      'screen before picking a question', (tester) async {
    await tester.pumpWidget(host(catalogWith('image')));
    await openSelection(tester);
    // Shown right after exam/track selection, above 문항 선택 — not inside the
    // writer and not gated behind picking a question.
    expect(find.text('수리논술 첨삭 서비스 준비 중'), findsOneWidget);
    expect(find.textContaining('준비가 완료되면 제공됩니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('published text exam shows no preparing notice', (tester) async {
    await tester.pumpWidget(host(catalogWith('text')));
    await openSelection(tester);
    expect(find.text('수리논술 첨삭 서비스 준비 중'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
