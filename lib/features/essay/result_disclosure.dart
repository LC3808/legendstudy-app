import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// One text node in both states: never render an excerpt beside its full body.
class ResultTextDisclosure extends StatefulWidget {
  const ResultTextDisclosure({super.key, required this.text});
  final String text;
  @override
  State<ResultTextDisclosure> createState() => _ResultTextDisclosureState();
}

class _ResultTextDisclosureState extends State<ResultTextDisclosure> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => setState(() => expanded = !expanded),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              widget.text,
              maxLines: expanded ? null : 3,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: AppTokens.body.copyWith(height: 1.6),
            ),
          ),
          Icon(
            expanded ? Icons.expand_less : Icons.expand_more,
            semanticLabel: expanded ? '접기' : '펼치기',
          ),
        ],
      ),
    ),
  );
}

class ResultAccordion extends StatelessWidget {
  const ResultAccordion({super.key, required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 16),
    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
    shape: const Border(bottom: BorderSide(color: AppTokens.cardBorder)),
    collapsedShape: const Border(
      bottom: BorderSide(color: AppTokens.cardBorder),
    ),
    title: Text(title, textAlign: TextAlign.left),
    children: [
      DefaultTextStyle.merge(
        style: AppTokens.body.copyWith(height: 1.6),
        child: child,
      ),
    ],
  );
}

/// Preserve the full official criterion, but keep it out of the chart's axis.
class GrowthCriterionTitle extends StatelessWidget {
  const GrowthCriterionTitle({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    if (name.runes.length <= 70) {
      return Text(name, textAlign: TextAlign.left, style: AppTokens.body);
    }
    final first = name.split('\n').first.trim();
    return ResultAccordion(
      title: first.isNotEmpty && first.length < 60 ? first : '평가 기준 자세히 보기',
      child: Text(name, textAlign: TextAlign.left),
    );
  }
}
