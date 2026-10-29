import 'result_disclosure.dart';
import '../../core/theme/app_theme.dart';

import 'package:flutter/material.dart';

import 'evaluation_report.dart';

class GrowthBars extends StatelessWidget {
  const GrowthBars({
    required this.before,
    required this.after,
    this.learning = false,
    this.beforeLabel = '이전',
    this.afterLabel = '최근',
    super.key,
  });
  final bool learning;
  final String beforeLabel, afterLabel;
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GrowthCriterionTitle(name: c.after.name),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(c.before.rating!, beforeLabel, Colors.blueGrey),
                    bar(c.after.rating!, afterLabel, const Color(0xFFFFAC14)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        (c.after.rating! < c.before.rating!
                                ? const Color(0xFF9E344A)
                                : c.after.rating! > c.before.rating!
                                ? EssayDesign.accent
                                : Colors.blueGrey)
                            .withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    c.before.rating == c.after.rating
                        ? '평가 단계 유지 · ${c.after.rating}단계'
                        : '평가 단계 ${c.before.rating} → ${c.after.rating}',
                    style: AppTokens.body.copyWith(
                      color: c.after.rating! < c.before.rating!
                          ? const Color(0xFF9E344A)
                          : c.after.rating! > c.before.rating!
                          ? const Color(0xFF8A4B00)
                          : AppTokens.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.left,
                  ),
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
