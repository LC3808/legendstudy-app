import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/content/presentation/material_display_title.dart';
import 'package:legendstudy_app/features/resources/domain/content_resource.dart';
import 'package:legendstudy_app/features/resources/resource_providers.dart';
import 'package:legendstudy_app/features/resources/presentation/resource_section.dart';

void main() {
  test('conservative display-only exam SEO suffix', () {
    const prefix = '[2026년 7월 시행] 2026학년도 7월 고3 모의고사';
    const original = '$prefix 기출 - 문제, 답, 해설, 등급컷, 영어듣기 : 국어/영어/수학/사탐/과탐';
    expect(materialDisplayTitle(original, 'exam'), prefix);
    expect(
      materialDisplayTitle('2025 고2 모의고사 기출 - 문제/답/해설 자료', 'exam'),
      '2025 고2 모의고사',
    );
    for (final value in ['모의고사 준비 방법', '모의고사 기출 - 학습 계획', '모의고사 기출 - 문제집 추천']) {
      expect(materialDisplayTitle(value, 'exam'), value);
    }
    for (final type in [
      'essay',
      'study_material',
      'admissions_info',
      'education_column',
    ]) {
      expect(materialDisplayTitle(original, type), original);
    }
  });
  for (final width in [360.0, 428.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('group occurrences without resource loss $width/$scale', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, width == 360 ? 640 : 926);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final items = List.generate(
          3,
          (i) => ContentResource(
            id: 'r$i',
            contentItemId: 'p',
            examSubjectId: 'o$i',
            groupLabel: '국어',
            occurrenceLabel: i == 0 ? '언어와 매체' : '화법과 작문',
            resourceType: 'question',
            title: '자료 $i',
            sourceUrl: 'https://example.org',
            linkKind: 'unknown',
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contentResourcesProvider('p').overrideWith((ref) async => items),
            ],
            child: MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: const Scaffold(
                  body: SingleChildScrollView(
                    child: ResourceSection(
                      contentItemId: 'p',
                      contentSlug: 'p',
                      contentSourceUrl: 'https://legendstudy.com/1',
                      isArticle: false,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('국어'), findsOneWidget);
        expect(find.text('언어와 매체'), findsOneWidget);
        expect(find.text('화법과 작문'), findsNWidgets(2));
        for (var i = 0; i < 3; i++) {
          expect(find.text('자료 $i'), findsOneWidget);
        }
        expect(find.text('원문에서 보기'), findsNothing);
        await tester.tap(find.text('국어'));
        await tester.pumpAndSettle();
        expect(find.text('자료 0'), findsNothing);
        await tester.tap(find.text('국어'));
        await tester.pumpAndSettle();
        expect(find.text('자료 0'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
