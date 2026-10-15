import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/approved_result_adapter.dart';
import 'package:legendstudy_app/features/essay/essay_models.dart';
import 'package:legendstudy_app/features/essay/essay_pages.dart';
import 'package:legendstudy_app/features/essay/evaluation_report.dart';
import 'package:legendstudy_app/features/essay/university_catalog.dart';
import 'package:legendstudy_app/features/essay/shared_history.dart';
import 'package:legendstudy_app/features/essay/shared_history_page.dart';

void main() {
  setUpAll(() async {
    if (const bool.fromEnvironment('CORE_RENDER')) {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      await (FontLoader('CorePreview')..addFont(
            File('/System/Library/Fonts/AppleSDGothicNeo.ttc')
                .readAsBytes()
                .then(ByteData.sublistView),
          ))
          .load();
    }
  });
  test('full existing catalog and independent history cycles preserved', () {
    expect(essayUniversityCatalog.length, 42);
    expect(essayUniversityCatalog.map((u) => u['sourceUniversityId']).take(3), [
      'gachon',
      'cau',
      'skku',
    ]);
    expect(
      essayUniversityCatalog
          .take(22)
          .any((u) => u['sourceUniversityId'] == 'pnu'),
      isTrue,
    );
    SharedEssayRecord row(String id, String? parent) => SharedEssayRecord(
      id: id,
      math: false,
      exam: true,
      at: DateTime(2026),
      rewrite: parent != null,
      evaluations: [],
      examData: {'parent_id': parent},
    );
    final groups = groupEssayHistory([
      row('a', null),
      row('b', 'a'),
      row('c', null),
    ]);
    expect(groups.map((g) => g.length).toList()..sort(), [1, 2]);
  });
  test('display titles preserve concepts without exposing long raw label', () {
    expect(shortCriterionTitle('( 나 ) 의 사회계약론에 대한 이해 미래 세대를 고려하여'), '사회계약론 이해');
    expect(
      shortCriterionTitle('( 다 ) 의 공리주의에 대한 이해와 평가 현재 미래 세대'),
      '공리주의 이해와 평가',
    );
  });
  final path = Platform.environment['ESSAY_QA_RESULT_PATH'];
  for (final comparison in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'saved operating result approved Native view comparison $comparison scale $scale',
        (tester) async {
          final rows = (jsonDecode(File(path!).readAsStringSync()) as List)
              .cast<Map<String, dynamic>>();
          final q = rows.last['answers'][0]['questionId'] as String;
          final before = examEvaluationReport(rows.first, q),
              after = examEvaluationReport(rows.last, q);
          final e = approvedEssayEvaluation(after, before);
          expect(
            e.dimensions.where((d) => d.level != d.previousLevel).length,
            1,
          );
          expect(
            e.dimensions
                .where((d) => d.label == '공리주의 이해와 평가')
                .single
                .previousLevel,
            3,
          );
          expect(
            e.dimensions.where((d) => d.label == '공리주의 이해와 평가').single.level,
            4,
          );
          expect(e.changes['해결한 부분'], isNotEmpty);
          tester.view.physicalSize = const Size(360, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(
                fontFamily: const bool.fromEnvironment('CORE_RENDER')
                    ? 'CorePreview'
                    : null,
              ),
              home: MediaQuery(
                data: MediaQueryData(
                  size: const Size(360, 844),
                  textScaler: TextScaler.linear(scale),
                ),
                child: Scaffold(
                  body: RepaintBoundary(
                    key: const ValueKey('capture'),
                    child: EssayResultView(
                      evaluation: comparison
                          ? e
                          : approvedEssayEvaluation(before, null),
                      question: EssayQuestion(
                        id: q,
                        university: '한양대학교',
                        exam: '2024학년도 수시 논술 · 인문계열 · 오후 2',
                        title: '문제 1',
                        prompt: '',
                        passages: const [],
                        origin: CriteriaOrigin.officialExam,
                      ),
                      comparison: comparison,
                      isPreview: false,
                      collapsedDetails: true,
                      onRewrite: () {},
                      submittedAnswer: comparison
                          ? after.answer
                          : before.answer,
                      header: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('한양대학교'),
                          Text('2024학년도 수시 논술'),
                          EssayExamBadges(data: {'track':'인문계열','session':'오후 2'}, questionLabel:'문제 1'),
                          Text('재첨삭 | 2026.10.14'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(comparison ? '이번 답안의 변화 한눈에 보기' : '내 답안 한눈에 보기'),
            findsOneWidget,
          );
          if (comparison) {
            expect(find.text('변화한 항목 1개'), findsOneWidget);
            expect(find.text('유지된 항목 4개 · 상세 비교'), findsOneWidget);
          }
          expect(find.text('확인할 수 있는 공식 근거 표시가 없어요.'), findsNothing);
          expect(tester.takeException(), isNull);
          if (scale == 1 && comparison) {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(const ValueKey('capture')),
            );
            await tester.runAsync(() async {
              final image = await boundary.toImage(pixelRatio: 2);
              final data = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File('/private/tmp/essay-approved-native-result.png')
                  .writeAsBytes(data!.buffer.asUint8List());
            });
          }
          await tester.scrollUntilVisible(
            find.text('다시 써보기'),
            700,
            scrollable: find.byType(Scrollable).first,
          );
          expect(tester.takeException(), isNull);
        },
        skip: path == null,
      );
    }
  }
}
