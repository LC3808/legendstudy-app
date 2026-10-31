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
    testWidgets('learning feedback width $width large text', (t) async {
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
                .copyWith(textScaler: TextScaler.linear(1.8)),
            child: child!,
          ),
          home: Scaffold(body: StudentFeedbackView(report: report(c))),
        ),
      );
      for (var i = 0; i < 8; i++) {
        await t.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
        await t.pump();
        expect(t.takeException(), isNull);
      }
    });
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
