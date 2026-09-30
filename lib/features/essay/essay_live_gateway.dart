import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'essay_models.dart';
import 'essay_sentence_review.dart';

/// Only public RPCs and owner-scoped SELECTs. No worker/finance credentials.
abstract interface class EssayStore {
  String? get userId;
  Future<Object?> rpc(String name, Map<String, Object?> params);
  Future<List<Map<String, dynamic>>> rows(
    String table,
    Map<String, Object> filter,
  );
}

class SupabaseEssayStore implements EssayStore {
  SupabaseEssayStore(this.client);
  final SupabaseClient client;
  @override
  String? get userId => client.auth.currentSession?.isExpired == false
      ? client.auth.currentUser?.id
      : null;
  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) =>
      client.rpc(name, params: params);
  @override
  Future<List<Map<String, dynamic>>> rows(
    String table,
    Map<String, Object> filter,
  ) async {
    var query = client.from(table).select();
    for (final entry in filter.entries) {
      query = query.eq(entry.key, entry.value);
    }
    return await query;
  }
}

class EssayClientError implements Exception {
  const EssayClientError(this.code);
  final String code;
  String get message => switch (code) {
    'PT401' => '로그인이 필요해요. 다시 로그인해 주세요.',
    'PT402' => '이 첨삭에 사용할 수 있는 첨삭권이나 포함된 재첨삭 권리가 없어요.',
    'PT403' => '이 학습 기록에 접근할 수 없어요.',
    'PT404' => '학습 기록을 찾을 수 없어요.',
    'PT409' => '저장 내용이나 요청 상태가 변경됐어요. 최신 기록을 확인해 주세요.',
    'PT422' => '문항 자료 또는 요청 내용을 확인해 주세요.',
    'DISABLED' => '실제 첨삭 연결을 준비하고 있어요. 아직 요청할 수 없어요.',
    _ => '연결을 확인하지 못했어요. 입력한 내용은 유지됩니다. 다시 확인해 주세요.',
  };
}

String essayRequestUuid(String scope) {
  final hex = sha256.convert(utf8.encode(scope)).toString();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-4${hex.substring(13, 16)}-a${hex.substring(17, 20)}-${hex.substring(20, 32)}';
}

String newEssayUuid() => essayRequestUuid(
  List.generate(32, (_) => Random.secure().nextInt(256)).join(','),
);

class EssayServerStatus {
  const EssayServerStatus(
    this.state,
    this.creditState,
    this.creditMode,
    this.noCreditConsumed,
  );
  factory EssayServerStatus.parse(Map<String, dynamic> value) {
    final state = value['state'];
    final credit = value['credit_state'];
    final mode = value['credit_mode'];
    if (!['processing', 'reconciling', 'completed', 'failed'].contains(state) ||
        ![
          'reserved',
          'included',
          'settled',
          'released',
          'pending',
        ].contains(credit) ||
        !['paid', 'included', 'pending'].contains(mode) ||
        value['no_credit_consumed'] is! bool ||
        value['release_confirmed'] is! bool) {
      throw const EssayClientError('INVALID_RESPONSE');
    }
    return EssayServerStatus(
      state as String,
      credit as String,
      mode as String,
      state != 'reconciling' && value['no_credit_consumed'] == true,
    );
  }
  final String state, creditState, creditMode;
  final bool noCreditConsumed;
  String get message => switch (state) {
    'processing' => '답안을 분석하고 있어요.',
    'reconciling' => '처리 상태를 확인하고 있어요.\n다시 요청하지 않아도 됩니다.',
    'failed' =>
      noCreditConsumed
          ? '첨삭을 완료하지 못했어요.\n첨삭권은 차감되지 않았습니다.'
          : '첨삭을 완료하지 못했어요. 첨삭권 처리 상태를 확인해 주세요.',
    _ => '첨삭이 완료됐어요.',
  };
  String? get creditMessage => state == 'reconciling'
      ? null
      : switch (creditState) {
          'included' => '이번 재첨삭은 추가 첨삭권 없이 이용할 수 있어요.',
          'reserved' => '첨삭권 1회가 예약됐어요. 첨삭 완료 시 사용됩니다.',
          'settled' =>
            creditMode == 'included' ? '추가 첨삭권 없이 완료됐어요.' : '첨삭권 사용이 확정됐어요.',
          'released' => noCreditConsumed ? '첨삭권 예약이 해제됐어요.' : null,
          _ => null,
        };
}

