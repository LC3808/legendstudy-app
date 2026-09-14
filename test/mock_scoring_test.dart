import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_models.dart';
import 'package:legendstudy_app/features/study/scoring/scoring_repository.dart';
import 'package:legendstudy_app/features/study/application/study_controller.dart';
import 'package:legendstudy_app/features/study/domain/study_models.dart';
import 'study_core_test.dart' show TestClock, TestStore, TestRepo, flush;
import 'study_repository_test.dart' show config;

MockScoringAvailability availability([int n = 3]) =>
    MockScoringAvailability.fromJson({
      'exam_subject_id': 'occurrence',
      'paper_variant': 'common',
      'answer_key_version_id': 'key',
      'answer_key_version': 1,
      'question_count': n,
      'max_score': n * 2,
      'availability': 'scoring_available',
      'grade_cutoff_version_id': null,
      'grade_status': 'unavailable',
      'scoring_version': 'mcq5-v1',
    });
AnswerDraft answerDraft([int n = 3]) => AnswerDraft(
  availability(n),
  List.generate(n, (i) => AnswerEntryQuestion(i + 1, 2)),
);

class FakeScoring implements ScoringRepository {
  FakeScoring(this.owner);
  @override
  final String? owner;
  bool fail = false, stale = false;
  Completer<void>? hold;
  final calls = <Map<String, dynamic>>[];
  @override
  Future<List<ScoringPaper>> availablePapers() async => [
    ScoringPaper(availability(), '테스트 시험'),
  ];
  @override
  Future<AnswerDraft> prepare(MockScoringAvailability a) async =>
      answerDraft(a.questionCount!);
  @override
  Future<ScoreResult> submit(ScoringAttempt a) async {
    calls.add(a.payload());
    if (hold != null) await hold!.future;
    if (stale) throw const ScoringStale();
    if (fail) throw const ScoringFailure();
    return scoreMcq5(
      List.generate(a.draft.answers.length, (i) => [i + 1, 1, 2]),
      a.draft.answers,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final vectors =
      jsonDecode(
            File(
              'supabase/review/mock_scoring_vectors.json',
            ).readAsStringSync(),
          )
          as Map;
  for (final raw in vectors['vectors'] as List) {
    final v = raw as Map;
    test('Dart/server vector ${v['name']}', () {
      final r = scoreMcq5(
        (v['questions'] as List).map((q) => (q as List).cast<int>()).toList(),
        (v['answers'] as List).cast<int?>(),
        minimumScores: (v['minimum_scores'] as List?)?.cast<int>(),
        certainty: v['certainty'] as String,
      );
      for (final e in (v['expected'] as Map).entries) {
        expect(r.toJson()[e.key], e.value);
      }
    });
  }
  test('answer selection/change/unanswered/count/restore guards', () {
    final d = answerDraft(100).select(100, 5).select(1, 2).select(1, 3);
    expect(d.answered, 2);
    expect(d.unanswered, 98);
    expect(
      AnswerDraft.fromJson(
        jsonDecode(jsonEncode(d.toJson())) as Map<String, dynamic>,
      ).answers,
      d.answers,
    );
    expect(d.select(1, null).answered, 1);
    expect(() => d.select(101, 1), throwsFormatException);
    expect(() => d.select(1, 6), throwsFormatException);
    expect(() => answerDraft(101), throwsFormatException);
    expect(jsonEncode(d.toJson()).contains('correct_answer'), false);
  });
  for (final owner in [null, 'A']) {
    test('guest/auth durable draft, locks, submit, restore $owner', () async {
      final clock = TestClock(),
          store = TestStore(),
          repo = TestRepo('A'),
          scoring = FakeScoring(owner);
      var c = StudyController(
        clock,
        store,
        () => repo,
        ticking: false,
        scoringRepository: () => scoring,
      );
      c.identity(owner, resolved: true);
      await flush(c);
      await c.configureScoring(availability());
      c.configureMock(const MockSetup('시험', null, 60));
      await c.startMock();
      await c.selectAnswer(1, 1);
      clock.advance(1000);
      await c.pause();
      await c.selectAnswer(2, 2);
      expect(c.draft!.answers!.answers, [1, null, null]);
      c.dispose();
      c = StudyController(
        clock,
        store,
        () => repo,
        ticking: false,
        scoringRepository: () => scoring,
      );

      c.identity(owner, resolved: true);
      await flush(c);
      expect(c.draft!.answers!.answered, 1);
      await c.resume();
      await c.selectAnswer(2, 5);
      clock.advance(61000);
      await c.tick();
      await c.selectAnswer(3, 1);
      expect(c.draft!.frozen, true);
      expect(c.draft!.answers!.answers, [1, 5, null]);
      expect(scoring.calls, isEmpty);
      await c.end();
      await flush(c);
      await c.sync();
      await flush(c);
      expect(c.attempts.single.result!.rawScore, 2);
      expect(c.attempts.single.result!.wrong, [2]);
      expect(c.attempts.single.result!.unanswered, [3]);
      expect(c.week.last, 60000);
      expect(owner == null ? repo.inserts == 0 : repo.inserts > 0, true);
      final frozenPayload = jsonEncode(c.attempts.single.payload());
      await c.selectAnswer(1, 5);
      expect(jsonEncode(c.attempts.single.payload()), frozenPayload);
      final saved = c.attempts.single.id;
      c.dispose();
      c = StudyController(
        clock,
        store,
        () => repo,
        ticking: false,
        scoringRepository: () => scoring,
      );
      addTearDown(c.dispose);
      c.identity(owner, resolved: true);
      await flush(c);
      expect(c.attempts.single.id, saved);
      expect(c.attempts.single.result!.rawScore, 2);
    });
  }
  test('timeout retry retains exact ID/payload and no false result', () async {
    final clock = TestClock(),
        store = TestStore(),
        repo = TestRepo('A'),
        scoring = FakeScoring('A')..fail = true;
    final c = StudyController(
      clock,
      store,
      () => repo,
      ticking: false,
      scoringRepository: () => scoring,
    );
    addTearDown(c.dispose);
    c.identity('A', resolved: true);
    await flush(c);
    await c.configureScoring(availability());
    c.configureMock(const MockSetup('시험', null, 60));
    await c.startMock();
    await c.selectAnswer(1, 1);
    clock.advance(1000);
    await c.end();
    await flush(c);
    await c.sync();
    expect(c.attempts.single.result, isNull);
    final first = jsonEncode(scoring.calls.first);
    scoring.fail = false;
    await c.sync();
    await flush(c);
    expect(scoring.calls.every((p) => jsonEncode(p) == first), true);
    expect(c.attempts.single.result, isNotNull);
  });
  test('stale version preserved with no automatic current rewrite', () async {
    final clock = TestClock(), scoring = FakeScoring(null)..stale = true;
    final c = StudyController(
      clock,
      TestStore(),
      () => TestRepo('A'),
      ticking: false,
      scoringRepository: () => scoring,
    );
    addTearDown(c.dispose);
    c.identity(null, resolved: true);
    await flush(c);
    await c.configureScoring(availability());
    c.configureMock(const MockSetup('시험', null, 60));
    await c.startMock();
    clock.advance(1000);
    await c.end();
    await flush(c);
    await c.sync();
    expect(c.attempts.single.outcome, ScoringOutcome.stale);
    expect(c.attempts.single.result, isNull);
    final calls = scoring.calls.length;
    await c.sync();
    expect(scoring.calls.length, calls);
  });
  test(
    'late A response never enters B; guest answers never upload on login',
    () async {
      final clock = TestClock(), store = TestStore();
      var repo = TestRepo('A');
      var scoring = FakeScoring('A')..hold = Completer<void>();
      final c = StudyController(
        clock,
        store,
        () => repo,
        ticking: false,
        scoringRepository: () => scoring,
      );
      addTearDown(c.dispose);
      c.identity('A', resolved: true);
      await flush(c);
      await c.configureScoring(availability());
      c.configureMock(const MockSetup('A시험', null, 60));
      await c.startMock();
      clock.advance(1000);
      await c.end();
      await flush(c);
      final a = scoring;
      repo = TestRepo('B');
      scoring = FakeScoring('B');
      c.identity('B', resolved: true);
      await flush(c);
      a.hold!.complete();
      await flush(c);
      expect(c.attempts, isEmpty);
      expect(scoring.calls, isEmpty);
      c.identity(null, resolved: true);
      scoring = FakeScoring(null);
      await flush(c);
      await c.configureScoring(availability());
      c.configureMock(const MockSetup('Guest', null, 60));
      await c.startMock();
      await c.selectAnswer(1, 2);
      scoring = FakeScoring('B');
      c.identity('B', resolved: true);
      await flush(c);
      expect(c.draft, isNull);
      expect(scoring.calls, isEmpty);
    },
  );
  test('local answer write failure does not commit choice', () async {
    final store = TestStore(),
        c = StudyController(TestClock(), TestStore(), () => TestRepo('A'));
    c.dispose();
    final s = StudyController(
      TestClock(),
      store,
      () => TestRepo('A'),
      ticking: false,
      scoringRepository: () => FakeScoring(null),
    );
    addTearDown(s.dispose);
    s.identity(null, resolved: true);
    await flush(s);
    await s.configureScoring(availability());
    s.configureMock(const MockSetup('시험', null, 60));
    await s.startMock();
    store.fail = true;
    await s.selectAnswer(1, 1);
    expect(s.draft!.answers!.answered, 0);
  });
  test(
    'repository entry projection excludes solutions; empty stays timer only',
    () async {
      final paths = <http.Request>[];
      final repo = SupabaseScoringRepository(
        config,
        MockClient((r) async {
          paths.add(r);
          if (r.url.path.endsWith('mock_exam_scoring_availability')) {
            return http.Response(jsonEncode([availability().toJson()]), 200);
          }
          return http.Response(
            jsonEncode(answerDraft().questions.map((q) => q.toJson()).toList()),
            200,
          );
        }),
      );
      final d = await repo.prepare(availability());
      expect(d.answers, [null, null, null]);
      expect(
        paths.last.url.queryParameters['select'],
        'question_number,answer_type,points',
      );
      final empty = SupabaseScoringRepository(
        config,
        MockClient((_) async => http.Response('[]', 200)),
      );
      expect(await empty.availablePapers(), isEmpty);
    },
  );
  test(
    'RPC exact payload readback canonical, malformed result denied',
    () async {
      final a = ScoringAttempt(
        id: 'attempt',
        title: '시험',
        draft: answerDraft().select(1, 1),
      );
      final score = scoreMcq5([
        [1, 1, 2],
        [2, 1, 2],
        [3, 1, 2],
      ], a.draft.answers);
      var malformed = false;
      final requests = <http.Request>[];
      final repo = SupabaseScoringRepository(
        config,
        MockClient((r) async {
          requests.add(r);
          return http.Response(
            jsonEncode({
              ...score.toJson(),
              'id': a.id,
              'user_id': 'A',
              'exam_subject_id': 'occurrence',
              'paper_variant': 'common',
              'answer_key_version_id': 'key',
              'grade_cutoff_version_id': null,
              'scoring_version': 'mcq5-v1',
              'study_session_id': null,
              'answers': score.answers
                  .map(
                    (v) => {
                      ...v.toJson(),
                      'attempt_id': a.id,
                      'answer_key_version_id': 'key',
                    },
                  )
                  .toList(),
              if (malformed) 'raw_score': 999,
            }),
            200,
          );
        }),
        owner: 'A',
        token: 'offline-token',
      );
      expect((await repo.submit(a)).rawScore, 2);
      expect(requests.length, 2);
      expect((jsonDecode(requests.first.body) as Map).keys.toSet(), {
        'p_attempt_id',
        'p_study_session_id',
        'p_answer_key_version_id',
        'p_grade_cutoff_version_id',
        'p_scoring_version',
        'p_answers',
      });
      expect(requests.first.headers['Authorization'], 'Bearer offline-token');
      malformed = true;
      await expectLater(repo.submit(a), throwsFormatException);
    },
  );
  test(
    'guest service fetches solutions only at submit and never writes cloud',
    () async {
      final calls = <http.Request>[];
      final repo = SupabaseScoringRepository(
        config,
        MockClient((r) async {
          calls.add(r);
          if (r.url.path.endsWith('mock_exam_scoring_availability')) {
            return http.Response(jsonEncode([availability().toJson()]), 200);
          }
          return http.Response(
            jsonEncode([
              for (var n = 1; n <= 3; n++)
                {
                  'question_number': n,
                  'answer_type': 'multiple_choice',
                  'points': 2,
                  if (r.url.queryParameters['select']!.contains(
                    'correct_answer',
                  ))
                    'correct_answer': 1,
                },
            ]),
            200,
          );
        }),
      );
      final d = await repo.prepare(availability());
      expect(calls.every((r) => !r.url.query.contains('correct_answer')), true);
      final result = await repo.submit(
        ScoringAttempt(id: 'local', title: '시험', draft: d.select(1, 1)),
      );
      expect(result.rawScore, 2);
      expect(calls.every((r) => r.method == 'GET'), true);
    },
  );
}
