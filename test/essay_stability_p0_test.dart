import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:legendstudy_app/features/essay/evaluation_report.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/essay/exam_session_status.dart';
import 'package:legendstudy_app/features/essay/exam_session_store.dart';
import 'package:legendstudy_app/features/essay/exam_submission.dart';
import 'package:legendstudy_app/features/essay/shared_history.dart';

import 'auth_lifecycle_sdk_test.dart' show fixtureSession;

ExamSessionStatus status(String first, String second) => ExamSessionStatus({
  'version': 'exam-session-v1',
  'run_id': 'run',
  'state': 'reserved',
  'questions': [
    {'question_id': 'canonical-2', 'state': second},
    {'question_id': 'canonical-1', 'state': first},
  ],
  'retry_allowed': first == 'failed',
});
void main() {
  test('History never translates UUID sort position to an official question number', () {
    SharedEssayRecord row(Map<String, dynamic> data) => SharedEssayRecord(
      id: 'run',
      math: false,
      exam: true,
      examData: data,
      at: DateTime(2026),
      rewrite: false,
      evaluations: [],
    );
    final metadata = {
      'question_ids': ['canonical-2', 'canonical-1'],
      'questions': [
        {'dbQuestionId': 'canonical-1', 'label': '논제 1'},
        {'dbQuestionId': 'canonical-2', 'label': '논제 2'},
      ],
    };
    expect(essayExamQuestionLabel(row(metadata), 'canonical-2'), '논제 2');
    expect(essayExamQuestionLabel(row(metadata), 'canonical-1'), '논제 1');
    expect(
      essayExamQuestionLabel(
        row({
          'question_ids': ['canonical-2', 'canonical-1'],
        }),
        'canonical-2',
      ),
      '문항',
    );
  });
  test(
    'History and progress share one in-flight read and canonical states',
    () async {
      final response = Completer<ExamSessionStatus>();
      var reads = 0;
      final store = ExamSessionStore((_) {
        reads++;
        return response.future;
      });
      addTearDown(store.dispose);
      final history = store.refresh('run'), progress = store.refresh('run');
      expect(identical(history, progress), isTrue);
      response.complete(status('failed', 'completed'));
      expect((await history).questions, {
        'canonical-1': 'failed',
        'canonical-2': 'completed',
      });
      expect(await progress, same(await history));
      expect(reads, 1);
    },
  );
  test(
    'failed refresh and stale regression preserve confirmed success',
    () async {
      var value = status('processing', 'completed');
      var fail = false;
      final store = ExamSessionStore((_) async {
        if (fail) throw TimeoutException('fixture');
        return value;
      });
      addTearDown(store.dispose);
      await store.refresh('run');
      fail = true;
      await expectLater(store.refresh('run'), throwsA(isA<TimeoutException>()));
      expect(
        (await store.watch('run').first).questions['canonical-2'],
        'completed',
      );
      fail = false;
      value = status('failed', 'waiting');
      await expectLater(store.refresh('run'), throwsFormatException);
      expect(
        (await store.watch('run').first).questions['canonical-2'],
        'completed',
      );
    },
  );
  test(
    'retry acknowledgement waits out a pre-retry read then fetches fresh state',
    () async {
      final old = Completer<ExamSessionStatus>();
      var reads = 0;
      final store = ExamSessionStore(
        (_) => ++reads == 1
            ? old.future
            : Future.value(status('waiting', 'completed')),
      );
      addTearDown(store.dispose);
      final polling = store.refresh('run');
      final accepted = store.refreshAfterRetry('run');
      old.complete(status('failed', 'completed'));
      expect((await polling).canRetry, isTrue);
      expect((await accepted).questions['canonical-1'], 'waiting');
      expect(reads, 2);
    },
  );

  test('a disposed owner cannot publish an in-flight observation', () async {
    final response = Completer<ExamSessionStatus>();
    final store = ExamSessionStore((_) => response.future);
    final pending = store.refresh('run');
    store.dispose();
    response.complete(status('completed', 'completed'));
    await expectLater(pending, throwsStateError);
  });

  Future<SupabaseClient> client(
    Future<http.Response> Function(http.Request) rpc,
  ) async {
    final c = SupabaseClient(
      'https://fixture.supabase.co',
      'public-fixture',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((r) async {
        final v = r.url.path.contains('/auth/')
            ? http.Response(jsonEncode(fixtureSession()), 200)
            : await rpc(r);
        return http.Response.bytes(
          v.bodyBytes,
          v.statusCode,
          headers: v.headers,
          request: r,
        );
      }),
    );
    await c.auth.signInWithPassword(
      email: 'student@example.test',
      password: 'fixture',
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'partial result reuses Native report without marking the run completed',
    () {
      final fixtures = jsonDecode(
        File('test/fixtures/exam-history-v1.json').readAsStringSync(),
      ) as Map;
      final row = Map<String, dynamic>.from(fixtures['before'] as Map);
      final id = (row['answers'] as List).first['questionId'] as String;
      final full = examEvaluationReport(row, id);
      row.addAll({
        'state': 'reserved',
        'result_scope': 'completed_question',
        'question_state': 'completed',
      });
      final partial = examEvaluationReport(row, id);
      expect(partial.answer, full.answer);
      expect(row['state'], 'reserved');
      row['question_state'] = 'failed';
      expect(() => examEvaluationReport(row, id), throwsStateError);
    },
  );

  test(
    'submit rejection records HTTP/code without student answer or token',
    () async {
      final c = await client((_) async => throw StateError('unexpected RPC'));
      final events = <Map<String, dynamic>>[];
      var requests = 0;
      final gateway = ExamSubmissionGateway(
        c,
        'fixture-a',
        diagnostic: (v) async => events.add(v),
        transportOverride: MockClient((r) async {
          requests++;
          return http.Response('{"code":"SUBMISSION_REJECTED"}', 422);
        }),
      );
      await expectLater(
        gateway.request({
          'action': 'submit',
          'examId': 'exam',
          'key': 'key',
          'parentId': 'parent',
          'answers': [
            {'body': 'PRIVATE STUDENT ANSWER'},
          ],
        }),
        throwsA(isA<ExamSubmissionRejected>()),
      );
      expect(requests, 1);
      expect(events.last['http_status'], 422);
      expect(events.last['code'], 'SUBMISSION_REJECTED');
      expect(jsonEncode(events), isNot(contains('PRIVATE STUDENT ANSWER')));
      expect(
        jsonEncode(events),
        isNot(contains(c.auth.currentSession!.accessToken)),
      );
    },
  );
  test('lost acknowledgement recovers same run by owner/key with no evaluation POST', () async {
    final paths = <String>[];
    final c = await client((r) async {
      paths.add(r.url.path);
      expect(jsonDecode(r.body), {'p_key': 'same-key', 'p_exam': 'exam'});
      return http.Response(
        jsonEncode({
          'version': 'exam-request-status-v1',
          'found': true,
          'run_id': 'same-run',
          'exam_id': 'exam',
          'parent_id': 'parent',
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    expect(
      await recoverExamRequest(
        c,
        'fixture-a',
        key: 'same-key',
        exam: 'exam',
        parent: 'parent',
      ),
      'same-run',
    );
    expect(paths, ['/rest/v1/rpc/essay_exam_request_status']);
    await expectLater(
      recoverExamRequest(
        c,
        'fixture-a',
        key: 'same-key',
        exam: 'exam',
        parent: 'wrong',
      ),
      throwsFormatException,
    );
  });
}
