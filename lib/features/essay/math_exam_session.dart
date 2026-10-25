import '../../core/supabase/supabase_providers.dart';

import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../credits/credit_balance.dart';
import 'answer_image.dart';
import 'math_gateway.dart';
import 'source_draft.dart';
import 'shared_history.dart';

Map<String, dynamic> parseMathSession(dynamic value) {
  if (value is! Map ||
      value['version'] != 'math-session-v1' ||
      value['run_id'] is! String ||
      value['questions'] is! List ||
      (value['questions'] as List).isEmpty) {
    throw const FormatException('INVALID_SESSION');
  }
  final result = Map<String, dynamic>.from(value);
  for (final q in result['questions'] as List) {
    if (q is! Map ||
        q['evaluation_id'] is! String ||
        q['attempt_id'] is! String ||
        q['question_id'] is! String) {
      throw const FormatException('INVALID_SESSION');
    }
  }
  return result;
}

bool mathSessionRetryable(Map<String, dynamic> run) {
  final rows = (run['questions'] as List).cast<Map<String, dynamic>>();
  return run['state'] == 'reserved' &&
      rows.any((q) => q['state'] == 'FAILED') &&
      rows.every((q) => ['FAILED', 'COMPLETED'].contains(q['state']));
}

/// Prepares immutable inputs using the existing Math gateway, then submits one
/// financial round. Durable keys survive lost responses and process restarts.
class MathExamSession extends ConsumerStatefulWidget {
  const MathExamSession({
    required this.owner,
    required this.exam,
    required this.selected,
    required this.leaves,
    super.key,
  });
  final String owner;
  final Map<String, dynamic> exam;
  final Set<String> selected;
  final Map<String, String> leaves;
  @override
  ConsumerState<MathExamSession> createState() => _MathExamSessionState();
}

class _MathExamSessionState extends ConsumerState<MathExamSession> {
  bool busy = false, loaded = false;
  String? notice, parent;
  Map<String, dynamic>? pending, accepted;
  final inputs = <String, Map<String, dynamic>>{},
      corrections = <String, String>{};
  List<Map<String, dynamic>> parents = [];
  MathGateway get gateway => ref.read(mathGatewayProvider(widget.owner))!;
  List<Map<String, dynamic>> get questions =>
      (widget.exam['questions'] as List).cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> get selected =>
      questions.where((q) => widget.selected.contains(q['key'])).toList();
  SourceDraftGateway get store => SourceDraftGateway(
    widget.owner,
    'math-session:${widget.exam['dbExamId']}:${parent ?? 'initial'}:${(widget.selected.toList()..sort()).join(',')}',
  );
  bool get current =>
      mounted && ref.read(authStateProvider).value?.userId == widget.owner;
  @override
  void initState() {
    super.initState();
    Future.microtask(() => work(load));
  }

