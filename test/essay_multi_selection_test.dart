import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/supabase/supabase_providers.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/essay/source_catalog.dart';
import 'package:legendstudy_app/features/essay/source_catalog_page.dart';
import 'package:legendstudy_app/features/essay/source_draft.dart';

void main() {
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'checkbox bundle keeps selected questions and individual drafts at $scale',
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
        final questions = [
          for (var i = 1; i <= 3; i++)
            {
              'key': 'q$i',
              'dbQuestionId': 'canonical-q$i',
              'label': '문제 $i',
              'inputMode': 'text',
            },
        ];
        final catalog = SourceCatalog(
          [
            {'sourceUniversityId': 'u', 'name': '시험 대학'},
          ],
          [
            {
              'sourceUniversityId': 'u',
              'key': 'exam',
              'year': 2024,
              'kind': 'admission',
              'track': '인문',
              'questions': questions,
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
              home: SourceCatalogPage(catalog: Future.value(catalog)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('시험 대학'));
        await tester.pumpAndSettle();
        final cta = find.widgetWithText(FilledButton, '답안 작성하기');
        expect(tester.widget<FilledButton>(cta).onPressed, isNull);
        for (final label in ['문제 1', '문제 2']) {
          await tester.ensureVisible(find.text(label));
          await tester.tap(find.text(label));
          await tester.pumpAndSettle();
        }
        expect(find.text('선택한 문항 2개'), findsOneWidget);
        await tester.tap(find.text('문제 2'));
        await tester.pumpAndSettle();
        expect(find.text('선택한 문항 1개'), findsOneWidget);
        await tester.tap(find.text('문제 2'));
        await tester.pumpAndSettle();
        expect(
          tester.widget<FilledButton>(cta).style!.backgroundColor!.resolve({}),
          AppTokens.textPrimary,
        );
        await tester.ensureVisible(cta);
        await tester.tap(cta);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), '첫 문항 답안');
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        final picker = find.byType(DropdownButton<String>);
        await tester.scrollUntilVisible(
          picker,
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(picker);
        await tester.pumpAndSettle();
        await tester.tap(find.text('문제 2').last);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('답안 확인 · 첨삭 요청'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('답안 확인 · 첨삭 요청'));
        await tester.pumpAndSettle();
        final review = tester.widget<ExamAnswerReview>(
          find.byType(ExamAnswerReview),
        );
        expect(review.selectedQuestions, {'q1', 'q2'});
        expect(find.textContaining('문제 2: 답안이 비어'), findsOneWidget);
        await tester.ensureVisible(find.text('답안 수정'));
        await tester.tap(find.text('답안 수정'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byType(TextField));
        await tester.enterText(find.byType(TextField), '둘째 문항 답안');
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          picker,
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(picker);
        await tester.pumpAndSettle();
        await tester.tap(find.text('문제 1').last);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '첫 문항 답안',
        );
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('선택한 문항 2개'), findsOneWidget);
        await tester.ensureVisible(cta);
        await tester.tap(cta);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '첫 문항 답안',
        );
        await tester.scrollUntilVisible(
          picker,
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(picker);
        await tester.pumpAndSettle();
        await tester.tap(find.text('문제 2').last);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          '둘째 문항 답안',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
