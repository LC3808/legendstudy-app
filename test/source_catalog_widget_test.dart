import 'dart:io';

import 'package:legendstudy_app/features/essay/student_pdf_catalog.dart';

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:legendstudy_app/features/essay/university_catalog.dart';
import 'package:legendstudy_app/features/credits/credit_balance.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets('approved PDF browse remains available on HOLD at 360/$scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final disk = <String, String>{};
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SourceDraftGateway.channel, (call) async {
            if (call.method == 'read') return disk[call.arguments];
            if (call.method == 'write') {
              final args = call.arguments as Map;
              disk[args['key'] as String] = args['value'] as String;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SourceDraftGateway.channel, null),
      );
      final q = approvedStudentPdfs.values.first;
      final data = SourceCatalog(
        [
          {'sourceUniversityId': 'konkuk', 'name': '건국대학교'},
        ],
        [
          {
            'sourceUniversityId': 'konkuk',
            'key': 'exam',
            'year': 2027,
            'kind': 'mock',
            'track': '자연',
            'verification': 'REVIEW_REQUIRED',
            'questions': [
              {
                'key': 'q',
                'label': '문제 1',
                'dbQuestionId': q['questionId'],
                'studentPdf': studentPdfFor(
                  q['examId'] as String,
                  q['questionId'] as String,
                ),
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
      await tester.tap(find.text('건국대학교'));
      await tester.pumpAndSettle();
      expect(find.text('2027학년도 모의논술'), findsOneWidget);
      expect(
        tester
            .widget<OutlinedButton>(
              find.widgetWithText(OutlinedButton, '문제 보기'),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '답안 작성하기'))
            .onPressed,
        isNotNull,
      );
      await tester.ensureVisible(find.text('답안 작성하기'));
      await tester.tap(find.text('답안 작성하기'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '검수 중 문항의 기기 내 초안');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(disk.values.single, contains('검수 중 문항의 기기 내 초안'));
      expect(find.text('계정 답안 확인·저장'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('답안 확인'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.widgetWithText(FilledButton, '답안 확인'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('답안 확인'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, '첨삭 서비스 준비 중'),
            )
            .onPressed,
        isNull,
      );
      expect(find.text('첨삭 요청 · 1 크레딧'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'held university keeps materials selectable but disables feedback entry',
    (tester) async {
      final data = SourceCatalog(
        [
          {
            'sourceUniversityId': 'yonsei',
            'name': '연세대학교',
            'officialSourceUrl': 'https://example.org/',
          },
        ],
        [
          {
            'sourceUniversityId': 'yonsei',
            'key': 'held',
            'year': 2026,
            'kind': 'admission',
            'track': '인문',
            'questions': [
              {'key': 'q', 'label': '문제 1', 'inputMode': 'text'},
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
            home: SourceCatalogPage(catalog: Future.value(data)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '서비스 준비중'))
            .onPressed,
        isNull,
      );
      await tester.tap(
        find.widgetWithText(FilledButton, '서비스 준비중'),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('문제 1'), findsNothing);
      await tester.tap(find.text('연세대학교'));
      await tester.pumpAndSettle();
      expect(find.text('문제 1'), findsOneWidget);
      expect(find.text('공식 입학처 자료 확인 ↗'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '서비스 준비중'))
            .onPressed,
        isNull,
      );
      expect(find.byType(TextField), findsNothing);
    },
  );

  testWidgets(
    'registered review-only metadata allows selection but blocks answer writing',
    (tester) async {
      final data = SourceCatalog(
        [
          {
            'sourceUniversityId': 'konkuk',
            'name': '건국대학교',
            'officialSourceUrl': 'https://example.org/',
          },
        ],
        [
          {
            'sourceUniversityId': 'konkuk',
            'key': 'registered',
            'verification': 'REVIEW_REQUIRED',
            'year': 2026,
            'kind': 'admission',
            'track': '인문',
            'questions': [
              {'key': 'q', 'label': '문제 1', 'inputMode': 'text'},
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
            home: SourceCatalogPage(catalog: Future.value(data)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('건국대학교'));
      await tester.pumpAndSettle();
      expect(find.text('문제 1'), findsOneWidget);
      expect(find.text('공식 입학처 자료 확인 ↗'), findsOneWidget);
      // Registered but review-blocked (single question auto-selected, no draft):
      // feedback is unavailable, so the CTA reads 첨삭 서비스 준비 중.
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, '첨삭 서비스 준비 중'),
            )
            .onPressed,
        isNull,
      );
      expect(find.byType(TextField), findsNothing);
    },
  );

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
        expect(find.text('나의 첨삭 기록 ›'), findsOneWidget);
        expect(find.text('나의 논술 LAB'), findsNothing);
        expect(find.text('첨삭 시작하기'), findsNothing);
        await tester.tap(find.text('시험 대학'));
        await tester.pumpAndSettle();
        // This synthetic image exam has no Math leaf/availability in tests, so
        // the 준비 중 안내가 선택 화면에 노출되어 목록이 길어진다. 지연 빌드되는
        // 체크박스를 스크롤로 띄운 뒤 확인한다.
        await tester.scrollUntilVisible(
          find.text('문제 1'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        // Single question is selected by default and retained on return.
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        await tester.ensureVisible(find.text('답안 작성하기'));
        await tester.tap(find.text('답안 작성하기'));
        await tester.pumpAndSettle();
        expect(find.text('답안 사진 촬영'), findsOneWidget);
        expect(find.text('이미지 첨부'), findsOneWidget);
        expect(find.text('시험 대학'), findsOneWidget);
        expect(find.byType(SegmentedButton<bool>), findsNothing);
        expect(find.text('대학 공식 기출자료에서 문제와 제시문을 확인하세요.'), findsNothing);
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
        await tester.scrollUntilVisible(
          find.text('문제 1'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        // Single question is selected by default and retained on return.
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        await tester.ensureVisible(find.text('답안 작성하기'));
        await tester.tap(find.text('답안 작성하기'));
        await tester.pumpAndSettle();
        expect(find.text('풀이 보충 설명'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final scale in [1.0, 2.0]) {
    testWidgets('Owner logos preserve card navigation at 360/$scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      final universities = ['skku', 'uos', 'hanyang']
          .map(
            (id) => essayUniversityCatalog.singleWhere(
              (u) => u['sourceUniversityId'] == id,
            ),
          )
          .toList();
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
            home: RepaintBoundary(
              key: boundary,
              child: SourceCatalogPage(
                catalog: Future.value(SourceCatalog(universities, [])),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        for (final u in universities) {
          await precacheImage(
            AssetImage(u['logoAsset'] as String),
            boundary.currentContext!,
          );
        }
      });
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsNWidgets(3));
      for (final id in ['skku', 'uos']) {
        final logo = find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName ==
                  'assets/university-logos/$id.png',
        );
        expect(logo, findsOneWidget);
        expect(tester.getSize(logo), const Size(100, 52));
      }
      expect(tester.takeException(), isNull);
      if (Platform.environment['ESSAY_LOGO_CAPTURE'] == '1') {
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('/private/tmp/essay-owner-logos-$scale.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.text('서울시립대학교'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('대학 목록'), findsOneWidget);
      await tester.tap(find.byTooltip('대학 목록'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('성균관대학교'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('대학 목록'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'rewrite starts blank, restores scoped draft, locks selection and respects HOLD',
    (tester) async {
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
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
      await tester.ensureVisible(find.text('문제 1'));
      // Rewrite's original question set is fixed.
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.ensureVisible(find.text('답안 작성하기'));
      await tester.tap(find.text('답안 작성하기'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      await tester.enterText(find.byType(TextField), '수정 중인 답안');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('문제 1'));
      // Rewrite's original question set is fixed.
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      await tester.ensureVisible(find.text('답안 작성하기'));
      await tester.tap(find.text('답안 작성하기'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '수정 중인 답안',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Hero balance appears once and university back restores list position',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final universities = List.generate(
        42,
        (i) => <String, dynamic>{'sourceUniversityId': 'u$i', 'name': '대학 $i'},
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(
              (ref) => Stream.value(const AuthStatus('owner')),
            ),
            creditBalanceProvider.overrideWith(
              (ref) async => CreditBalance.fromJson({
                'dto_version': 'credit-v1',
                'spendable': 10,
                'paid': 0,
                'free': 0,
                'other': 10,
              }),
            ),
          ],
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: SourceCatalogPage(
                catalog: Future.value(SourceCatalog(universities, [])),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('현재 크레딧 10개'), findsOneWidget);
      expect(find.text('나의 첨삭 기록 ›'), findsOneWidget);
      expect(find.text('나의 논술 LAB'), findsNothing);
      expect(find.text('첨삭 시작하기'), findsNothing);
      await tester.scrollUntilVisible(find.text('대학 20'), 300);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 180));
      await tester.pumpAndSettle();
      final y = tester.getTopLeft(find.text('대학 20')).dy;
      await tester.tap(find.text('대학 20'));
      await tester.pumpAndSettle();
      expect(find.text('현재 크레딧 10개'), findsNothing);
      await tester.tap(find.byTooltip('대학 목록'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('대학 20')).dy, closeTo(y, 1));
      expect(tester.takeException(), isNull);
    },
  );
}
