import 'math_mobile/math_recognition_panel.dart';
import 'math_mobile/academic_purple.dart';
import 'math_mobile/math_formula_editor.dart';
import 'math_mobile/math_image_tools.dart';
import 'math_mobile/math_coaching_page.dart';
import 'math_text.dart';

import 'dart:typed_data';

import 'answer_image.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_providers.dart';
import '../credits/credit_balance.dart';
import 'math_gateway.dart';
import 'shared_history.dart';
import 'shared_history_page.dart';
import 'evaluation_report.dart';

class MathWorkspacePage extends ConsumerWidget {
  const MathWorkspacePage({this.evaluationId, this.requestedLeafId, super.key});
  final String? evaluationId;
  final String? requestedLeafId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final owner = auth.isLoading || auth.hasError ? null : auth.value?.userId;
    return MathMobileTheme(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('수리논술'),
          actions: [
            IconButton(
              tooltip: '나의 첨삭 기록',
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SharedEssayHistoryPage(),
                ),
              ),
            ),
          ],
        ),
        body: owner == null
            ? Center(
                child: TextButton(
                  onPressed: () => context.push('/auth'),
                  child: const Text('로그인 후 내 답안을 작성하세요.'),
                ),
              )
            : _MathWorkspace(
                key: ValueKey('$owner/$evaluationId/$requestedLeafId'),
                owner: owner,
                evaluationId: evaluationId,
                requestedLeafId: requestedLeafId,
              ),
      ),
    );
  }
}

class _MathWorkspace extends ConsumerStatefulWidget {
  const _MathWorkspace({
    super.key,
    required this.owner,
    this.evaluationId,
    this.requestedLeafId,
  });
  final String owner;
  final String? evaluationId;
  final String? requestedLeafId;
  @override
  ConsumerState<_MathWorkspace> createState() => _MathWorkspaceState();
}