class EssayPending implements Exception {
  const EssayPending(this.status);
  final EssayServerStatus status;
}

class EssayHistory {
  const EssayHistory(this.attempts, this.evaluations, this.progress);
  final List<Map<String, dynamic>> attempts, evaluations, progress;
}

/// Bound to one authenticated identity and one persisted cycle. Never a preview fallback.
class SupabaseEssayGateway implements EssayGateway {
  SupabaseEssayGateway(
    this.store, {
    required this.questionId,
    this.writesEnabled = false,
    this.evaluationsEnabled = false,
    this.regime = 'essay-v1.3',
  }) : ownerId = store.userId;
  final EssayStore store;
  final String questionId, regime;
  final String? ownerId;
  final bool writesEnabled, evaluationsEnabled;
  bool _revoked = false;
  String? sessionId, evaluationId, attemptId;
  String submittedAnswer = '';
  EssayServerStatus? status;
  EssaySentenceReview? sentenceReview;
  List<String> evidenceLabels = [];
  EssayHistory history = const EssayHistory([], [], []);
  String? _evaluationKey;
  String mode = 'practice';
  String deviceClass = 'app_mobile';
  void revoke() {
    _revoked = true;
  }

  void _auth() {
    if (_revoked || ownerId == null || store.userId != ownerId) {
      throw const EssayClientError('PT401');
    }
  }

  Future<T> _guard<T>(Future<T> Function() operation) async {
    _auth();
    try {
      final value = await operation();
      _auth();
      return value;
    } on PostgrestException catch (e) {
      _auth();
      throw EssayClientError(e.code ?? 'NETWORK');
    }
  }

  Future<List<Map<String, dynamic>>> read(
    String table,
    Map<String, Object> filter,
  ) => _guard(() => store.rows(table, filter));
  Future<Object?> _rpc(String name, Map<String, Object?> args) =>
      _guard(() => store.rpc(name, args));
  void _write() {
    _auth();
    if (!writesEnabled) throw const EssayClientError('DISABLED');
  }

  String get _session => sessionId ?? (throw const EssayClientError('PT404'));

  Future<EssayDraft> open({String? resumeSession}) async {
    _auth();
    if (resumeSession != null) {
      final own = await read('essay_practice_sessions', {
        'id': resumeSession,
        'user_id': ownerId!,
        'question_id': questionId,
      });
      if (own.length != 1) throw const EssayClientError('PT404');
      sessionId = resumeSession;
    } else if (sessionId == null) {
      final sessions = await read('essay_practice_sessions', {
        'user_id': ownerId!,
        'question_id': questionId,
      });
      sessions.sort(
        (a, b) => '${b['created_at']}/${b['id']}'.compareTo(
          '${a['created_at']}/${a['id']}',
        ),
      );
      if (sessions.isNotEmpty) {
        sessionId = sessions.first['id'] as String;
      } else {
        _write();
        sessionId = essayRequestUuid(
          'essay-default-cycle/v1/$ownerId/$questionId',
        );
      }
    }
    // Reusing the same UUID on retry is safe; no new cycle on screen re-entry.
    if (writesEnabled) {
      await _rpc('essay_open_session', {
        'p_id': _session,
        'p_question': questionId,
      });
    }
    final draft = await loadDraft();
    await loadHistory();
    if (history.attempts.isNotEmpty) {
      final last = history.attempts.last;
      final evals = history.evaluations
          .where((e) => e['attempt_id'] == last['id'])
          .toList();
      if (evals.isNotEmpty) {
        evaluationId = evals.last['id'] as String;
        attemptId = last['id'] as String;
        submittedAnswer = last['body'] as String;
      }
    }
    return draft;
  }

  @override
  Future<EssayDraft> loadDraft() async {
    final rows = await read('essay_drafts', {'session_id': _session});
    if (rows.length != 1) throw const EssayClientError('PT404');
    mode = rows.single['mode'] as String;
    return EssayDraft(
      rows.single['body'] as String,
      rows.single['revision'] as int,
    );
  }

  @override
  Future<EssayDraft> saveDraft(String body, int expectedRevision) async {
    _write();
    try {
      final rev = await _rpc('essay_save_draft', {
        'p_session': _session,
        'p_revision': expectedRevision,
        'p_body': body,
        'p_device': deviceClass,
        'p_mode': mode,
        'p_active_seconds': null,
      });
      return EssayDraft(body, rev as int);
    } on EssayClientError catch (e) {
      if (e.code == 'PT409') throw EssayConflict();
      rethrow;
    }
  }

