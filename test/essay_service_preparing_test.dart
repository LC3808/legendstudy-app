import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';

/// Step 1 — 자연·수리논술 첨삭 공개 보류 안내.
/// The notice is keyed on the existing publication policy (Math evaluation
/// availability + published leaf), not the university or track name, so a held
/// photo/math question warns before the student writes, while a TEXT question
/// in the same flow stays untouched.
void main() {
  Widget host(SourceCatalog catalog) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async {
          if (call.method == 'read') return null;
          return null;
        });
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

  Future<void> openWriter(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    await tester.tap(find.text('시험 대학'));
    await tester.pumpAndSettle();
    // A single-question exam auto-selects its only question, so the CTA is ready.
    final cta = find.widgetWithText(FilledButton, '답안 작성하기');
    await tester.scrollUntilVisible(
      cta,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(cta);
    await tester.pumpAndSettle();
  }

  testWidgets('photo/math question shows the preparing notice before writing', (
    tester,
  ) async {
    await tester.pumpWidget(host(catalogWith('image')));
    await openWriter(tester);
    expect(find.text('수리논술 첨삭 서비스 준비 중'), findsOneWidget);
    expect(find.textContaining('준비가 완료되면 제공됩니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('text question keeps the existing flow without the notice', (
    tester,
  ) async {
    await tester.pumpWidget(host(catalogWith('text')));
    await openWriter(tester);
    expect(find.text('수리논술 첨삭 서비스 준비 중'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
