import 'math_mobile/math_recognition_panel.dart';
import 'math_mobile/math_formula_editor.dart';
import '../../core/supabase/supabase_providers.dart';

import 'dart:async';
import 'dart:convert';

import '../../shared/widgets/shell_widgets.dart';
import 'result_disclosure.dart';
import 'math_mobile/academic_purple.dart';
import 'math_mobile/math_coaching_page.dart';

import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../credits/credit_balance.dart';
import 'answer_image.dart';
import 'math_gateway.dart';
import 'source_draft.dart';
import 'source_catalog_page.dart' show essayWritingDraftKey;
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
    this.rewriteRun,
    this.onEdit,
    this.onSubmittedChanged,
    super.key,
  });
  final String owner;
  final Map<String, dynamic> exam;
  final Set<String> selected;
  final Map<String, String> leaves;
  final Map<String, dynamic>? rewriteRun;
  final VoidCallback? onEdit;
  final ValueChanged<bool>? onSubmittedChanged;
  @override
  ConsumerState<MathExamSession> createState() => _MathExamSessionState();
}

class _MathExamSessionState extends ConsumerState<MathExamSession>
    with WidgetsBindingObserver {
  Timer? pollTimer;
  int polls = 0, inputStage = 0;
  String activity = '저장한 답안을 확인하고 있어요';
  bool foreground = true;
  bool get recognizing => inputs.values.any(
    (input) => (input['candidate'] as Map?)?['state'] == 'PROCESSING',
  );
  bool get submitted => pending?['submitted'] == true;
  bool get completed => accepted?['state'] == 'completed';
  bool get inFlight =>
      accepted != null &&
      !completed &&
      (accepted!['questions'] as List).any(
        (q) => q['state'] == 'REQUESTED' || q['state'] == 'PROCESSING',
      );

  void updateActivity(String label, {int? stage}) {
    if (!current) return;
    setState(() {
      activity = label;
      if (stage != null) inputStage = stage;
    });
  }

  void notifyParent() => widget.onSubmittedChanged?.call(busy || submitted);

  void schedulePoll() {
    pollTimer?.cancel();
    if (!current ||
        busy ||
        !foreground ||
        !(inFlight || recognizing) ||
        notice != null) {
      return;
    }
    pollTimer = Timer(
      Duration(
        seconds: polls < 5
            ? 3
            : polls < 15
            ? 10
            : 30,
      ),
      () async {
        polls++;
        await work(
          submitted ? refresh : refreshInputs,
          label: submitted ? '첨삭 상태를 확인하고 있어요' : '수식 인식 상태를 확인하고 있어요',
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    if (foreground) {
      schedulePoll();
    } else {
      pollTimer?.cancel();
    }
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

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
    WidgetsBinding.instance.addObserver(this);
    parent = widget.rewriteRun?['id'] as String?;
    Future.microtask(() => work(load));
  }

  Future<void> work(
    Future<void> Function() action, {
    String label = '저장한 답안을 확인하고 있어요',
  }) async {
    if (busy) return;
    pollTimer?.cancel();
    setState(() {
      activity = label;
      busy = true;
      notice = null;
    });
    notifyParent();
    try {
      await ref.read(authStateProvider.future);
      gateway.checkOwner();
      await action();
    } catch (error) {
      if (current) {
        setState(
          () => notice =
              mathExtractionNotice(error) ??
              '연결을 확인하지 못했어요. 저장한 답안은 유지됩니다. 다시 확인해 주세요.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        notifyParent();
        schedulePoll();
      }
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
              r['state'] == 'completed' &&
              r['continuous_cycles_supported'] == true,
        )
        .toList();
    final continued = (history['runs'] as List)
        .map((r) => (r as Map)['previous_run_id'])
        .whereType<String>()
        .toSet();
    parents.removeWhere((r) => continued.contains(r['run_id']));
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
    updateActivity('저장한 답안을 불러오고 있어요', stage: 0);
    final rows = <Map<String, dynamic>>[];
    for (final q in selected) {
      final draft = SourceDraftGateway(
        widget.owner,
        essayWritingDraftKey(q['key'] as String, widget.rewriteRun),
      );
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
        updateActivity('${q['label']} · 사진을 업로드하고 있어요', stage: 0);
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
          sourceImages[artifact['artifact_id'] as String] = images[i];
          await gateway.uploadEvidence(
            artifact['artifact_id'] as String,
            images[i],
          );
        }
        updateActivity('${q['label']} · 수식과 문장을 인식하고 있어요', stage: 1);
        try {
          await gateway.extract(id as String);
        } catch (_) {
          // A lost/late response must read this attempt, not create a new one.
        }
        input = await gateway.call('math_input', 'read_input', {
          'attempt_id': id,
        });
      }
      inputs[key] = input;
      if ((input['candidate'] as Map?)?['state'] == 'PROCESSING') continue;
      if (images.isNotEmpty) requireMathExtractionResult(input);
      updateActivity('${q['label']} · 원본 대조를 준비하고 있어요', stage: 1);
      await loadInputSources(input);
      inputs[key] = input;
    }
    if (current) {
      setState(() {
        inputStage = recognizing ? 1 : 2;
      });
    }
  }

  Future<void> refreshInputs() async {
    for (final entry in inputs.entries.toList()) {
      if ((entry.value['candidate'] as Map?)?['state'] != 'PROCESSING') {
        continue;
      }
      final input = await gateway.call('math_input', 'read_input', {
        'attempt_id': (pending!['attempts'] as Map)[entry.key],
      });
      if (!current) return;
      inputs[entry.key] = input;
      if ((input['candidate'] as Map?)?['state'] == 'PROCESSING') continue;
      requireMathExtractionResult(input);
      await loadInputSources(input);
    }
    if (current) setState(() => inputStage = recognizing ? 1 : 2);
  }

  Future<void> loadInputSources(Map<String, dynamic> input) async {
    // Reopening a prepared attempt must retain the original comparison UI.
    // Reuse the authenticated artifact gateway; never invent a replacement.
    for (final artifact
        in (input['candidate_regions'] as List? ?? [])
            .map((r) => (r as Map)['artifact_id'])
            .whereType<String>()
            .toSet()
            .take(6)) {
      if (!sourceImages.containsKey(artifact)) {
        sourceImages[artifact] = await gateway.readEvidence(artifact);
      }
    }
  }

  final sourceImages = <String, Uint8List>{};

  Future<void> confirm(String key) async {
    final input = inputs[key]!;
    for (final r in input['candidate_regions'] as List) {
      final text =
          corrections['${r['region_id'] ?? r['id']}'] ??
          '${r['normalized_math'] ?? r['raw_text'] ?? ''}';
      if (unresolvedMath(text)) throw StateError('MATH_RECOGNITION_UNRESOLVED');
    }
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
    await refresh();
    final run = accepted!;
    for (final q in run['questions'] as List) {
      if (q['state'] == 'REQUESTED') {
        updateActivity(
          '${questionLabel(q as Map<String, dynamic>)} · 첨삭을 요청하고 있어요',
        );
        try {
          await gateway.evaluate(q['evaluation_id'] as String);
        } catch (_) {
          gateway.checkOwner();
        }
      }
    }
    await refresh();
  }

  String questionLabel(Map<String, dynamic> q) =>
      questions
              .where((v) => v['dbQuestionId'] == q['question_id'])
              .firstOrNull?['label']
          as String? ??
      '문항';

  // Refresh is read-only. Polling never resubmits or charges another round.
  Future<void> refresh() async {
    final run = parseMathSession(
      await gateway.session('math_session_read', {'p_run': pending!['runId']}),
    );
    if (!current) return;
    setState(() => accepted = run);
    if (completed || mathSessionRetryable(run)) {
      ref.invalidate(creditBalanceProvider);
      ref.invalidate(sharedEssayHistoryProvider(widget.owner));
    }
  }

  Future<void> editAnswers() async {
    // Only an unsubmitted preparation may be replaced. Server evidence stays.
    if (submitted) return;
    pending = null;
    inputs.clear();
    corrections.clear();
    await persist();
    if (current) widget.onEdit?.call();
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
      final quote = parent == null
          ? <String, dynamic>{'credits_required': 1}
          : await gateway.session('math_session_quote', {'p_previous': parent});
      if (quote is! Map || ![0, 1].contains(quote['credits_required'])) {
        throw const FormatException('CHARGE_QUOTE_REQUIRED');
      }
      final credits = quote['credits_required'] as int;
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
            '${missing.isEmpty ? '' : '$missing 문항은 포함되지 않아요. 나중에 제출하면 별도 이용권이 필요해요.\n\n'}${credits == 0 ? '이번 재첨삭은 무료예요.' : '이용권 1개로 선택한 문항을 첨삭해요.'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('계속 작성하기'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(credits == 0 ? '무료 재첨삭하기' : '이용권 1개 사용하고 첨삭하기'),
            ),
          ],
        ),
      );
      if (yes != true || !current) return;
      pending!['expectedCredits'] = credits;
      pending!['submitted'] = true;
      notifyParent();
      await persist();
    }
    updateActivity('첨삭 요청을 접수하고 있어요');
    if (pending!['runId'] == null) {
      final id = await gateway.session('math_session_continue', {
        'p_exam': widget.exam['dbExamId'],
        'p_key': pending!['key'],
        'p_attempts': selected
            .map((q) => (pending!['attempts'] as Map)[q['key']])
            .toList(),
        'p_previous': parent,
        'p_expected_credits': pending!['expectedCredits'],
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
    final ready =
        selected.isNotEmpty &&
        selected.every(
          (q) => inputs[q['key']]?['can_request_evaluation'] == true,
        );
    final failed = accepted != null && mathSessionRetryable(accepted!);
    final processing = (accepted?['questions'] as List? ?? []).any(
      (q) => q['state'] == 'PROCESSING',
    );
    final children = <Widget>[
      if (submitted || busy || inputs.isNotEmpty) ...[
        Text(
          completed
              ? '첨삭이 완료됐어요'
              : notice != null
              ? '처리 상태를 다시 확인해 주세요'
              : failed
              ? '일부 문항을 다시 처리해야 해요'
              : busy
              ? activity
              : recognizing
              ? '수식과 문장을 인식하고 있어요'
              : submitted
              ? '첨삭 결과를 기다리고 있어요'
              : ready
              ? '답안 확인을 마쳤어요'
              : '원본과 인식 내용을 확인해 주세요',
          style: const TextStyle(
            fontSize: 20,
            height: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        StepProgressBar(
          steps: submitted
              ? const ['제출 완료', '첨삭 중', '결과 준비']
              : const ['답안 준비', '입력 인식', '내용 확인'],
          activeIndex: submitted
              ? (completed
                    ? 2
                    : processing ||
                          (accepted?['questions'] as List? ?? []).any(
                            (q) => q['state'] == 'COMPLETED',
                          )
                    ? 1
                    : 0)
              : inputStage,
          done: completed || (!submitted && ready),
          showActivity: notice == null && (busy || processing || recognizing),
          activeColor: AcademicPurple.primary,
          trackColor: AcademicPurple.emphasis,
        ),
        if (submitted && !completed && !failed && notice == null)
          ProcessingGuidance(active: processing),
      ],
      if (!loaded && !busy)
        OutlinedButton(
          onPressed: () => work(load),
          child: const Text('저장한 답안 다시 확인'),
        ),
      if (loaded && pending == null && parents.isNotEmpty)
        DropdownButtonFormField<String>(
          isExpanded: true,
          initialValue: parent ?? '',
          items: [
            const DropdownMenuItem(value: '', child: Text('새 첨삭 · 이용권 1개')),
            for (final p in parents)
              DropdownMenuItem(
                value: p['run_id'] as String,
                child: Text(
                  '${(p['next_quote'] as Map?)?['credits_required'] == 0 ? '무료 재첨삭' : '다음 첨삭 · 이용권 1개'} · ${(p['created_at'] as String).substring(0, 10)}',
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
      if (loaded && !submitted && inputs.isEmpty && !busy)
        FilledButton(
          onPressed: selected.isEmpty ? null : () => work(prepare),
          child: const Text('저장한 답안 확인'),
        ),
      if (!submitted && !busy && !recognizing && widget.onEdit != null)
        OutlinedButton(
          onPressed: () => work(editAnswers),
          child: const Text('답안 수정'),
        ),
      if (!submitted)
        for (final q in selected)
          if (inputs[q['key']] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  q['label'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (inputs[q['key']]!['can_request_evaluation'] == true)
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AcademicPurple.success,
                      ),
                      SizedBox(width: 8),
                      Text('답안 확인 완료'),
                    ],
                  )
                else if ((inputs[q['key']]!['candidate'] as Map?)?['state'] ==
                        'COMPLETED' &&
                    inputs[q['key']]!['input_state'] == 'CONFIRMATION_REQUIRED')
                  MathRecognitionPanel(
                    key: ValueKey(
                      '${q['key']}/${inputs[q['key']]!['candidate']}',
                    ),
                    regions:
                        (inputs[q['key']]!['candidate_regions'] as List? ?? [])
                            .map((r) => Map<String, dynamic>.from(r as Map))
                            .toList(),
                    sources: sourceImages,
                    busy: busy,
                    onConfirm: (values) async {
                      corrections.addAll(values);
                      await work(
                        () => confirm(q['key'] as String),
                        label: '${q['label']} · 확인한 답안을 저장하고 있어요',
                      );
                    },
                  ),
              ],
            ),
      if (!busy && pending != null && accepted == null && (submitted || ready))
        FilledButton(
          onPressed: () => work(submit, label: '첨삭 요청을 확인하고 있어요'),
          child: Text(submitted ? '접수한 첨삭 계속하기' : '첨삭 요청하기'),
        ),
      if (accepted != null) ...[
        for (final q in accepted!['questions'] as List)
          Row(
            children: [
              Expanded(child: Text(questionLabel(q as Map<String, dynamic>))),
              Text(
                q['state'] == 'COMPLETED'
                    ? '완료'
                    : q['state'] == 'FAILED'
                    ? '재처리 필요'
                    : q['state'] == 'PROCESSING'
                    ? '첨삭 중'
                    : '접수 완료',
              ),
            ],
          ),
        if (completed)
          for (final q in accepted!['questions'] as List)
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MathCoachingPage(
                    evaluationId: q['evaluation_id'] as String,
                    sources: sourceImages,
                  ),
                ),
              ),
              child: Text(
                '${questionLabel(q as Map<String, dynamic>)} 첨삭 결과 보기',
              ),
            ),
        if (!completed && !busy) ...[
          OutlinedButton(
            onPressed: () => work(refresh, label: '첨삭 상태를 확인하고 있어요'),
            child: const Text('첨삭 상태 새로고침'),
          ),
          if ((accepted!['questions'] as List).any(
            (q) => q['state'] == 'REQUESTED',
          ))
            OutlinedButton(
              onPressed: () => work(dispatch, label: '접수한 첨삭을 이어가고 있어요'),
              child: const Text('접수한 첨삭 계속하기'),
            ),
          if (failed)
            FilledButton(
              onPressed: () => work(retry, label: '실패한 문항을 다시 처리하고 있어요'),
              child: const Text('실패한 문항 다시 처리'),
            ),
        ],
      ],
      if (notice != null) Semantics(liveRegion: true, child: Text(notice!)),
      if (notice != null && !submitted && inputs.isNotEmpty && !busy)
        OutlinedButton(
          onPressed: () => work(prepare),
          child: const Text('저장한 답안 다시 확인'),
        ),
    ];
    return MathMobileTheme(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            children[i],
          ],
        ],
      ),
    );
  }
}
