import 'package:flutter/material.dart';

import 'evaluation_report.dart';

class GrowthBars extends StatelessWidget {
  const GrowthBars({
    required this.before,
    required this.after,
    this.learning = false,
    super.key,
  });
  final bool learning;
  final EvaluationReport before, after;
  @override
  Widget build(BuildContext context) {
    final changes = compareEvaluationReports(
      before,
      after,
      requireLineage: !learning,
    );
    if (changes == null) {
      return const Text('같은 문제·평가 기준으로 비교할 수 있는 기록이 아직 부족해요.');
    }
    final numeric = changes
        .where((c) => c.before.rating != null && c.after.rating != null)
        .toList();
    Widget bar(int n, String label, Color color) => Expanded(
      child: Semantics(
        label: '$label $n / 5단계',
        child: Column(
          children: [
            Text('$n'),
            SizedBox(
              height: 100,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 26,
                  height: n * 20.0,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Text(label),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('같은 문제·평가 기준의 1~5단계 결과'),
        for (final c in numeric)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  c.after.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    bar(c.before.rating!, '이전', Colors.blueGrey),
                    bar(
                      c.after.rating!,
                      '최근',
                      Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        for (final c in changes.where(
          (c) => c.before.rating == null || c.after.rating == null,
        ))
          Text('${c.after.name} · ${c.before.display} → ${c.after.display}'),
      ],
    );
  }
}
