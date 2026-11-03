import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../math_gateway.dart';
import '../source_catalog_page.dart';
import '../shared_history.dart';
import 'academic_purple.dart';
import 'coaching_contract.dart';
import 'math_coaching_screen.dart';

class MathCoachingPage extends ConsumerStatefulWidget {
  const MathCoachingPage({
    required this.evaluationId,
    this.onRewrite,
    this.runId,
    this.questionId,
    this.sources = const {},
    super.key,
  });
  final String evaluationId;
  final String? runId, questionId;
  final Map<String, Uint8List> sources;
  final Future<void> Function(bool paid)? onRewrite;
  @override
  ConsumerState<MathCoachingPage> createState() => _MathCoachingPageState();
}

class _MathCoachingPageState extends ConsumerState<MathCoachingPage> {
  String? owner;
  Future<CoachingSnapshot>? future;
  final keys = <String, String>{};
  final sources = <String, Uint8List>{};
  String? initialOwner;

  Future<CoachingSnapshot> load() async {
    final identity = owner;
    final snapshot = CoachingSnapshot(
      await request('read', {'evaluation_id': widget.evaluationId}),
    );
    final gateway = ref.read(mathGatewayProvider(identity!));
    final loaded = <String, Uint8List>{
      if (initialOwner == identity) ...widget.sources,
    };
    final artifacts = snapshot.tasks
        .expand((task) => objects(task['source_regions']))
        .map((region) => region['artifact_id'])
        .whereType<String>()
        .toSet();
    for (final id in artifacts.take(6)) {
      if (loaded.containsKey(id)) continue;
      try {
        if (gateway != null) loaded[id] = await gateway.readEvidence(id);
      } catch (_) {
        // A missing original must not hide feedback or invent a replacement image.
      }
      if (!mounted || ref.read(authStateProvider).value?.userId != identity) {
        throw StateError('ACCOUNT_CHANGED');
      }
    }
    if (!mounted || ref.read(authStateProvider).value?.userId != identity) {
      throw StateError('ACCOUNT_CHANGED');
    }
    sources
      ..clear()
      ..addAll(loaded);
    return snapshot;
  }

  Future<void> openSessionWriter(CoachingSnapshot snapshot, bool paid) async {
    if (owner == null) throw StateError('ACCOUNT_CHANGED');
    final gateway = ref.read(mathGatewayProvider(owner!));
    if (gateway == null) throw StateError('UNAVAILABLE');
    if (widget.runId != null) {
      final rows = await SharedEssayHistory(
        gateway.client,
        owner!,
      ).examRuns(widget.runId);
      if (!mounted ||
          rows.length != 1 ||
          ref.read(authStateProvider).value?.userId != owner) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SourceCatalogPage(
            rewriteRun: {...rows.single, if (paid) '_additional': true},
          ),
        ),
      );
      return;
    }
    final sessionId = snapshot.policy['session_run_id'];
    if (sessionId is! String || owner == null) {
      if (widget.onRewrite != null) return widget.onRewrite!(paid);
      throw StateError('REWRITE_SOURCE_UNAVAILABLE');
    }
    final run = await gateway.session('math_session_read', {
      'p_run': sessionId,
    });
    if (!mounted || ref.read(authStateProvider).value?.userId != owner) return;
    if (run is! Map || run['state'] != 'completed') {
      throw StateError('ROUND_NOT_COMPLETED');
    }
    final answers = <Map<String, dynamic>>[];
    for (final q in run['questions'] as List) {
      final input = await gateway.call('math_input', 'read_input', {
        'attempt_id': q['attempt_id'],
      });
      final attempt = object(input['attempt']);
      answers.add({
        'questionId': q['question_id'],
        'body':
            attempt['typed_answer'] ??
            objects(input['confirmed_regions'])
                .map((r) => r['normalized_math'] ?? r['raw_text'] ?? '')
                .join('\n'),
      });
    }
    if (!mounted || ref.read(authStateProvider).value?.userId != owner) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SourceCatalogPage(
          rewriteRun: {
            'id': sessionId,
            'math_session_run_id': sessionId,
            'exam_id': run['exam_id'],
            'question_ids': (run['questions'] as List)
                .map((q) => (q as Map)['question_id'])
                .toList(),
            'answers': answers,
            if (paid) '_additional': true,
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> request(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final identity = ref.read(authStateProvider).value?.userId;
    if (identity == null || identity != owner) {
      throw StateError('ACCOUNT_CHANGED');
    }
    final gateway = ref.read(mathGatewayProvider(identity));
    if (gateway == null) throw StateError('UNAVAILABLE');
    if (widget.runId != null) {
      payload = Map.of(payload)..remove('evaluation_id');
    }
    final result = await gateway.call(
      widget.runId == null ? 'math_coaching' : 'essay_math_coaching',
      action,
      {
        ...payload,
        if (widget.runId != null) ...{
          'run_id': widget.runId,
          'question_id': widget.questionId,
        },
        if (action == 'reveal' || action == 'hint')
          'client_submission_id': keys.putIfAbsent(
            '$action/${payload['task_id']}/${payload['level']}',
            mathRequestId,
          ),
      },
    );
    if (!mounted || ref.read(authStateProvider).value?.userId != identity) {
      throw StateError('ACCOUNT_CHANGED');
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value?.userId;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('로그인 후 확인할 수 있습니다.')));
    }
    // Keep the auto-disposed gateway alive while async History reads are pending.
    ref.watch(mathGatewayProvider(user));
    if (owner != user) {
      initialOwner ??= user;
      owner = user;
      sources.clear();
      keys.clear();
      future = load();
    }
    return FutureBuilder<CoachingSnapshot>(
      key: ValueKey(user),
      future: future,
      builder: (context, state) {
        if (state.hasData) {
          return MathCoachingScreen(
            key: ValueKey('$owner/${widget.evaluationId}'),
            snapshot: state.data!,
            sources: sources,
            request: request,
            onRewrite: (paid) => openSessionWriter(state.data!, paid),
          );
        }
        return MathMobileTheme(
          child: Scaffold(
            appBar: AppBar(title: const Text('수리논술 LAB')),
            body: Center(
              child: state.hasError
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            '안전한 첨삭 결과를 확인하지 못했습니다. 서버 공개 계약이 준비되면 다시 확인할 수 있습니다.',
                          ),
                          TextButton(
                            onPressed: () => setState(() => future = load()),
                            child: const Text('다시 확인'),
                          ),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }
}
