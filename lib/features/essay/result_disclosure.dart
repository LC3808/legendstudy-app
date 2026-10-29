import 'dart:async';

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
              displayEssayText(widget.text),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      backgroundColor: const Color(0xFFF8FAFC),
      collapsedBackgroundColor: title == '음성으로 듣기'
          ? const Color(0xFFFFF8EB)
          : const Color(0xFFF8FAFC),
      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
      shape: EssayDesign.shape,
      collapsedShape: EssayDesign.shape,
      title: Text(title, textAlign: TextAlign.left, style: AppTokens.cardTitle),
      children: [
        DefaultTextStyle.merge(
          style: AppTokens.body.copyWith(height: 1.6),
          child: child,
        ),
      ],
    ),
  );
}

/// Preserve the full official criterion, but keep it out of the chart's axis.
class GrowthCriterionTitle extends StatelessWidget {
  const GrowthCriterionTitle({super.key, required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final first = name.split('\n').first.trim();
    final titled = name.contains('\n') && first.isNotEmpty && first.length < 60;
    return ResultAccordion(
      title: titled ? first : '평가 기준 자세히 보기',
      child: Text(
        displayEssayText(
          titled ? name.substring(name.indexOf('\n') + 1) : name,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}

/// Scoped LAB presentation tokens; the rest of the app keeps its current theme.
abstract final class EssayDesign {
  static const accent = Color(0xFFFFAC14);
  static const radius = 14.0;
  static final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radius),
    side: const BorderSide(color: AppTokens.cardBorder),
  );
  static final segmentStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? AppTokens.textPrimary
          : AppTokens.surface,
    ),
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? Colors.white
          : AppTokens.textPrimary,
    ),
    side: const WidgetStatePropertyAll(BorderSide(color: AppTokens.cardBorder)),
  );
}

class EssaySurface extends StatelessWidget {
  const EssaySurface({
    super.key,
    required this.child,
    this.highlighted = false,
    this.padding = const EdgeInsets.all(16),
  });
  final Widget child;
  final bool highlighted;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Material(
    color: AppTokens.surface,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(EssayDesign.radius),
      side: BorderSide(
        color: highlighted ? EssayDesign.accent : AppTokens.cardBorder,
      ),
    ),
    child: Padding(padding: padding, child: child),
  );
}

/// Never compress multiple criteria into one synthetic question score.
class EssayQuestionGrid extends StatelessWidget {
  const EssayQuestionGrid({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns =
          box.maxWidth >= 680 &&
          MediaQuery.textScalerOf(context).scale(16) <= 20;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final child in children)
            SizedBox(
              width: columns ? (box.maxWidth - 16) / 2 : box.maxWidth,
              child: child,
            ),
        ],
      );
    },
  );
}

/// Presentation only. Keep blank paragraphs, markers, formulas and table rows.
String displayEssayText(String source) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final out = <String>[];
  final structured = RegExp(
    r'^\s*(?:[•●▶①-⑳]|[-*] |\d+[.)]|\[|준거|평가 영역|채점|문항|하위|[|]|.*[=<>∑√])',
  );
  for (final line in lines) {
    if (out.isNotEmpty &&
        out.last.trim().length >= 20 &&
        line.trim().isNotEmpty &&
        !RegExp(r'[.!?。:]$').hasMatch(out.last.trim()) &&
        !structured.hasMatch(line) &&
        !line.contains('  ') &&
        !out.last.contains('|') &&
        !out.last.contains('  ') &&
        !RegExp(r'[=<>∑√]').hasMatch(out.last)) {
      out[out.length - 1] = '${out.last.trimRight()} ${line.trimLeft()}';
    } else {
      out.add(line);
    }
  }
  return out.join('\n');
}

class ProcessingGuidance extends StatefulWidget {
  const ProcessingGuidance({super.key, required this.active});
  final bool active;
  @override
  State<ProcessingGuidance> createState() => _ProcessingGuidanceState();
}

class _ProcessingGuidanceState extends State<ProcessingGuidance> {
  Timer? timer;
  int index = 0;
  static const messages = ['첨삭 결과를 기다리고 있어요.', '잠시 쉬어가세요. 결과가 준비되면 확인할 수 있어요.'];
  void schedule() {
    timer?.cancel();
    if (widget.active) {
      timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (mounted) setState(() => index = (index + 1) % messages.length);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    schedule();
  }

  @override
  void didUpdateWidget(covariant ProcessingGuidance old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) schedule();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 250),
    child: Text(
      widget.active ? messages[index] : '접수된 답안의 처리 상태를 확인하고 있어요.',
      key: ValueKey(widget.active ? index : -1),
      textAlign: TextAlign.center,
      style: AppTokens.secondary,
    ),
  );
}
