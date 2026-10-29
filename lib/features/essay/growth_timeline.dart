import 'result_disclosure.dart';

import 'package:flutter/material.dart';

import 'evaluation_report.dart';

/// Break each segment unless BOTH adjacent stored reports have the same scale.
/// No interpolation through missing rounds or rubric revisions.
class GrowthTimeline extends StatelessWidget {
  const GrowthTimeline({super.key, required this.reports});
  final List<EvaluationReport?> reports;
  @override
  Widget build(BuildContext context) {
    final names = <String, String>{};
    for (final report in reports) {
      for (final c in report?.rubric ?? <EvaluationCriterion>[]) {
        names[c.id] = c.name;
      }
    }
    if (names.isEmpty) return const Text('표시할 평가 항목이 없어요.');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('전체 성장 과정 · 1~5단계 (누락·기준 변경 구간은 연결하지 않아요)'),
        for (final entry in names.entries) ...[
          const SizedBox(height: 12),
          GrowthCriterionTitle(name: entry.value),
          if (reports.first != null &&
              reports.last != null &&
              compareEvaluationReports(
                    reports.first!,
                    reports.last!,
                    requireLineage: false,
                  ) !=
                  null)
            Text(
              '최초 ${reports.first!.rubric.where((c) => c.id == entry.key).firstOrNull?.display ?? '기록 없음'} → 최신 ${reports.last!.rubric.where((c) => c.id == entry.key).firstOrNull?.display ?? '기록 없음'}',
            ),
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _TimelinePainter(
                reports,
                entry.key,
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            children: [
              for (final (i, report) in reports.indexed)
                Text(
                  '${i + 1}회: ${report?.rubric.where((c) => c.id == entry.key).firstOrNull?.display ?? '기록 없음'}',
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter(this.reports, this.criterion, this.color);
  final List<EvaluationReport?> reports;
  final String criterion;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.grey.withValues(alpha: .25)
      ..strokeWidth = 1;
    for (var n = 1; n <= 5; n++) {
      final y = size.height - 10 - n * (size.height - 20) / 5;
      canvas.drawLine(Offset(10, y), Offset(size.width - 10, y), grid);
    }
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2;
    Offset? previous;
    for (var i = 0; i < reports.length; i++) {
      final report = reports[i];
      final matches = report?.rubric.where((c) => c.id == criterion).toList();
      final rating = matches?.length == 1 ? matches!.single.rating : null;
      if (rating == null) {
        previous = null;
        continue;
      }
      final point = Offset(
        10 +
            i *
                (size.width - 20) /
                (reports.length - 1).clamp(1, reports.length),
        size.height - 10 - rating * (size.height - 20) / 5,
      );
      if (previous != null &&
          i > 0 &&
          reports[i - 1] != null &&
          compareEvaluationReports(
                reports[i - 1]!,
                report!,
                requireLineage: false,
              ) !=
              null) {
        canvas.drawLine(previous, point, stroke);
      }
      canvas.drawCircle(point, 4, stroke);
      previous = point;
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter old) =>
      old.reports != reports ||
      old.criterion != criterion ||
      old.color != color;
}