class _MathWorkspaceState extends ConsumerState<_MathWorkspace> {
  final drafts = <String, ({String text, List<Uint8List> photos})>{};
  List<Uint8List> photos = [];
  final artifacts = <int, String>{};
  final uploaded = <int>{};
  Map<String, dynamic>? inputState;
  final corrections = <String, String>{};
  final answer = TextEditingController();
  String? leaf, attempt, evaluation, notice;
  String submissionKey = mathRequestId(), evaluationKey = mathRequestId();
  bool busy = false, frozen = false;
  Map<String, dynamic>? state, prior;
  ({EvaluationReport report, EvaluationReport? before})? report;
  MathGateway get gateway => ref.read(mathGatewayProvider(widget.owner))!;
  bool get current =>
      mounted && ref.read(authStateProvider).value?.userId == widget.owner;
  @override
  void initState() {
    super.initState();
    evaluation = widget.evaluationId;
    if (evaluation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) run(refresh);
      });
    }
  }

  @override
  void dispose() {
    answer.dispose();
    super.dispose();
  }

  Future<void> run(Future<void> Function() work) async {
    if (busy) {
      return;
    }
    setState(() {
      busy = true;
      notice = null;
    });
    try {
      await work();
    } catch (error) {
      if (current) {
        setState(
          () => notice = error is PostgrestException && error.code == 'PT402'
              ? '사용 가능한 크레딧 또는 포함 재첨삭 조건을 확인해 주세요.'
              : mathExtractionNotice(error) ?? '처리 결과를 확인하지 못했어요. 같은 요청으로 다시 확인해 주세요. 새 답안의 첨삭을 중복 요청하지 마세요.',
        );
      }
    } finally {
      if (current) {
        ref.invalidate(creditBalanceProvider);
        ref.invalidate(sharedEssayHistoryProvider(widget.owner));
        setState(() => busy = false);
      }
    }
  }

  final exposureKeys = <String, String>{};
  String exposureKey(String key) =>
      exposureKeys.putIfAbsent(key, mathRequestId);

  Future<void> refresh() async {
    final id = evaluation;
    if (id == null) return;
    final next = await gateway.call('math_learning', 'read_learning_state', {
      'evaluation_id': id,
    });
    if (!current) return;
    setState(() {
      state = next;
      leaf = next['leaf_id'] as String? ?? leaf;
    });
    if (next['valid_evaluation_available'] == true) {
      final data = (
        report: mathEvaluationReport({'evaluation_id': id}),
        before: null as EvaluationReport?,
      );
      if (current) setState(() => report = data);
    } else if (current) {
      setState(
        () => notice = next['evaluation_state'] == 'FAILED'
            ? '첨삭이 완료되지 않았어요. 크레딧 잔액과 기록을 확인해 주세요.'
            : '첨삭 처리 중이거나 결과 확인이 필요해요. 잠시 후 다시 확인해 주세요.',
      );
    }
  }

  Future<void> submit() async {
    if (!await gateway.available()) throw StateError('UNAVAILABLE');
    if (!current) return;
    if (evaluation != null) {
      await resumeEvaluation();
      return;
    }
    if (leaf == null || (answer.text.trim().isEmpty && photos.isEmpty)) return;
    if (!await gateway.available()) throw StateError('CLOSED');
    if (!current) return;
    // Freeze before the first request: a lost response must retry identical payload/key.
    setState(() => frozen = true);
    if (attempt == null) {
      final data = await gateway.call(
        prior == null ? 'math_input' : 'math_learning',
        prior == null ? 'create_attempt' : 'create_resolve_attempt',
        {
          'client_submission_id': submissionKey,
          'leaf_id': leaf,
          'kind': prior == null
              ? 'INITIAL'
              : prior!['response_format'] == 'SHORT_ANSWER'
              ? 'SHORT_ANSWER_RESOLVE'
              : 'FULL_RESOLVE',
          'input_kind': photos.isEmpty
              ? 'TYPED'
              : answer.text.trim().isEmpty
              ? 'EVIDENCE'
              : 'MIXED',
          if (answer.text.trim().isNotEmpty) 'typed_answer': answer.text,
          if (prior != null) ...{
            'predecessor_id': prior!['attempt_id'],
            'prior_evaluation_id': prior!['evaluation_id'],
          },
        },
      );
      if (!current) return;
      setState(() => attempt = data['attempt_id'] as String);
    }
    for (var i = 0; i < photos.length; i++) {
      if (uploaded.contains(i)) continue;
      if (!artifacts.containsKey(i)) {
        final data = await gateway.call('math_input', 'register_evidence', {
          'attempt_id': attempt,
          'metadata': {
            'position': i + 1,
            'media_type': answerImageType(photos[i]),
            'byte_size': photos[i].length,
          },
        });
        if (!current) return;
        artifacts[i] = data['artifact_id'] as String;
      }
      await gateway.uploadEvidence(artifacts[i]!, photos[i]);
      if (!current) return;
      uploaded.add(i);
    }
    var input = await gateway.call('math_input', 'read_input', {
      'attempt_id': attempt,
    });
    if (!current) return;
    if (photos.isNotEmpty &&
        (input['candidate'] == null ||
            (input['candidate'] is Map && (input['candidate'] as Map)['state'] == 'FAILED')) &&
        input['can_request_evaluation'] != true) {
      try {
        await gateway.extract(attempt!);
      } catch (_) {
        // Resolve ambiguous transport failure using the stored attempt.
      } finally {
        if (current) {
          input = await gateway.call('math_input', 'read_input', {
            'attempt_id': attempt,
          });
          if (current) setState(() => inputState = input);
        }
      }
      requireMathExtractionResult(input);
      if (current) setState(() => notice = '사진에서 읽은 답안을 확인해 주세요.');
      return;
    }
    if (input['can_request_evaluation'] != true) {
      if (photos.isNotEmpty) requireMathExtractionResult(input);
      setState(() {
        inputState = input;
        notice = '사진에서 읽은 답안을 확인해 주세요.';
      });
      return;
    }

    if (evaluation == null) {
      final data = await gateway.call(
        prior == null ? 'math_input' : 'math_learning',
        prior == null ? 'request_evaluation' : 'request_reevaluation',
        {'attempt_id': attempt, 'client_submission_id': evaluationKey},
      );
      if (!current) return;
      setState(() => evaluation = data['evaluation_id'] as String);
    }
    try {
      await gateway.evaluate(evaluation!);
    } finally {
      if (current) await refresh();
    }
  }

  Future<void> confirmInput() async {
    final candidate = inputState?['candidate'] as Map?;
    final regions = (inputState?['candidate_regions'] as List? ?? [])
        .cast<Map<String, dynamic>>();
    if (candidate == null || regions.isEmpty) throw StateError('NO_EXTRACTION');

    if (regions.any(
      (r) => unresolvedMath(
        corrections['${r['region_id'] ?? r['id']}'] ??
            ((r['normalized_math'] as String? ?? '').isNotEmpty
                ? r['normalized_math'] as String
                : r['raw_text'] as String? ?? ''),
      ),
    )) {
      throw StateError('MATH_RECOGNITION_UNRESOLVED');
    }
    await gateway.call('math_input', 'confirm_extraction', {
      'attempt_id': attempt,
      'run_id': candidate['run_id'] ?? candidate['id'],
      'regions': [
        for (final r in regions)
          {
            'region_id': r['region_id'] ?? r['id'],
            'raw_text':
                corrections['${r['region_id'] ?? r['id']}'] ??
                r['raw_text'] ??
                '',
            'normalized_math':
                corrections['${r['region_id'] ?? r['id']}'] ??
                r['normalized_math'] ??
                r['raw_text'] ??
                '',
          },
      ],
    });
    if (!current) return;
    final next = await gateway.call('math_input', 'read_input', {
      'attempt_id': attempt,
    });
    if (current) {
      setState(() {
        inputState = next;
        notice = '판독 내용을 저장했습니다. 첨삭 진행을 눌러 주세요.';
      });
    }
  }

  Future<void> resumeEvaluation() async {
    await refresh();
    if (current && state?['evaluation_state'] == 'REQUESTED') {
      try {
        await gateway.evaluate(evaluation!);
      } finally {
        if (current) await refresh();
      }
    }
  }

  void rewrite() {
    final old = state;
    if (old?['valid_evaluation_available'] != true ||
        (old?['included_reevaluation'] as Map?)?['eligible'] != true) {
      return;
    }
    setState(() {
      photos = [];
      artifacts.clear();
      uploaded.clear();
      inputState = null;
      corrections.clear();
      prior = old;
      state = null;
      attempt = null;
      evaluation = null;
      report = null;
      submissionKey = mathRequestId();
      evaluationKey = mathRequestId();
      frozen = false;
      answer.clear();
      notice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(mathCatalogProvider(widget.owner));
    final canEvaluate =
        ref.watch(mathEvaluationAvailableProvider(widget.owner)).value == true;
    return catalog.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(mathCatalogProvider(widget.owner)),
          child: const Text('문항 다시 불러오기'),
        ),
      ),
      data: (rows) {
        final selected =
            leaf ??
            widget.requestedLeafId ??
            (rows.isEmpty ? null : rows.first['leaf_id'] as String);
        final match = rows.where((r) => r['leaf_id'] == selected);
        final question = match.isEmpty ? null : match.first;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (inputState == null) const MathInputProgress(stage: 0),
            const SizedBox(height: 20),
            const Text(
              '답안 제출',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('문제 풀이를 사진으로 촬영하거나 이미지를 선택해 주세요.'),
            const CreditBalanceCard(),
            const Text('1 크레딧으로 최초 첨삭 1회와 14일 이내 같은 답안의 재첨삭 1회를 이용할 수 있어요. '),
            if (!canEvaluate) const Text('문항을 확인할 수 있어요. 현재 첨삭은 이용할 수 없습니다.'),
            if (notice != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(notice!, semanticsLabel: notice),
              ),
            if (rows.isEmpty) const Text('현재 이용 가능한 첨삭 문항이 없습니다.'),
            if (widget.requestedLeafId != null && question == null)
              const Text('선택한 문항은 아직 수리논술 첨삭이 준비되지 않았습니다.'),
            if (rows.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: question == null ? null : selected,
                key: ValueKey(selected),
                isExpanded: true,
                decoration: const InputDecoration(labelText: '문제 선택'),
                items: [
                  for (final q in rows)
                    DropdownMenuItem(
                      value: q['leaf_id'] as String,
                      child: Text(q['label'] as String),
                    ),
                ],
                onChanged:
                    busy ||
                        frozen ||
                        prior != null ||
                        evaluation != null ||
                        widget.requestedLeafId != null
                    ? null
                    : (v) => setState(() {
                        if (selected != null) {
                          drafts[selected] = (
                            text: answer.text,
                            photos: List.of(photos),
                          );
                        }
                        leaf = v;
                        answer.text = drafts[v]?.text ?? '';
                        photos = List.of(drafts[v]?.photos ?? []);
                      }),
              ),
              if (question != null) ...[
                MathText(question['problem_statement'] as String? ?? ''),
                MathText(question['statement'] as String? ?? ''),
              ],
              if (report == null &&
                  (widget.evaluationId == null || prior != null)) ...[
                MathImageInput(
                  values: photos,
                  enabled: !busy && !frozen,
                  onChanged: (value) async {
                    if (current && !busy && !frozen && value.length <= 6) {
                      setState(() => photos = List.of(value));
                    }
                  },
                ),
                TextField(
                  controller: answer,
                  enabled: !busy && !frozen,
                  minLines: 6,
                  maxLines: 12,
                  maxLength: 30000,
                  decoration: InputDecoration(labelText: '추가 설명 또는 텍스트 답안'),
                ),
                if (inputState != null &&
                    inputState!['can_request_evaluation'] != true)
                  MathRecognitionPanel(
                    key: ValueKey(inputState!['candidate'].toString()),
                    regions: (inputState!['candidate_regions'] as List? ?? [])
                        .cast<Map<String, dynamic>>(),
                    sources: {
                      for (final entry in artifacts.entries)
                        if (entry.key < photos.length)
                          entry.value: photos[entry.key],
                    },
                    busy: busy,
                    onConfirm: (values) async {
                      corrections.addAll(values);
                      await run(confirmInput);
                    },
                  ),
                FilledButton(
                  onPressed: busy || !canEvaluate || question == null
                      ? null
                      : () {
                          leaf = selected;
                          run(submit);
                        },
                  child: Text(
                    busy
                        ? '첨삭을 확인하고 있어요…'
                        : frozen
                        ? (inputState?['can_request_evaluation'] == true
                              ? '첨삭 진행'
                              : '같은 요청 다시 확인')
                        : prior == null
                        ? '첨삭 진행'
                        : '재첨삭',
                  ),
                ),
              ],
            ],
            if (evaluation != null)
              OutlinedButton(
                onPressed: busy ? null : () => run(refresh),
                child: const Text('결과·크레딧 다시 확인'),
              ),
            if (evaluation != null && state?['evaluation_state'] == 'REQUESTED')
              OutlinedButton(
                onPressed: busy || !canEvaluate || question == null
                    ? null
                    : () => run(resumeEvaluation),
                child: const Text('같은 첨삭 처리 다시 요청'),
              ),
            if (report != null) ...[
              FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MathCoachingPage(
                      evaluationId: evaluation!,
                      sources: {
                        for (final entry in artifacts.entries)
                          if (entry.key < photos.length)
                            entry.value: photos[entry.key],
                      },
                      onRewrite: (paid) async {
                        if (paid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '새 이용권 첨삭은 시험 선택에서 이용 조건을 확인해 주세요.',
                              ),
                            ),
                          );
                          return;
                        }
                        rewrite();
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
                child: const Text('수리논술 첨삭 결과 보기'),
              ),
            ],
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SharedEssayHistoryPage(),
                ),
              ),
              child: const Text('나의 첨삭 기록'),
            ),
          ],
        );
      },
    );
  }
}
