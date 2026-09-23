import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/study_models.dart';

double studyChartCeiling(List<int> totals) =>
    totals.fold<int>(0, math.max).toDouble();
double studyBarHeight(int duration, double ceiling) =>
    ceiling <= 0 ? 0 : 160 * duration / ceiling;

class StudyBarChart extends StatefulWidget {
  const StudyBarChart({
    super.key,
    required this.labels,
    required this.totals,
    this.descriptions,
  });
  final List<String> labels;
  final List<int> totals;
  final List<String>? descriptions;
  @override
  State<StudyBarChart> createState() => _StudyBarChartState();
}

class _StudyBarChartState extends State<StudyBarChart> {
  int? selected;
  @override
  void didUpdateWidget(StudyBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labels.length != widget.labels.length ||
        oldWidget.descriptions?.join() != widget.descriptions?.join()) {
      selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ceiling = studyChartCeiling(widget.totals);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('최대 ${studyDuration(ceiling.toInt())}'),
        const SizedBox(height: 8),
        Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < widget.totals.length; i++)
              Expanded(
                child: Semantics(
                  label:
                      '${widget.descriptions?[i] ?? widget.labels[i]}, ${studyDuration(widget.totals[i])}',
                  button: true,
                  selected: selected == i,
                  child: ExcludeSemantics(
                    child: InkWell(
                      onTap: () => setState(() => selected = i),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 160,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                key: ValueKey('study-bar-$i'),
                                width: 20,
                                height: studyBarHeight(
                                  widget.totals[i],
                                  ceiling,
                                ),
                                child: widget.totals[i] == 0
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
                          Text(
                            widget.labels[i],
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (selected != null) ...[
          const SizedBox(height: 8),
          Text(
            '${widget.descriptions?[selected!] ?? widget.labels[selected!]} · ${studyDuration(widget.totals[selected!])}',
          ),
        ],
      ],
    );
  }
}
