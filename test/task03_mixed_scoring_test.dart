import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_pages.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_repository.dart';

import 'study_repository_test.dart' show config;
import 'study_core_test.dart' show TestClock, TestStore, TestRepo, flush;
import 'mock_scoring_test.dart' show FakeScoring;

import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';

Map<String, dynamic> availability({
  String status = 'READY',
  bool available = true,
}) => {
  'exam_subject_id': 's',
  'paper_variant': 'common',
  'answer_key_version_id': 'k',
  'answer_key_version': 1,
  'question_count': 4,
  'max_score': 10,
  'availability': available ? 'scoring_available' : 'timer_only',
  'grade_status': 'unavailable',
  'scoring_version': 'mixed-v2',
  'verification_status': status,
};
List<Map<String, dynamic>> questions() => [
  for (final row in [
    [
      1,
      'multiple_choice',
      [1, 3],
      false,
      2,
    ],
    [
      2,
      'numeric',
      [0],
      false,
      3,
    ],
    [
      3,
      'numeric',
      [999],
      false,
      3,
    ],
    [4, 'multiple_choice', <int>[], true, 2],
  ])
    {
      'question_number': row[0],
      'answer_type': row[1],
      'accepted_answers': row[2],
      'all_credit': row[3],
      'points': row[4],
      'question_id': 'q${row[0]}',
    },
];

class MixedRepository extends FakeScoring {
  MixedRepository(super.owner);
  @override
  Future<AnswerDraft> prepare(MockScoringAvailability a) async =>
      AnswerDraft(a, questions().map(AnswerEntryQuestion.fromJson).toList());
  @override
  Future<ScoreResult> submit(ScoringAttempt a) async =>
      scoreMixed(questions(), a.draft.answers);
}

