import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legendstudy_app/core/theme/app_theme.dart';
import 'package:legendstudy_app/features/study/scoring/practice_grade.dart';
import 'package:legendstudy_app/features/study/scoring/practice_grade_reference_data.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_result_view.dart';

ScoringAttempt sampleAttempt({bool mismatch = false}) {
  final data = jsonDecode(
    File('data/mock_expansion/task03b/load_data.json').readAsStringSync(),
  ) as Map;
  final key = (data['answer_key_versions'] as List).first as Map;
  final qs = (data['exam_questions'] as List)
      .where((q) => q['answer_key_version_id'] == key['id'])
      .toList();
  final choices = qs
      .map<int?>((q) => (q['accepted_answers'] as List).first as int)
      .toList();
  final a = MockScoringAvailability.fromJson({
    'exam_subject_id': mismatch ? 'other-subject' : key['exam_subject_id'],
    'paper_variant': key['paper_variant'],
    'answer_key_version_id': key['id'],
    'answer_key_version': 1,
    'question_count': key['question_count'],
    'max_score': key['max_score'],
    'grade_status': 'unavailable',
    'scoring_version': 'mixed-v2',
    'verification_status': 'READY',
    'availability': 'scoring_available',
  });
  return ScoringAttempt(
    id: 'synthetic-grade',
    outcome: ScoringOutcome.complete,
    title: '2022학년도 6월 모의평가',
    draft: AnswerDraft(
      a,
      qs
          .map(
            (q) => AnswerEntryQuestion(
              q['question_number'] as int,
              q['points'] as int,
              answerType: q['answer_type'] as String,
            ),
          )
          .toList(),
      choices,
    ),
    result: scoreMixed(
      qs.map((q) => Map<String, dynamic>.from(q as Map)).toList(),
      choices,
    ),
  );
}

void main() {
  final keys = practiceGradeReferenceData['keys'] as Map;
  final curves = practiceGradeReferenceData['curves'] as Map;
  test(
    '443 version-pinned keys: every point monotone and bounded; source present',
    () {
      expect(keys.length, 443);
      var expected = 0, estimated = 0;
      for (final k in keys.values) {
        final curve = curves[k['curve']] as Map;
        final max = k['max_score'] as int;
        if (curve['estimated'] as bool) {
          estimated++;
          expect(curve['basis'], isNotEmpty);
        } else {
          expected++;
        }
        expect(curve['urls'], isNotEmpty);
        expect(curve['revision'].length, 64);
        var prevBest = 9, prevWorst = 9;
        for (var raw = 0; raw <= max; raw++) {
          final g = PracticeGrade.fromCurve(raw, max, curve)!;
          expect(g.best, inInclusiveRange(1, g.worst));
          expect(g.worst, lessThanOrEqualTo(9));
          expect(g.best, lessThanOrEqualTo(prevBest));
          expect(g.worst, lessThanOrEqualTo(prevWorst));
          prevBest = g.best;
          prevWorst = g.worst;
        }
        expect(prevBest, 1);
        expect(prevWorst, 1);
      }
      expect(expected, 364);
      expect(estimated, 79);
    },
  );
  test('exact threshold, range, missing evidence, malformed order', () {
    final c = <String, dynamic>{
      'bands': [
        [90, 92],
        [80, 82],
        [70, 72],
        [60, 62],
        [50, 52],
        [40, 42],
        [30, 32],
        [20, 22],
      ],
      'estimated': false,
      'method': 'test',
      'revision': 'v1',
      'basis': <String>[],
      'urls': ['https://example.com'],
    };
    expect(PracticeGrade.fromCurve(90, 100, c)!.label, '예상 등급 · 1~2등급');
    expect(PracticeGrade.fromCurve(92, 100, c)!.label, '예상 등급 · 1등급');
    expect(PracticeGrade.fromCurve(19, 100, c)!.label, '예상 등급 · 9등급');
    expect(PracticeGrade.fromCurve(-1, 100, c), isNull);
    expect(PracticeGrade.fromCurve(101, 100, c), isNull);
    expect(
      PracticeGrade.fromCurve(50, 100, {
        ...c,
        'bands': [
          [90, 92],
        ],
      }),
      isNull,
    );
    expect(
      PracticeGrade.fromCurve(50, 100, {
        ...c,
        'bands': List.filled(8, [90, 80]),
      }),
      isNull,
    );
    expect(
      PracticeGrade.fromCurve(50, 100, {
        ...c,
        'bands': [
          [70, 72],
          ...List.filled(7, [80, 82]),
        ],
      }),
      isNull,
    );
  });
  test('result reference survives serialization without altering original score; mismatched ID blocked', () {
    final a = sampleAttempt();
    final before = jsonEncode(a.toJson());
    expect(PracticeGrade.forAttempt(a)!.estimated, isTrue);
    expect(a.result!.grade, isNull);
    expect(jsonEncode(a.toJson()), before);
    final restored = ScoringAttempt.fromJson(
      jsonDecode(before) as Map<String, dynamic>,
    );
    expect(
      PracticeGrade.forAttempt(restored)!.label,
      PracticeGrade.forAttempt(a)!.label,
    );
    expect(PracticeGrade.forAttempt(sampleAttempt(mismatch: true)), isNull);
  });
  for (final scale in [1.0, 2.0]) {
    testWidgets('estimated grade shown in score banner at $scale', (t) async {
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          builder: (c, child) => MediaQuery(
            data: MediaQuery.of(c)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ScoringResultView(attempt: sampleAttempt(), guest: true),
            ),
          ),
        ),
      );
      expect(find.text('추정 등급 · 1등급'), findsOneWidget);
      expect(find.text('유사 시험 원점수 기준'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  }
}
