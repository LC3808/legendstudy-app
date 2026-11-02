import 'math_answer_disclosure.dart';
import 'package:flutter/material.dart';

import 'math_text.dart';

/// Reuses math_learning reveal contracts. Bodies only arrive after explicit requests.
class MathLearningPanel extends StatefulWidget {
  const MathLearningPanel({
    required this.state,
    required this.revealHint,
    required this.revealSolution,
    required this.onRewrite,
    super.key,
  });
  final Map<String, dynamic> state;
  final Future<String> Function(Map<String, dynamic>) revealHint;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)
  revealSolution;
  final VoidCallback onRewrite;
  @override
  State<MathLearningPanel> createState() => _MathLearningPanelState();
}

class _MathLearningPanelState extends State<MathLearningPanel> {
  final hints = <int, String>{};
  Map<String, dynamic>? solution;
  bool busy = false, confirm = false;
  String? error;
  Future<void> run(Future<void> Function() action) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
    } catch (_) {
      if (mounted) setState(() => error = '안내를 불러오지 못했습니다. 다시 확인해 주세요.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cores = (widget.state['core'] as List? ?? [])
        .cast<Map<dynamic, dynamic>>();
    final available = (widget.state['hints'] as List? ?? [])
        .cast<Map<dynamic, dynamic>>();
    final solutions = (widget.state['solutions'] as List? ?? [])
        .cast<Map<dynamic, dynamic>>();
    final core = cores.isEmpty ? null : cores.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('풀이 단계별 학습'),
        if (core != null) const Text('1단계 · 문제의 조건과 풀이 단계를 대조해 주세요.'),
        if (error != null) Text(error!),
        for (final level in [1, 2])
          if (level == 1 || hints.containsKey(1)) ...[
            if (hints.containsKey(level))
              Text(level == 1 ? '사용한 정의와 정리의 적용 조건을 확인해 보세요.' : '조건을 빠짐없이 적용하고 계산을 다시 검산한 뒤 직접 수정해 보세요.')
            else
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => run(() async {
                        final eligible = available.where(
                          (h) =>
                              h['core_id'] == core?['core_id'] &&
                              h['level'] == level &&
                              h['can_reveal'] == true,
                        );
                        if (eligible.isEmpty) {
                          throw StateError('HINT_UNAVAILABLE');
                        }
                        final body = await widget.revealHint(
                          Map<String, dynamic>.from(eligible.first),
                        );
                        if (mounted) setState(() => hints[level] = body);
                      }),
                child: Text(level == 1 ? '2단계 · 개념 힌트' : '3단계 · 해결 방향'),
              ),
          ],
        if (hints.containsKey(2) &&
            solution == null &&
            solutions.any(
              (s) => s['reveal_state'] == 'AVAILABLE_ON_EXPLICIT_REQUEST',
            )) ...[
          OutlinedButton(
            onPressed: busy ? null : () => setState(() => confirm = true),
            child: const Text('수정 풀이 비교 준비'),
          ),
          if (confirm) ...[
            const Text('먼저 직접 수정해 보세요. 참고 풀이 공개는 학습 이력에 기록됩니다.'),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () => run(() async {
                      final target = solutions.firstWhere(
                        (s) =>
                            s['reveal_state'] ==
                            'AVAILABLE_ON_EXPLICIT_REQUEST',
                      );
                      final value = await widget.revealSolution(
                        Map<String, dynamic>.from(target),
                      );
                      if (mounted) setState(() => solution = value);
                    }),
              child: const Text('참고 풀이 확인'),
            ),
          ],
        ],
        MathAnswerDisclosure(key: ValueKey(widget.state['evaluation_id']), child: Column(children: [if(core != null) MathText('${core['title'] ?? ''}\n${core['why'] ?? ''}'), for(final body in hints.values) MathText(body)])),
        if (solution != null)
          ExpansionTile(
            title: Text(
              solution!['provenance'] == 'AI_GENERATED_REFERENCE'
                  ? 'AI 생성 참고 풀이 · 비교'
                  : '공식·검수 참고 풀이 · 비교',
            ),
            children: [MathText(solution!['body'] as String? ?? '')],
          ),
        OutlinedButton(
          onPressed: busy ? null : widget.onRewrite,
          child: const Text('직접 풀이 수정하기'),
        ),
      ],
    );
  }
}