void main() {
  for (final owner in [null, 'A']) {
    test(
      'mixed durable draft, pause, timeout and result recovery $owner',
      () async {
        final clock = TestClock(),
            store = TestStore(),
            repo = TestRepo('A'),
            scoring = MixedRepository(owner);
        StudyController create() => StudyController(
          clock,
          store,
          () => repo,
          ticking: false,
          scoringRepository: () => scoring,
        );
        var c = create();
        c.identity(owner, resolved: true);
        await flush(c);
        await c.configureScoring(
          MockScoringAvailability.fromJson(availability()),
        );
        c.configureMock(const MockSetup('Synthetic', null, 60));
        await c.startMock();
        await c.selectAnswer(2, 0);
        store.fail = true;
        await c.selectAnswer(3, 999);
        expect(c.draft!.answers!.answers, [null, 0, null, null]);
        store.fail = false;
        await c.pause();
        await c.selectAnswer(3, 999);
        expect(c.draft!.answers!.answers[2], isNull);
        c.dispose();
        c = create();
        c.identity(owner, resolved: true);
        await flush(c);
        expect(c.draft!.answers!.answers, [null, 0, null, null]);
        await c.resume();
        await c.selectAnswer(3, 999);
        clock.advance(61000);
        await c.tick();
        await c.selectAnswer(2, 1);
        expect(c.draft!.answers!.answers, [null, 0, 999, null]);
        await c.end();
        await flush(c);
        await c.sync();
        await flush(c);
        final result = c.attempts.single.result!;
        expect(result.rawScore, 8);
        expect(result.answers[1].submitted, 0);
        c.dispose();
        c = create();
        addTearDown(c.dispose);
        c.identity(owner, resolved: true);
        await flush(c);
        expect(c.attempts.single.result!.toJson(), result.toJson());
      },
    );
  }

  final shared = jsonDecode(
    File('supabase/candidates/task03_scoring_v2/synthetic_vectors.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  for (final item in shared['vectors'] as List) {
    final v = item as Map;
    test('SQL/Dart shared vector ${v['name']}', () {
      final result = scoreMixed(
        (shared['questions'] as List)
            .map((q) => Map<String, dynamic>.from(q as Map))
            .toList(),
        (v['answers'] as List).cast<int?>(),
        minimumScores: (v['minimum_scores'] as List?)?.cast<int>(),
        certainty: v['certainty'] as String,
      );
      for (final e in (v['expected'] as Map).entries) {
        expect(result.toJson()[e.key], e.value);
      }
    });
  }

  test('typed draft persists zero, max and blank without solutions', () {
    final d = AnswerDraft(
      MockScoringAvailability.fromJson(availability()),
      questions().map(AnswerEntryQuestion.fromJson).toList(),
    ).select(1, 3).select(2, 0).select(3, 999);
    final restored = AnswerDraft.fromJson(
      jsonDecode(jsonEncode(d.toJson())) as Map<String, dynamic>,
    );
    expect(restored.answers, [3, 0, 999, null]);
    expect(restored.answered, 3);
    expect(jsonEncode(d.toJson()), isNot(contains('accepted_answers')));
    for (final value in [-1, 1000]) {
      expect(() => d.select(2, value), throwsFormatException);
    }
    expect(() => d.select(1, 0), throwsFormatException);
    expect(d.select(2, null).answered, 2);
  });
  test('READY only; PARTIAL is preserved through cache', () {
    for (final status in ['PARTIAL', 'NOT_READY']) {
      expect(
        () => MockScoringAvailability.fromJson(availability(status: status)),
        throwsFormatException,
      );
      final a = MockScoringAvailability.fromJson(
        availability(status: status, available: false),
      );
      expect(
        MockScoringAvailability.fromJson(a.toJson()).verificationStatus,
        status,
      );
      expect(a.available, false);
    }
    expect(
      () => MockScoringAvailability.fromJson({
        ...availability(),
        'verification_status': 'unknown',
      }),
      throwsFormatException,
    );
  });
  test(
    'mixed engine, multiple accepted, all-credit and immutable snapshot',
    () {
      final result = scoreMixed(questions(), [3, 0, 1, null]);
      expect(result.rawScore, 7);
      expect(result.correctCount, 3);
      expect(result.wrong, [3]);
      expect(result.unanswered, [4]);
      expect(result.answers[1].correctLabel, '0');
      expect(result.answers[0].correctLabel, '① / ③');
      expect(result.answers[3].correctLabel, '전원 정답');
      expect(result.answers[1].questionId, 'q2');
      expect(result.answers[1].unit, isNull);
      expect(
        ScoreResult.fromJson(
          jsonDecode(jsonEncode(result.toJson())) as Map<String, dynamic>,
        ).toJson(),
        result.toJson(),
      );
      expect(
        () => result.answers[0].acceptedAnswers.add(5),
        throwsUnsupportedError,
      );
      expect(scoreMixed(questions(), [1, 0, 999, 5]).rawScore, 10);
      expect(scoreMixed(questions(), [null, null, null, null]).rawScore, 2);
      expect(
        scoreMixed(
          questions(),
          [3, 0, 1, null],
          minimumScores: [10, 9, 8, 7, 6, 5, 4, 2, 0],
          certainty: 'confirmed',
        ).grade,
        4,
      );
      final corrupt = result.toJson();
      (corrupt['answers'] as List)[1]['awarded_points'] = 0;
      expect(() => ScoreResult.fromJson(corrupt), throwsFormatException);
    },
  );
  test('invalid key, qid, type, sequence and accepted answer fail closed', () {
    for (final change in <Map<String, dynamic>>[
      {
        'accepted_answers': [1, 1],
      },
      {
        'accepted_answers': [0],
      },
      {'accepted_answers': <int>[]},
      {'answer_type': 'text'},
      {'points': 0},
      {'question_id': ''},
      {'question_number': 2},
      {'all_credit': true},
    ]) {
      final q = questions();
      q[0] = {...q[0], ...change};
      expect(() => scoreMixed(q, [1, 0, 999, null]), throwsFormatException);
    }
    final q = questions();
    q[1]['question_id'] = 'q1';
    expect(() => scoreMixed(q, [1, 0, 999, null]), throwsFormatException);
    expect(
      () => scoreMixed(questions(), [0, 0, 999, null]),
      throwsFormatException,
    );
  });
  testWidgets(
    'numeric input zero, leading zero, blank, invalid paste, restore and disabled',
    (t) async {
      int? value;
      bool enabled = true;
      StateSetter? rebuild;
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, set) {
                rebuild = set;
                return NumericAnswerField(
                  number: 22,
                  value: value,
                  enabled: enabled,
                  onChanged: (v) async {
                    set(() => value = v);
                  },
                );
              },
            ),
          ),
        ),
      );
      await t.enterText(find.byType(TextField), '000');
      await t.pump();
      expect(value, 0);
      await t.enterText(find.byType(TextField), '999');
      await t.pump();
      expect(value, 999);
      await t.enterText(find.byType(TextField), '12x34');
      await t.pump();
      expect(value, 999);
      await t.enterText(find.byType(TextField), '');
      await t.pump();
      expect(value, isNull);
      rebuild!(() {
        value = 17;
        enabled = false;
      });
      await t.pump();
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        '17',
      );
      expect(t.widget<TextField>(find.byType(TextField)).enabled, false);
    },
  );
  testWidgets('numeric persistence error restores saved value', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NumericAnswerField(
            number: 22,
            value: 2,
            enabled: true,
            onChanged: (v) async {
              throw StateError('disk failure');
            },
          ),
        ),
      ),
    );
    await t.enterText(find.byType(TextField), '123');
    await t.pump();
    expect(t.widget<TextField>(find.byType(TextField)).controller!.text, '2');
    expect(find.text('저장하지 못했어요. 다시 입력해 주세요.'), findsOneWidget);
  });
  testWidgets(
    'numeric rapid input keeps newest value while writes are pending',
    (t) async {
      final writes = <Completer<void>>[];
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumericAnswerField(
              number: 22,
              value: null,
              enabled: true,
              onChanged: (v) {
                final c = Completer<void>();
                writes.add(c);
                return c.future;
              },
            ),
          ),
        ),
      );
      await t.enterText(find.byType(TextField), '1');
      await t.enterText(find.byType(TextField), '12');
      writes.first.completeError(StateError('old failed'));
      await t.pump();
      expect(
        t.widget<TextField>(find.byType(TextField)).controller!.text,
        '12',
      );
      writes.last.complete();
      await t.pump();
      expect(t.takeException(), isNull);
    },
  );
  for (final mode in [
    'success',
    'page_error',
    'missing_metadata',
    'duplicate',
  ]) {
    test('catalogue 201 papers pagination $mode', () async {
      final offsets = <int>[];
      final batches = <int>[];
      final repo = SupabaseScoringRepository(
        config,
        MockClient((r) async {
          if (r.url.path.endsWith('mock_exam_scoring_availability')) {
            final offset = int.parse(r.url.queryParameters['offset']!);
            offsets.add(offset);
            if (mode == 'page_error' && offset == 100) {
              return http.Response('{}', 500);
            }
            return http.Response(
              jsonEncode([
                for (var i = offset; i < offset + 100 && i < 201; i++)
                  {
                    ...availability(),
                    'exam_subject_id': mode == 'duplicate' && i == 100
                        ? 's0'
                        : 's$i',
                  },
              ]),
              200,
            );
          }
          final ids = r.url.queryParameters['id']!
              .substring(4)
              .replaceAll(')', '')
              .split(',');
          batches.add(ids.length);
          return http.Response(
            jsonEncode([
              for (final id in ids)
                if (mode != 'missing_metadata' || id != 's0')
                  {
                    'id': id,
                    'content_item_id': 'exam',
                    'raw_subject_label': 'Math',
                    'exams': {
                      'year': 2021,
                      'exam_type': 'evaluation_mock',
                      'content_items': {'title': 'Synthetic'},
                    },
                  },
            ]),
            200,
          );
        }),
      );
      if (mode != 'success') {
        await expectLater(
          repo.availablePapers(),
          throwsA(isA<ScoringFailure>()),
        );
        return;
      }
      expect((await repo.availablePapers()).length, 201);
      expect(offsets, [0, 100, 200]);
      expect(batches, [40, 40, 40, 40, 40, 1]);
    });
  }
}
