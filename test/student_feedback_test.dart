import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/features/essay/student_feedback.dart';
import 'package:legendstudy_app/features/essay/evaluation_report.dart';

void main() {
  final cases = (jsonDecode(
    File('test/fixtures/student-feedback-cases.json').readAsStringSync(),
  ) as List).cast<Map<String, dynamic>>();
  EvaluationReport report(Map<String, dynamic> c) => EvaluationReport(
    id: 'after',
    answer: (c['answer'] as String),
    question: '합성 문항',
    summary: (c['summary'] as String),
    rubric: [
      EvaluationCriterion(
        'criterion',
        (c['official'] as String),
        '',
        c['level'] as int,
        (c['explanation'] as String),
      ),
    ],
    strengths: c['strength'] == ''
        ? []
        : [EvaluationFeedback('', (c['strength'] as String), '', '')],
    weaknesses: c['explanation'] == ''
        ? []
        : [
            EvaluationFeedback(
              (c['title'] as String),
              (c['explanation'] as String),
              '없는 인용',
              (c['action'] as String),
            ),
          ],
    actions: c['action'] == '' ? [] : [(c['action'] as String)],
    nextSteps: [(c['checklist'] as String)],
    pins: const ['question', 'rubric-v1', 'evidence-v1', '1.3'],
    priorId: 'before',
  );
  for (final c in cases) {
    testWidgets(
      'stored learning feedback ${c['case']} preserves source and never invents guide',
      (t) async {
        final original = jsonEncode(c), r = report(c);
        await t.pumpWidget(
          MaterialApp(
            home: Scaffold(body: StudentFeedbackView(report: r)),
          ),
        );
        expect(find.text('종합 평가'), findsOneWidget);
        expect(find.text('높은 평가를 위한 작성 가이드'), findsOneWidget);
        expect(find.text((c['official'] as String)), findsNothing);
        expect(find.text('없는 인용'), findsNothing);
        if (c['action'] != '') {
          expect(find.text((c['action'] as String)), findsOneWidget);
        }
        expect(find.textContaining('별도로 검증된 높은 평가의 핵심 조건'), findsOneWidget);
        expect(r.rubric.single.name, (c['official'] as String));
        expect(r.answer, (c['answer'] as String));
        expect(r.rubric.single.rating, c['level']);
        expect(jsonEncode(c), original);
        expect(t.takeException(), isNull);
      },
    );
  }
  for (final width in [320.0, 360.0, 390.0, 430.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('learning feedback width $width scale $scale', (t) async {
        t.view.physicalSize = Size(width, 900);
        t.view.devicePixelRatio = 1;
        addTearDown(t.view.resetPhysicalSize);
        addTearDown(t.view.resetDevicePixelRatio);
        final c = {
          ...cases[1],
          'explanation': List.filled(8, cases[1]['explanation']).join('\n\n'),
        };
        await t.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: StudentFeedbackView(
                report: report(c),
                voice: const Text('음성 영역'),
                actions: const SizedBox(key: ValueKey('pdf'), height: 48),
                rewrite: const Text('재작성 행동'),
              ),
            ),
          ),
        );
        expect(
          t.getTopLeft(find.text('음성 영역')).dy,
          lessThan(t.getTopLeft(find.text('높은 평가를 위한 작성 가이드')).dy),
        );
        expect(
          t.getTopLeft(find.text('음성 영역')).dy,
          greaterThan(t.getTopLeft(find.text('종합 평가')).dy),
        );
        expect(
          t.getTopLeft(find.text('다시 써보기')).dy -
              t.getBottomLeft(find.byKey(const ValueKey('pdf'))).dy,
          greaterThanOrEqualTo(24),
        );
        for (var i = 0; i < 8; i++) {
          await t.drag(
            find.byType(SingleChildScrollView),
            const Offset(0, -600),
          );
          await t.pump();
          expect(t.takeException(), isNull);
        }
      });
    }
  }
  test('exact evidence fallback retains distinct feedback but excludes raw unmatched source', () {
    final r = EvaluationReport(
      id: 'r',
      answer: 'answer',
      question: '',
      summary: '',
      rubric: const [],
      strengths: const [],
      weaknesses: const [],
      actions: const [],
      nextSteps: const [],
      pins: const [],
      evidenceLabels: const ['원문 — 설명', '원문 — 별도 근거', '공식 원문만'],
    );
    expect(
      studentCriterionFeedback(
        r,
        const EvaluationCriterion('c', '원문', '', 4, '설명'),
      ),
      ['설명', '별도 근거'],
    );
    expect(
      studentCriterionFeedback(
        r,
        const EvaluationCriterion('c', '원문', '', 4, ''),
      ),
      ['설명', '별도 근거'],
    );
    expect(r.evidenceLabels.last, '공식 원문만');
  });
  test(
    'core action mapping matches WEB and excludes resolved/non-core priorities',
    () {
      final report = humanEvaluationReport({
        'id': 'fixture',
        'contract_version': '1.3',
        'attempt': {'body': '원본'},
        'overall_summary': '종합',
        'strengths': ['실제 강점'],
        'rewrite_checklist': ['저장된 점검'],
        'essay_improvement_progress': [
          {
            'status': 'unresolved',
            'title': '핵심',
            'explanation': '설명',
            'next_action': '핵심 행동',
            'scaffolding_observation': {'core_focus': true},
          },
          {
            'status': 'unresolved',
            'title': '추가',
            'explanation': '추가 설명',
            'next_action': '추가 행동',
          },
          {
            'status': 'resolved',
            'next_action': '해결된 행동',
            'scaffolding_observation': {'core_focus': true},
          },
        ],
      });
      expect(report.actions, ['핵심 행동']);
      expect(report.weaknesses.map((f) => f.action), ['핵심 행동', '추가 행동']);
      expect(report.nextSteps, ['저장된 점검']);
      expect(report.summary, '종합');
    },
  );
  test('different rubric and paid parent do not produce false growth', () {
    final a = report(cases[0]);
    final b = EvaluationReport(
      id: 'before',
      answer: a.answer,
      question: a.question,
      summary: a.summary,
      rubric: a.rubric,
      strengths: a.strengths,
      weaknesses: a.weaknesses,
      actions: a.actions,
      nextSteps: a.nextSteps,
      pins: ['different-version'],
    );
    expect(compareEvaluationReports(b, a), isNull);
  });
}
