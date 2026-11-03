import 'package:flutter/material.dart';

import '../math_text.dart';
import 'academic_purple.dart';

/// A view of the supplied evidence, never a rewritten/AI-corrected answer.
/// Long quotations must not push the student's improvement tasks off screen.
class MathAnswerEvidence extends StatefulWidget {
  const MathAnswerEvidence(this.source, {super.key});
  final String source;
  @override
  State<MathAnswerEvidence> createState() => _MathAnswerEvidenceState();
}

class _MathAnswerEvidenceState extends State<MathAnswerEvidence> {
  bool expanded = false;
  @override
  void didUpdateWidget(covariant MathAnswerEvidence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) expanded = false;
  }

  @override
  Widget build(BuildContext context) {
    final blocks = mathAnswerBlocks(widget.source);
    final long = widget.source.length > 500 || blocks.length > 6;
    Widget document = MathFormulaSurface(child: MathStudentText(widget.source));
    if (long && !expanded) {
      document = ClipRect(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 180),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: document,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        document,
        if (long) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() => expanded = !expanded),
            icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
            label: Text(expanded ? '답안 근거 접기' : '답안 근거 전체 보기'),
          ),
        ],
      ],
    );
  }
}
