import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/study_models.dart';
import '../../../core/theme/app_theme.dart';

double studyChartCeiling(List<int> totals) =>
    totals.fold<int>(0, math.max).toDouble();
double studyBarHeight(int duration, double ceiling) =>
    ceiling <= 0 ? 0 : 160 * duration / ceiling;

String studyBarDuration(int duration) =>
    duration >= 3600000 ? '${duration ~/ 60000}분' : studyDuration(duration);

double studyChartAverage(List<int> totals) =>
    totals.isEmpty ? 0 : totals.fold<int>(0, (a, b) => a + b) / totals.length;

class StudyBarChart extends StatefulWidget {
  const StudyBarChart({
    super.key,
    required this.labels,
    required this.totals,
    this.descriptions,
    this.dailyDetails = false,
  });
  final bool dailyDetails;
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
    final average = studyChartAverage(widget.totals);
    final averageText = '평균 ${studyDuration(average.round())}';
    final total = widget.totals.fold<int>(0, (sum, value) => sum + value);
    final measure = TextPainter(
      text: TextSpan(
        text: averageText,
        style: DefaultTextStyle.of(context).style.merge(AppTokens.caption),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final annotationHeight = widget.dailyDetails ? measure.height + 6 : 0.0;
    measure.dispose();
    final meanY = 160.0 * (1 - (ceiling <= 0 ? 0.0 : average / ceiling));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          children: [
            if (widget.dailyDetails) const Text('이번 주'),
            if (widget.dailyDetails) Text('총 ${studyDuration(total)}'),
            Text(
              '${widget.dailyDetails ? '일 최대' : '최대'} ${studyDuration(ceiling.toInt())}',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: annotationHeight),
              child: Row(
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium,
                                ),
                                if (widget.dailyDetails)
                                  Text(
                                    studyBarDuration(widget.totals[i]),
                                    key: ValueKey('study-value-$i'),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(fontSize: 10),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.dailyDetails)
              Positioned(
                left: 0,
                right: 0,
                top: annotationHeight,
                height: 160,
                child: IgnorePointer(
                  child: CustomPaint(
                    key: const Key('study-average-line'),
                    painter: StudyAverageLine(
                      ceiling <= 0 ? 0 : average / ceiling,
                    ),
                  ),
                ),
              ),
            if (widget.dailyDetails)
              Positioned(
                left: 0,
                top: meanY,
                child: IgnorePointer(
                  child: Container(
                    key: const Key('study-average-label'),
                    color: Theme.of(context).colorScheme.surface,
                    padding: const EdgeInsets.only(right: 4, bottom: 3),
                    child: Text(averageText, style: AppTokens.caption),
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

/// Reference only: zero average lies on the baseline, never creates a bar.
class StudyAverageLine extends CustomPainter {
  const StudyAverageLine(this.ratio);
  final double ratio;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTokens.disabled
      ..strokeWidth = 1;
    final y = size.height * (1 - ratio.clamp(0.0, 1.0));
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + 4, size.width), y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StudyAverageLine oldDelegate) =>
      ratio != oldDelegate.ratio;
}
