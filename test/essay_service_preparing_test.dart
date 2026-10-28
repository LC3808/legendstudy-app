import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/math_gateway.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';

/// §1 자연·수리논술 첨삭 공개 보류 안내 — 전수 일관.
/// The notice keys on the server's serviceable-exam set (service-status), not
/// inputMode (which is missing from the browse projection) or the exam/track
/// name. An enterable exam that is NOT serviceable shows the notice on the
/// SELECTION screen, before a question is picked; a serviceable exam shows none.
void main() {
  Widget host(SourceCatalog catalog, Set<String> serviceable) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SourceDraftGateway.channel,
          (call) async => null,
        );
    return ProviderScope(
      overrides: [
        publicServiceUniversitiesProvider.overrideWith(
          (ref, owner) async => {'u'},
        ),
        authStateProvider.overrideWith(
          (ref) => Stream.value(const AuthStatus('owner')),
        ),
        serviceExamIdsProvider('owner')
            .overrideWith((ref) async => serviceable),
      ],
      child: MaterialApp(
        home: SourceCatalogPage(catalog: Future.value(catalog)),
      ),
    );
  }

  SourceCatalog catalogFor() => SourceCatalog(
    [
      {'sourceUniversityId': 'u', 'universityId': 'u', 'name': '시험 대학'},
    ],
    [
      {
        'sourceUniversityId': 'u',
        'universityId': 'u',
        'key': 'exam',
        'dbExamId': 'exam-db-1',
        'year': 2026,
        'kind': 'admission',
        'track': '자연',
        'verification': 'VERIFIED',
        'questions': [
          {
            'key': 'q1',
            'dbQuestionId': 'canonical-q1',
            'label': '문제 1',
            'inputMode': 'image',
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

  testWidgets('a non-serviceable exam shows the preparing notice before '
      'picking a question', (tester) async {
    await tester.pumpWidget(host(catalogFor(), const <String>{}));
    await openSelection(tester);
    expect(find.text('수리논술 첨삭 서비스 준비 중'), findsOneWidget);
    expect(find.textContaining('준비가 완료되면 제공됩니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a serviceable exam shows no preparing notice', (tester) async {
    await tester.pumpWidget(host(catalogFor(), const {'exam-db-1'}));
    await openSelection(tester);
    expect(find.text('수리논술 첨삭 서비스 준비 중'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
