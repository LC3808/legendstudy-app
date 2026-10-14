import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'native selection, image-first and draft restore at 360dp scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final disk = <String, String>{};
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async {
              if (call.method == 'read') return disk[call.arguments];
              if (call.method == 'write') {
                final a = call.arguments as Map;
                disk[a['key'] as String] = a['value'] as String;
              }
              return null;
            });
        final data = SourceCatalog(
          [
            {'sourceUniversityId': 'fixture', 'name': '시험 대학'},
          ],
          [
            {
              'sourceUniversityId': 'fixture',
              'key': 'exam',
              'year': 2025,
              'kind': 'admission',
              'track': '자연계열',
              'questions': [
                {'key': 'same-question', 'label': '문제 1', 'inputMode': 'image'},
              ],
            },
          ],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authStateProvider.overrideWith(
                (ref) => Stream.value(const AuthStatus('owner')),
              ),
            ],
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: SourceCatalogPage(catalog: Future.value(data)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('나의 첨삭 기록'), findsOneWidget);
        await tester.tap(find.text('첨삭 시작하기'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('문제 1'));
        await tester.tap(find.text('문제 1'));
        await tester.pumpAndSettle();
        expect(find.text('답안 사진 촬영'), findsOneWidget);
        expect(find.text('이미지 첨부'), findsOneWidget);
        expect(find.text('시험 대학'), findsOneWidget);
        await tester.tap(find.text('문제 보기'));
        await tester.pumpAndSettle();
        expect(find.text('답안 확인 · 첨삭 요청'), findsNothing);
        await tester.tap(find.text('답안 작성'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('답안 확인 · 첨삭 요청'),
          250,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('답안 확인 · 첨삭 요청'), findsOneWidget);
        await tester.ensureVisible(find.byType(TextField));

        await tester.enterText(find.byType(TextField), '풀이 보충 설명');
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(disk.values.single, contains('풀이 보충 설명'));
        expect(tester.takeException(), isNull);
        await tester.pageBack();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('문제 1'));
        await tester.tap(find.text('문제 1'));
        await tester.pumpAndSettle();
        expect(find.text('풀이 보충 설명'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('rewrite restores original, locks selection and respects HOLD', (
    tester,
  ) async {
    final disk = <String, String>{};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async {
          if (call.method == 'read') return disk[call.arguments];
          if (call.method == 'write') {
            final a = call.arguments as Map;
            disk[a['key'] as String] = a['value'] as String;
          }
          return null;
        });
    final data = SourceCatalog(
      [
        {'sourceUniversityId': 'fixture', 'name': '시험 대학'},
      ],
      [
        {
          'sourceUniversityId': 'fixture',
          'key': 'exam',
          'dbExamId': 'exam-id',
          'year': 2024,
          'kind': 'admission',
          'track': '인문계열',
          'questions': [
            {
              'key': 'rewrite-q',
              'dbQuestionId': 'q-id',
              'label': '문제 1',
              'inputMode': 'text',
            },
          ],
        },
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(const AuthStatus('owner')),
          ),
        ],
        child: MaterialApp(
          home: SourceCatalogPage(
            catalog: Future.value(data),
            rewriteRun: {
              'id': 'parent',
              'exam_id': 'exam-id',
              'question_ids': ['q-id'],
              'answers': [
                {'questionId': 'q-id', 'body': '기존 제출 답안'},
              ],
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
    await tester.ensureVisible(find.text('문제 1'));
    await tester.tap(find.text('문제 1'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '기존 제출 답안',
    );
    await tester.enterText(find.byType(TextField), '수정 중인 답안');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('문제 1'));
    await tester.tap(find.text('문제 1'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '수정 중인 답안',
    );
    expect(tester.takeException(), isNull);
  });
}
