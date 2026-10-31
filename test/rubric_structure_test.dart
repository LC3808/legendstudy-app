import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/official_rubric.dart';
import 'package:legendstudy_app/features/essay/approved_result_adapter.dart';
import 'package:legendstudy_app/features/essay/evaluation_report.dart';
import 'package:legendstudy_app/features/essay/essay_pages.dart';
import 'package:legendstudy_app/features/essay/essay_models.dart';

void main() {
  final fixture = jsonDecode(
    File('test/fixtures/exam-history-v1.json').readAsStringSync(),
  );
  test('Soongsil source fixture preserves five exact score rows and bonus', () {
    final source = jsonDecode(
      File('test/fixtures/soongsil-rubric-source.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final rows = (source['rows'] as List).cast<Map<String, dynamic>>();
    expect(rows.map((r) => r['score']), ['8~10', '6~7', '4~5', '1~3', '0']);
    expect(source['original_text'], contains('논\n8~10\n리적으로'));
    expect(rows.first['description'], contains('논리적으로'));
    expect(source['bonus'], contains('1점 가점'));
    expect(source['status'], 'CANDIDATE_OWNER_REVIEW');
  });
  for (final raw in [
    '이유를 제시하\n준거 1 는 것이다.',
    '[논제 I] 801자 이상~900자 이하: 배점 40점',
    '채점 기준 배점\nS 1, 2, 3을 모두 제시\n상\nA 일부 부족',
  ]) {
    test('SWU KHU Dongguk historical text stays unchanged: $raw', () {
      final run =
          jsonDecode(jsonEncode(fixture['after'])) as Map<String, dynamic>;
      final result = run['result'] as Map<String, dynamic>;
      final question =
          (result['questions'] as List).first as Map<String, dynamic>;
      ((question['criteria'] as List).first as Map<String, dynamic>)['label'] =
          raw;
      final r = examEvaluationReport(run, 'question');
      final e = approvedEssayEvaluation(r, null);
      expect(e.dimensions.first.officialCriterion, raw);
      expect(e.dimensions.first.explanation, r.rubric.first.feedback);
    });
  }
  test('raw criteria are independent from explanation and rating', () {
    final report = examEvaluationReport(
      Map<String, dynamic>.from(fixture['after'] as Map),
      'question',
    );
    final adapted = approvedEssayEvaluation(report, null);
    for (var i = 0; i < report.rubric.length; i++) {
      expect(adapted.dimensions[i].explanation, report.rubric[i].feedback);
      expect(adapted.dimensions[i].officialCriterion, report.rubric[i].name);
      expect(adapted.dimensions[i].key, report.rubric[i].id);
      expect(adapted.dimensions[i].level, report.rubric[i].rating);
    }
  });
  test('neutral table title only for an unlabeled single criterion', () {
    const raw = '6. 채점 기준\n채점 기준 배점\n이해를 논\n8~10\n리적으로';
    expect(resultCriterionTitle(raw, criterionCount: 1), '문항별 채점기준');
    expect(resultCriterionTitle(raw, criterionCount: 2), isNot('문항별 채점기준'));
  });
  testWidgets(
    'feedback appears once, raw is collapsed, distinct evidence survives',
    (t) async {
      final run =
          jsonDecode(jsonEncode(fixture['after'])) as Map<String, dynamic>;
      final source = jsonDecode(
        File('test/fixtures/soongsil-rubric-source.json').readAsStringSync(),
      );
      run['result']['questions'][0]['criteria'][0]['label'] =
          source['original_text'];
      final report = examEvaluationReport(run, 'question');
      final e = approvedEssayEvaluation(report, null);
      final d = e.dimensions.first;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EssayResultView(
              evaluation: e,
              question: const EssayQuestion(
                id: 'question',
                university: '검증 대학',
                exam: '검증 시험',
                title: '문제 1',
                prompt: '',
                passages: [],
                origin: CriteriaOrigin.officialExam,
              ),
              comparison: false,
              onRewrite: null,
              isPreview: false,
              collapsedDetails: true,
              evidenceLabels: [
                '${d.officialCriterion} — ${d.explanation}',
                '별도의 실제 근거',
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        find.text('공식 채점기준 자세히 보기').first,
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text(d.explanation), findsOneWidget);
      expect(find.text(d.officialCriterion!), findsNothing);
      await t.tap(find.text('공식 채점기준 자세히 보기').first);
      await t.pumpAndSettle();
      expect(find.text(d.officialCriterion!), findsOneWidget);
      expect(
        find.text('${d.officialCriterion} — ${d.explanation}'),
        findsNothing,
      );
      await t.scrollUntilVisible(
        find.text('평가 근거'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await t.tap(find.text('평가 근거'));
      await t.pumpAndSettle();
      expect(find.text('별도의 실제 근거'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  Map<String, dynamic> payload() => {
    'schema': 'official-rubric-read-v1',
    'status': 'VERIFIED',
    'criterion_id': 'c',
    'original_text': '원문',
    'source': {
      'package_digest': 'digest',
      'package_version': 2,
      'page': 6,
      'pdf_hash': 'a' * 64,
    },
    'rows': [
      {'score': '8~10', 'grade': '', 'description': '검수된 설명'},
    ],
    'bonus': '1점 가점 조건',
  };
  OfficialRubric? read(Map<String, dynamic> value) => OfficialRubric.read(
    value,
    criterionId: 'c',
    packageDigest: 'digest',
    originalText: '원문',
  );
  test(
    'unapproved candidates and mismatched historical bindings are rejected',
    () {
      expect(read(payload()), isNotNull);
      for (final entry in {
        'status': 'CANDIDATE_OWNER_REVIEW',
        'criterion_id': 'other',
        'original_text': '다른 원문',
      }.entries) {
        expect(read(payload()..[entry.key] = entry.value), isNull);
      }
      expect(read(payload()..['source'] = {'package_digest': 'new'}), isNull);
      expect(
        read(
          payload()
            ..['rows'] = [
              {'score': '8~10'},
            ],
        ),
        isNull,
      );
    },
  );
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    testWidgets('structured rows retain score and description at $width', (
      t,
    ) async {
      t.view.physicalSize = Size(width, 844);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: OfficialRubricView(rubric: read(payload())!),
            ),
          ),
        ),
      );
      expect(find.text('배점 8~10'), findsOneWidget);
      expect(find.text('검수된 설명'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
