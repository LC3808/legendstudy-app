import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/study_models.dart';

// A 60-minute minimum axis keeps a one-minute session from filling the chart.
double studyChartCeiling(List<int> totals) =>
    math.max(3600000, totals.fold<int>(0, math.max)).toDouble();
double studyBarHeight(int duration, double ceiling) => 160 * duration / ceiling;

class StudyBarChart extends StatelessWidget {
  const StudyBarChart({super.key, required this.labels, required this.totals});
  final List<String> labels;
  final List<int> totals;
  @override
  Widget build(BuildContext context) {
    final ceiling = studyChartCeiling(totals);
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('공부시간 · 최대 눈금 ${studyDuration(ceiling.toInt())}'),
        const SizedBox(height: 8),
        // Scroll rather than overlap labels; logical order always stays oldest first.
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            textDirection: TextDirection.ltr,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < totals.length; i++)
                Semantics(
                  label: '${labels[i]}, ${studyDuration(totals[i])}',
                  child: ExcludeSemantics(
                    child: SizedBox(
                      width: 68 * scale,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 160,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                key: ValueKey('study-bar-$i'),
                                width: 24,
                                height: studyBarHeight(totals[i], ceiling),
                                child: totals[i] == 0
                                    ? null
                                    : DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(3),
                                              ),
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const Divider(height: 1),
                          const SizedBox(height: 6),
                          Text(labels[i], textAlign: TextAlign.center),
                          Text(
                            studyDuration(totals[i]),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('오래된 기간 → 최근 기간 · 좌우로 넘겨 확인하세요.'),
      ],
    );
  }
}