  @override
  Future<String> submit(
    String body,
    int expectedRevision,
    String requestKey,
  ) async {
    _write();
    final hash = sha256.convert(utf8.encode(body)).toString();
    // Stable across restarts/network loss; payload remains part of the server fingerprint.
    final key = essayRequestUuid('$_session/$expectedRevision/$hash');
    try {
      final id = await _rpc('essay_submit_attempt', {
        'p_session': _session,
        'p_revision': expectedRevision,
        'p_key': key,
        'p_body_hash': hash,
      }) as String;
      attemptId = id;
      submittedAnswer = body;
      return id;
    } on EssayClientError catch (e) {
      if (e.code == 'PT409') throw EssayConflict();
      rethrow;
    }
  }

  @override
  Future<EssayEvaluation> requestEvaluation(String attemptId) async {
    _write();
    if (!evaluationsEnabled) throw const EssayClientError('DISABLED');
    if (this.attemptId != null && this.attemptId != attemptId) {
      throw const EssayClientError('PT409');
    }
    this.attemptId = attemptId;
    if (evaluationId == null) {
      _evaluationKey ??= essayRequestUuid('$attemptId/$regime');
      evaluationId = await _rpc('essay_request_evaluation', {
        'p_attempt': attemptId,
        'p_key': _evaluationKey,
        'p_regime': regime,
      }) as String;
    }
    return poll();
  }

  Future<EssayEvaluation> poll() async {
    final id = evaluationId;
    if (id == null) throw const EssayClientError('PT404');
    status = EssayServerStatus.parse(
      Map<String, dynamic>.from(
        await _rpc('essay_evaluation_status', {'p_evaluation': id}) as Map,
      ),
    );
    if (status!.state != 'completed') throw EssayPending(status!);
    return loadResult(id);
  }

  void beginRevision() {
    _auth();
    evaluationId = null;
    attemptId = null;
    status = null;
    _evaluationKey = null;
  }

  void retryConfirmedFailure() {
    _auth();
    if (status?.state != 'failed') throw const EssayClientError('PT409');
    evaluationId = null;
    status = null;
    _evaluationKey = newEssayUuid();
  }

  Future<EssayHistory> loadHistory() async {
    final attempts = await read('essay_attempts', {'session_id': _session});
    final evaluations = await read('essay_evaluations', {
      'session_id': _session,
    });
    final progress = await read('essay_improvement_progress', {
      'session_id': _session,
    });
    attempts.sort(
      (a, b) => (a['attempt_no'] as int).compareTo(b['attempt_no'] as int),
    );
    evaluations.sort(
      (a, b) => '${a['requested_at']}/${a['id']}'.compareTo(
        '${b['requested_at']}/${b['id']}',
      ),
    );
    progress.sort(
      (a, b) => '${a['created_at']}/${a['id']}'.compareTo(
        '${b['created_at']}/${b['id']}',
      ),
    );
    return history = EssayHistory(attempts, evaluations, progress);
  }

  Future<EssayEvaluation> loadResult(String id) async {
    final evaluations = await read('essay_evaluations', {
      'id': id,
      'session_id': _session,
    });
    if (evaluations.length != 1) throw const EssayClientError('PT404');
    final e = evaluations.single;
    final attempts = await read('essay_attempts', {
      'id': e['attempt_id'] as String,
      'session_id': _session,
    });
    final dims = await read('essay_evaluation_dimensions', {
      'evaluation_id': id,
    });
    final criteria = await read('essay_evaluation_criteria', {
      'question_id': questionId,
    });
    final progress = await read('essay_improvement_progress', {
      'evaluation_id': id,
    });
    final evidence = await read('essay_evaluation_evidence', {
      'evaluation_id': id,
    });
    final mappings = await read('essay_question_evidence', {
      'question_id': questionId,
    });
    final examples = await read('essay_generated_rewrites', {
      'evaluation_id': id,
    });
    await loadHistory();
    final snapshot = e['input_snapshot'] as Map;
    final previousId =
        (snapshot['scaffolding_context']
            as Map?)?['selected_previous_evaluation_id'];
    final previousEvaluations = history.evaluations
        .where((row) => row['id'] == previousId)
        .toList();
    final previousDimensions = previousEvaluations.isEmpty
        ? <Map<String, dynamic>>[]
        : await read('essay_evaluation_dimensions', {
            'evaluation_id': previousId as String,
          });
    final result = mapEssayResult(
      evaluation: e,
      attempt: attempts.single,
      dimensions: dims,
      criteria: criteria,
      progress: progress,
      history: history,
      evidence: evidence,
      mappings: mappings,
      examples: examples,
      previousEvaluation: previousEvaluations.isEmpty
          ? null
          : previousEvaluations.single,
      previousDimensions: previousDimensions,
      included: status?.creditMode == 'included',
    );
    sentenceReview = result.sentences;
    evidenceLabels = result.evidence;
    submittedAnswer = attempts.single['body'] as String;
    attemptId = e['attempt_id'] as String;
    return result.evaluation;
  }
}

