// Explicit opt-in ONLY. Credentials are generated privately for disposable local Auth.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:legendstudy_app/features/essay/essay_live_gateway.dart';
import 'package:legendstudy_app/features/essay/essay_models.dart';

void main() {
  final path = Platform.environment['ESSAY_L1_CLIENT_FIXTURE'];
  test(
    'actual local Auth JWT → Dart SupabaseEssayGateway → public RPC / RLS',
    () async {
      final overrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = overrides);
      final cfg =
          jsonDecode(File(path!).readAsStringSync()) as Map<String, dynamic>;
      final url = cfg['url'] as String;
      expect(Uri.parse(url).host, '127.0.0.1');
      final client = SupabaseClient(url, cfg['anon'] as String);
      final other = SupabaseClient(url, cfg['anon'] as String);
      addTearDown(client.dispose);
      addTearDown(other.dispose);
      final users = cfg['users'] as List;
      await client.auth.signInWithPassword(
        email: users[0]['email'] as String,
        password: users[0]['password'] as String,
      );
      await other.auth.signInWithPassword(
        email: users[1]['email'] as String,
        password: users[1]['password'] as String,
      );
      final store = SupabaseEssayStore(client);
      SupabaseEssayGateway gateway({String regime = 'essay-v1.3'}) =>
          SupabaseEssayGateway(
            store,
            questionId: cfg['question'] as String,
            writesEnabled: true,
            evaluationsEnabled: true,
            regime: regime,
          );
      Future<dynamic> worker(
        String operation,
        Map<String, Object?> args,
      ) async {
        final response = await http.post(
          Uri.parse('$url/rest/v1/rpc/$operation'),
          headers: {
            'apikey': cfg['anon'] as String,
            'Authorization': 'Bearer ${cfg['worker']}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(args),
        );
        if (response.statusCode != 200 && response.statusCode != 204) {
          throw StateError('Synthetic worker HTTP ${response.statusCode}');
        }
        return response.body.isEmpty ? null : jsonDecode(response.body);
      }

      Future<Map<String, dynamic>> claim(String id) async =>
          Map<String, dynamic>.from(
            await worker('essay_claim', {'p_evaluation': id}) as Map,
          );
      Future<void> finish(
        SupabaseEssayGateway g,
        Map<String, dynamic> lease,
      ) async {
        final row = (await store.rows('essay_evaluations', {
          'id': g.evaluationId!,
        })).single;
        final snap = row['input_snapshot'] as Map;
        final output = <String, Object?>{
          'contract_version': row['contract_version'],
          'summary': '합성 첨삭 결과',
          'strengths': ['원문을 유지했어요.'],
          'checklist': ['근거를 확인해 보세요.'],
          'dimensions': [
            {
              'criterion_id': cfg['criterion'],
              'level': 4,
              'explanation': '합성 진단',
              'evidence_ids': [cfg['evidence']],
            },
          ],
          'improvements': [],
        };
        if (row['contract_version'] == '1.3') {
          output.addAll({
            'attempt_id': row['attempt_id'],
            'answer_hash': snap['answer_hash'],
            'core_improvement_keys': [],
            'previous_improvement_reviews': [],
            'sentence_feedback': [],
            'local_reviews': [],
          });
        }
        await worker('essay_finalize_success', {
          'p_evaluation': g.evaluationId,
          'p_run': lease['run_id'],
          'p_token': lease['lease_token'],
          'p_output': output,
        });
      }

      final g = gateway();
      var draft = await g.open();
      final session = g.sessionId;
      final resumed = gateway();
      await resumed.open();
      expect(resumed.sessionId, session);
      draft = await g.saveDraft('합성 답안 😀 가', draft.revision);
      await expectLater(
        g.saveDraft('충돌', draft.revision - 1),
        throwsA(isA<EssayConflict>()),
      );
      final id = await g.submit(draft.body, draft.revision, '');
      expect(await g.submit(draft.body, draft.revision, ''), id);
      await expectLater(g.requestEvaluation(id), throwsA(isA<EssayPending>()));
      expect(g.status!.creditState, 'reserved');
      final e = g.evaluationId!;
      final lease = await claim(e);
      await worker('essay_timeout', {
        'p_evaluation': e,
        'p_run': lease['run_id'],
        'p_token': lease['lease_token'],
      });
      await expectLater(g.poll(), throwsA(isA<EssayPending>()));
      expect(g.status!.state, 'reconciling');
      expect(g.status!.noCreditConsumed, false);
      Future<void> clock(String seconds) async {
        final result = await Process.run(
          Platform.environment['ESSAY_L1_PYTHON']!,
          [
            '-B',
            'tool/essay_lab/prepare_l1_client_fixture.py',
            '--clock',
            seconds,
          ],
        );
        expect(result.exitCode, 0, reason: 'Guarded local test clock');
      }

      await clock('121');
      addTearDown(() => clock('0'));
      final next = await claim(e);
      await expectLater(finish(g, lease), throwsStateError);
      await finish(g, next);
      final result = await g.poll();
      expect(result.summary, '합성 첨삭 결과');
      expect(g.sentenceReview!.items, isEmpty);
      expect(g.status!.state, 'completed');
      g.beginRevision();
      expect(g.sessionId, session);
      draft = await g.saveDraft('직접 재작성한 합성 답안', draft.revision);
      final second = await g.submit(draft.body, draft.revision, '');
      await expectLater(
        g.requestEvaluation(second),
        throwsA(isA<EssayPending>()),
      );
      expect(g.status!.creditMode, 'included');
      await finish(g, await claim(g.evaluationId!));
      final secondResult = await g.poll();
      expect(secondResult.comparable, true);
      expect(secondResult.dimensions.single.previousLevel, 4);
      g.beginRevision();
      draft = await g.saveDraft('세 번째 합성 답안', draft.revision);
      final third = await g.submit(draft.body, draft.revision, '');
      await expectLater(
        g.requestEvaluation(third),
        throwsA(isA<EssayPending>()),
      );
      final failedLease = await claim(g.evaluationId!);
      await worker('essay_finalize_failure', {
        'p_evaluation': g.evaluationId,
        'p_run': failedLease['run_id'],
        'p_token': failedLease['lease_token'],
      });
      await expectLater(g.poll(), throwsA(isA<EssayPending>()));
      expect(g.status!.state, 'failed');
      expect(g.status!.creditState, 'released');
      expect(g.status!.noCreditConsumed, true);
      g.retryConfirmedFailure();
      await expectLater(
        g.requestEvaluation(third),
        throwsA(isA<EssayPending>()),
      );
      await finish(g, await claim(g.evaluationId!));
      await g.poll();
      final legacy = gateway(regime: 'essay-v1.2');
      await legacy.open();
      legacy.beginRevision();
      final ld = await legacy.saveDraft('legacy 합성 답안', draft.revision);
      final la = await legacy.submit(ld.body, ld.revision, '');
      await expectLater(
        legacy.requestEvaluation(la),
        throwsA(isA<EssayPending>()),
      );
      await finish(legacy, await claim(legacy.evaluationId!));
      await legacy.poll();
      expect(legacy.sentenceReview, null);
      final history = await g.loadHistory();
      expect(history.attempts.length, 4);
      expect(history.evaluations.length, 5);
      final otherGateway = SupabaseEssayGateway(
        SupabaseEssayStore(other),
        questionId: cfg['question'] as String,
        writesEnabled: true,
        evaluationsEnabled: true,
      );
      await expectLater(
        otherGateway.open(resumeSession: session),
        throwsA(isA<EssayClientError>()),
      );
      await expectLater(
        other.rpc<Object?>(
          'essay_evaluation_status',
          params: {'p_evaluation': e},
        ),
        throwsA(isA<PostgrestException>()),
      );
      expect(
        await other
            .from('essay_attempts')
            .select('id')
            .eq('session_id', session!),
        isEmpty,
      );
      final ledgerBefore = await client
          .from('credit_transactions')
          .select('id');
      await client.rpc<Object?>('essay_erase', params: {'p_session': session});
      expect(
        await client
            .from('essay_attempts')
            .select('id')
            .eq('session_id', session),
        isEmpty,
      );
      expect(
        (await client.from('credit_transactions').select('id')).length,
        ledgerBefore.length,
      );
      await expectLater(g.poll(), throwsA(isA<EssayClientError>()));
      await client.auth.signOut();
      await expectLater(g.loadDraft(), throwsA(isA<EssayClientError>()));
    },
    skip: path == null
        ? 'Explicit disposable local fixture not supplied'
        : false,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