  Future<void> work(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      notice = null;
    });
    try {
      await ref.read(authStateProvider.future);
      gateway.checkOwner();
      await action();
    } catch (_) {
      if (current) {
        setState(
          () => notice =
              '처리 상태를 확인하지 못했어요. 저장한 답안과 요청은 유지됩니다. 같은 요청으로 다시 확인해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> load() async {
    final history = await gateway.session('math_session_history', {});
    if (history is! Map ||
        history['version'] != 'math-session-history-v1' ||
        history['runs'] is! List) {
      throw const FormatException('HISTORY');
    }
    parents = (history['runs'] as List)
        .map(parseMathSession)
        .where(
          (r) =>
              r['exam_id'] == widget.exam['dbExamId'] &&
              r['free_rewrite_available'] == true,
        )
        .toList();
    final saved = await store.loadDraft();
    pending = saved.body.isEmpty
        ? null
        : Map<String, dynamic>.from(jsonDecode(saved.body) as Map);
    if (pending?['runId'] is String) {
      accepted = parseMathSession(
        await gateway.session('math_session_read', {
          'p_run': pending!['runId'],
        }),
      );
    }
    if (current) setState(() => loaded = true);
  }

  Future<void> persist() async {
    gateway.checkOwner();
    final saved = await store.loadDraft();
    await store.saveLocalDraft(
      pending == null ? '' : jsonEncode(pending),
      saved.revision,
    );
    gateway.checkOwner();
  }

  Future<void> prepare() async {
    if (selected.isEmpty) return;
    final rows = <Map<String, dynamic>>[];
    for (final q in selected) {
      final draft = SourceDraftGateway(widget.owner, q['key'] as String);
      final body = (await draft.loadDraft()).body;
      final images = await draft.loadImages();
      if (body.trim().isEmpty && images.isEmpty) throw StateError('EMPTY');
      rows.add({
        'q': q,
        'body': body,
        'images': images,
        'hashes': images.map((b) => sha256.convert(b).toString()).toList(),
      });
    }
    final fingerprint = jsonEncode({
      'parent': parent,
      'answers': rows
          .map(
            (r) => {
              'id': (r['q'] as Map)['dbQuestionId'],
              'body': r['body'],
              'hashes': r['hashes'],
            },
          )
          .toList(),
    });
    if (pending != null && pending!['fingerprint'] != fingerprint) {
      throw StateError('ANSWER_CHANGED');
    }
    pending ??= {
      'key': mathRequestId(),
      'fingerprint': fingerprint,
      'attemptKeys': <String, dynamic>{},
      'attempts': <String, dynamic>{},
    };
    await persist();
    if (pending!['submitted'] == true) return;
    final prior = parents.where((r) => r['run_id'] == parent).firstOrNull;
    if (parent != null &&
        (prior == null ||
            (prior['questions'] as List).length != selected.length)) {
      throw StateError('FROZEN_SET');
    }
    for (final row in rows) {
      final q = row['q'] as Map;
      final key = q['key'] as String;
      final images = (row['images'] as List).cast<Uint8List>();
      final body = row['body'] as String;
      final previous = (prior?['questions'] as List? ?? [])
          .cast<Map<String, dynamic>>()
          .where((p) => p['question_id'] == q['dbQuestionId'])
          .firstOrNull;
      if (parent != null && previous == null) throw StateError('FROZEN_SET');
      final keys = pending!['attemptKeys'] as Map,
          attempts = pending!['attempts'] as Map;
      keys[key] ??= mathRequestId();
      await persist();
      if (attempts[key] == null) {
        final created = await gateway.call('math_input', 'create_attempt', {
          'client_submission_id': keys[key],
          'leaf_id': widget.leaves[q['dbQuestionId']],
          'kind': previous == null ? 'INITIAL' : 'FULL_RESOLVE',
          'input_kind': images.isEmpty
              ? 'TYPED'
              : body.trim().isEmpty
              ? 'EVIDENCE'
              : 'MIXED',
          if (body.trim().isNotEmpty) 'typed_answer': body,
          if (previous != null) ...{
            'predecessor_id': previous['attempt_id'],
            'prior_evaluation_id': previous['evaluation_id'],
          },
        });
        attempts[key] = created['attempt_id'];
        await persist();
      }
      final id = attempts[key];
      var input = await gateway.call('math_input', 'read_input', {
        'attempt_id': id,
      });
      if (images.isNotEmpty &&
          input['input_state'] == 'INPUT_REQUIRED' &&
          (input['candidate'] == null ||
              (input['candidate'] as Map)['state'] == 'FAILED')) {
        for (var i = 0; i < images.length; i++) {
          final artifact = await gateway.call(
            'math_input',
            'register_evidence',
            {
              'attempt_id': id,
              'metadata': {
                'position': i + 1,
                'media_type': answerImageType(images[i]),
                'byte_size': images[i].length,
                'content_sha256': (row['hashes'] as List)[i],
              },
            },
          );
          await gateway.uploadEvidence(
            artifact['artifact_id'] as String,
            images[i],
          );
        }
        await gateway.extract(id as String);
        input = await gateway.call('math_input', 'read_input', {
          'attempt_id': id,
        });
      }
      inputs[key] = input;
    }
    if (current) {
      setState(() => notice = '입력 확인에는 크레딧이 사용되지 않습니다. 사진에서 읽은 내용을 확인해 주세요.');
    }
  }

  Future<void> confirm(String key) async {
    final input = inputs[key]!;
    await gateway.call('math_input', 'confirm_extraction', {
      'attempt_id': (pending!['attempts'] as Map)[key],
      'run_id':
          (input['candidate'] as Map)['run_id'] ??
          (input['candidate'] as Map)['id'],
      'regions': [
        for (final r in input['candidate_regions'] as List)
          {
            'region_id': r['region_id'] ?? r['id'],
            'raw_text':
                corrections['${r['region_id'] ?? r['id']}'] ??
                r['normalized_math'] ??
                r['raw_text'],
            'normalized_math':
                corrections['${r['region_id'] ?? r['id']}'] ??
                r['normalized_math'] ??
                r['raw_text'],
          },
      ],
    });
    inputs[key] = await gateway.call('math_input', 'read_input', {
      'attempt_id': (pending!['attempts'] as Map)[key],
    });
  }

  Future<void> dispatch() async {
    final run = parseMathSession(
      await gateway.session('math_session_read', {'p_run': pending!['runId']}),
    );
    for (final q in run['questions'] as List) {
      if (q['state'] == 'REQUESTED') {
        try {
          await gateway.evaluate(q['evaluation_id'] as String);
        } catch (_) {
          gateway.checkOwner();
        }
      }
    }
    accepted = parseMathSession(
      await gateway.session('math_session_read', {'p_run': run['run_id']}),
    );
    ref.invalidate(creditBalanceProvider);
    ref.invalidate(sharedEssayHistoryProvider(widget.owner));
  }

  Future<void> submit() async {
    if (pending == null) return;
    if (pending!['submitted'] != true) {
      await prepare();
      if (!selected.every(
        (q) => inputs[q['key']]?['can_request_evaluation'] == true,
      )) {
        return;
      }
      final missing = questions
          .where((q) => !widget.selected.contains(q['key']))
          .map((q) => q['label'])
          .join(', ');
      if (!mounted || !current) return;
      final yes = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(missing.isEmpty ? '시험 회차 첨삭' : '작성하지 않은 답안이 있습니다'),
          content: Text(
            '${missing.isEmpty ? '' : '$missing 문항은 이번 첨삭에 포함되지 않습니다.\n'}이번 첨삭에는 ${parent == null ? 1 : 0} 크레딧이 사용됩니다.\n미제출 문항을 나중에 첨삭받으면 별도 회차로 1 크레딧이 사용됩니다.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('계속 작성하기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text('${parent == null ? 1 : 0} 크레딧 사용하고 첨삭하기'),
            ),
          ],
        ),
      );
      if (yes != true || !current) return;
      pending!['submitted'] = true;
      await persist();
    }
    if (pending!['runId'] == null) {
      final id = await gateway.session('math_session_submit', {
        'p_exam': widget.exam['dbExamId'],
        'p_key': pending!['key'],
        'p_attempts': selected
            .map((q) => (pending!['attempts'] as Map)[q['key']])
            .toList(),
        'p_parent': parent,
      });
      if (id is! String) throw const FormatException('RUN');
      pending!['runId'] = id;
      await persist();
    }
    await dispatch();
  }

  Future<void> retry() async {
    pending!['retryKey'] ??= mathRequestId();
    await persist();
    await gateway.session('math_session_retry', {
      'p_run': pending!['runId'],
      'p_key': pending!['retryKey'],
    });
    pending!.remove('retryKey');
    await persist();
    await dispatch();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authStateProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!loaded)
          TextButton(
            onPressed: busy ? null : () => work(load),
            child: const Text('회차 연결 확인'),
          ),
        if (loaded && pending == null && parents.isNotEmpty)
          DropdownButtonFormField<String>(
            initialValue: parent ?? '',
            items: [
              const DropdownMenuItem(value: '', child: Text('새 첨삭 · 1 크레딧')),
              for (final p in parents)
                DropdownMenuItem(
                  value: p['run_id'] as String,
                  child: Text(
                    '무료 재첨삭 · ${(p['created_at'] as String).substring(0, 10)}',
                  ),
                ),
            ],
            onChanged: busy
                ? null
                : (v) => work(() async {
                    parent = v == '' ? null : v;
                    inputs.clear();
                    await load();
                  }),
          ),
        if (loaded && accepted == null)
          OutlinedButton(
            onPressed: busy || selected.isEmpty ? null : () => work(prepare),
            child: const Text('저장한 답안 입력 확인 · 0 크레딧'),
          ),
        for (final q in selected)
          if (inputs[q['key']] != null) ...[
            Text(q['label'] as String),
            if (inputs[q['key']]!['can_request_evaluation'] == true)
              const Text('첨삭 요청 준비 완료')
            else ...[
              for (final r
                  in inputs[q['key']]!['candidate_regions'] as List? ?? [])
                TextFormField(
                  key: ValueKey(r['region_id'] ?? r['id']),
                  initialValue:
                      '${r['normalized_math'] ?? r['raw_text'] ?? ''}',
                  maxLines: null,
                  decoration: const InputDecoration(labelText: '사진에서 읽은 내용'),
                  onChanged: (v) =>
                      corrections['${r['region_id'] ?? r['id']}'] = v,
                ),
              if (inputs[q['key']]!['input_state'] == 'CONFIRMATION_REQUIRED')
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => work(() => confirm(q['key'] as String)),
                  child: const Text('이 내용으로 확인'),
                ),
            ],
          ],
        if (pending != null &&
            accepted == null &&
            (pending!['submitted'] == true ||
                selected.isNotEmpty &&
                    selected.every(
                      (q) =>
                          inputs[q['key']]?['can_request_evaluation'] == true,
                    )))
          FilledButton(
            onPressed: busy ? null : () => work(submit),
            child: Text(
              pending!['submitted'] == true
                  ? '같은 회차 처리 확인'
                  : '논술 첨삭하기 · ${parent == null ? 1 : 0} 크레딧',
            ),
          ),
        if (accepted != null) ...[
          Text(
            accepted!['state'] == 'completed'
                ? '회차 첨삭이 완료됐어요. 나의 첨삭 기록에서 확인하세요.'
                : '제출한 회차의 처리 상태를 확인해 주세요.',
          ),
          for (final q in accepted!['questions'] as List)
            Text(
              '${questions.where((v) => v['dbQuestionId'] == q['question_id']).firstOrNull?['label'] ?? '문항'} · ${q['state'] == 'COMPLETED'
                  ? '완료'
                  : q['state'] == 'FAILED'
                  ? '재처리 필요'
                  : '진행 중'}',
            ),
          OutlinedButton(
            onPressed: busy ? null : () => work(dispatch),
            child: const Text('같은 회차 상태 확인'),
          ),
          if (mathSessionRetryable(accepted!))
            OutlinedButton(
              onPressed: busy ? null : () => work(retry),
              child: const Text('실패 문항만 재처리 · 0 크레딧'),
            ),
        ],
        if (pending != null &&
            (pending!['submitted'] != true ||
                accepted?['state'] == 'completed'))
          TextButton(
            onPressed: busy
                ? null
                : () => work(() async {
                    pending = null;
                    accepted = null;
                    inputs.clear();
                    corrections.clear();
                    await persist();
                    await load();
                  }),
            child: const Text('새 답안 준비'),
          ),
        if (notice != null) Text(notice!),
        if (busy) const Text('처리 중입니다…'),
      ],
    );
  }
}