class MappedEssayResult {
  const MappedEssayResult(this.evaluation, this.sentences, this.evidence);
  final EssayEvaluation evaluation;
  final EssaySentenceReview? sentences;
  final List<String> evidence;
}

List<String> _strings(Object? value) => (value as List? ?? []).cast<String>();

MappedEssayResult mapEssayResult({
  required Map<String, dynamic> evaluation,
  required Map<String, dynamic> attempt,
  required List<Map<String, dynamic>> dimensions,
  required List<Map<String, dynamic>> criteria,
  required List<Map<String, dynamic>> progress,
  required EssayHistory history,
  required List<Map<String, dynamic>> evidence,
  required List<Map<String, dynamic>> mappings,
  required List<Map<String, dynamic>> examples,
  required bool included,
  Map<String, dynamic>? previousEvaluation,
  List<Map<String, dynamic>> previousDimensions = const [],
}) {
  final e = evaluation;
  if (e['status'] != 'completed' ||
      e['invalidated_at'] != null ||
      e['attempt_id'] != attempt['id'] ||
      sha256.convert(utf8.encode(attempt['body'] as String)).toString() !=
          attempt['body_sha256']) {
    throw const EssayClientError('INVALID_RESPONSE');
  }
  final snapshot = Map<String, dynamic>.from(e['input_snapshot'] as Map);
  final criterionVersions = {
    for (final c in (snapshot['criteria'] as List)) c['id']: c['version'],
  };
  final criteriaById = {for (final c in criteria) c['id']: c};
  final dims = [...dimensions]
    ..sort(
      (a, b) =>
          (a['display_order'] as int).compareTo(b['display_order'] as int),
    );
  final items = [...progress]
    ..sort((a, b) => (a['priority'] as int).compareTo(b['priority'] as int));
  final sentences = <EssaySentenceItem>[];
  final priorities = <String>[];
  final changes = <String, List<String>>{};
  final scaffold = e['contract_version'] == '1.3';
  final previous = Map<String, dynamic>.from(
    snapshot['scaffolding_context'] as Map? ?? {},
  );
  final priorIds = {
    for (final x in (previous['items'] as List? ?? [])) x['progress_id'],
  };
  for (final p in items) {
    if (p['evaluation_id'] != e['id']) {
      throw const EssayClientError('INVALID_RESPONSE');
    }
    final env = p['scaffolding_observation'];
    if (scaffold && env == null) {
      throw const EssayClientError('INVALID_RESPONSE');
    }
    if (p['status'] != 'resolved' && (!scaffold || env['core_focus'] == true)) {
      priorities.add(p['next_action'] as String);
    }
    if (p['previous_progress_id'] != null &&
        priorIds.contains(p['previous_progress_id'])) {
      final label = switch (p['status']) {
        'resolved' => '해결한 부분',
        'improved' => '좋아지고 있는 부분',
        'recurred' => '다시 나타난 부분',
        _ => '아직 확인할 부분',
      };
      changes.putIfAbsent(label, () => []).add(p['explanation'] as String);
    }
    if (env != null) {
      if (env['version'] != 1) throw const EssayClientError('INVALID_RESPONSE');
      for (final s in env['sentences'] as List) {
        sentences.add(
          EssaySentenceItem(
            id: s['observation_key'] as String,
            category: EssaySentenceCategory.values.byName(
              s['category'] as String,
            ),
            priority: switch (s['priority']) {
              'contradiction' => EssaySentencePriority.contradiction,
              'unclear_meaning' => EssaySentencePriority.unclearMeaning,
              'grammar_agreement' => EssaySentencePriority.grammarAgreement,
              'wording' => EssaySentencePriority.wording,
              _ => throw const EssayClientError('INVALID_RESPONSE'),
            },
            start: s['start'] as int,
            end: s['end'] as int,
            quote: s['quote'] as String,
            diagnosis: s['diagnosis'] as String,
            direction: s['direction'] as String,
            example: s['example'] as String?,
          ),
        );
      }
    }
  }
  final review = scaffold
      ? EssaySentenceReview(
          evaluationId: e['id'] as String,
          attemptId: attempt['id'] as String,
          items: sentences,
        )
      : null;
  if (sentences.length > 5 ||
      (scaffold && priorities.length > 3) ||
      (review != null &&
          review
                  .verified(
                    e['id'] as String,
                    attempt['id'] as String,
                    attempt['body'] as String,
                  )
                  .length !=
              sentences.length)) {
    throw const EssayClientError('INVALID_RESPONSE');
  }
  final prev = previousEvaluation;
  final comparable =
      prev != null &&
      previous['selected_previous_evaluation_id'] == prev['id'] &&
      prev['status'] == 'completed' &&
      prev['invalidated_at'] == null &&
      prev['session_id'] == e['session_id'] &&
      prev['attempt_id'] != e['attempt_id'] &&
      prev['regime_key'] == e['regime_key'] &&
      prev['contract_version'] == e['contract_version'] &&
      prev['model_provider'] == e['model_provider'] &&
      prev['model_name'] == e['model_name'] &&
      prev['model_version'] == e['model_version'] &&
      jsonEncode((prev['input_snapshot'] as Map)['criteria']) ==
          jsonEncode(snapshot['criteria']) &&
      jsonEncode((prev['input_snapshot'] as Map)['evidence']) ==
          jsonEncode(snapshot['evidence']);
  final priorLevels = {
    for (final d in previousDimensions.where(
      (d) => comparable && d['evaluation_id'] == prev['id'],
    ))
      d['criterion_id']: d['level_1_to_5'],
  };
  final mappedDimensions = <EssayDimension>[];
  for (final d in dims) {
    final c = criteriaById[d['criterion_id']];
    if (c == null ||
        criterionVersions[c['id']] != c['definition_version'] ||
        d['evaluation_id'] != e['id']) {
      throw const EssayClientError('INVALID_RESPONSE');
    }
    if (comparable &&
        priorLevels[c['id']] is int &&
        d['level_1_to_5'] is int &&
        (d['level_1_to_5'] as int) > (priorLevels[c['id']] as int)) {
      changes.putIfAbsent('좋아진 부분', () => []).add(d['explanation'] as String);
    }
    mappedDimensions.add(
      EssayDimension(
        c['id'] as String,
        c['label'] as String,
        d['level_1_to_5'] as int?,
        d['explanation'] as String,
        officialWeight: c['official_weight_percent'] as num?,
        previousLevel: priorLevels[c['id']] as int?,
      ),
    );
  }
  final evidenceById = {for (final m in mappings) m['id']: m};
  const roles = {
    'question': '문제 요구',
    'passage': '제시문',
    'exam_intent': '대학 공식 출제 의도',
    'scoring_criteria': '대학 공식 평가 기준',
  };
  final labels = <String>[];
  for (final ref in evidence) {
    final m = evidenceById[ref['evidence_id']];
    if (m == null) {
      continue; // No fabricated citation if canonical source is unavailable.
    }
    labels.add(roles[m['role']] ?? '공식 평가 자료');
  }
  final validExamples = examples.where(
    (r) => r['status'] == 'completed' && r['origin'] == 'ai_generated',
  );
  return MappedEssayResult(
    EssayEvaluation(
      summary: e['overall_summary'] as String,
      strengths: _strings(e['strengths']),
      dimensions: mappedDimensions,
      improvements: items
          .where((p) => p['status'] != 'resolved')
          .map((p) => p['explanation'] as String)
          .toList(),
      overviewImprovements: scaffold
          ? items
                .where(
                  (p) =>
                      p['status'] != 'resolved' &&
                      p['scaffolding_observation']['core_focus'] == true,
                )
                .map((p) => p['explanation'] as String)
                .toList()
          : null,
      priorities: priorities,
      checklist: _strings(e['rewrite_checklist']),
      example: validExamples.isEmpty
          ? ''
          : validExamples.single['body'] as String,
      changes: changes,
      includedRevision: included,
      comparable: comparable,
      uncertainty: e['uncertainty_note'] as String?,
    ),
    review,
    labels.toSet().toList(),
  );
}
