import 'package:flutter/material.dart';

import '../math_text.dart';

/// Reuses the existing TeX representation/renderer; does not introduce a second editor format.
class MathFormulaEditor extends StatefulWidget {
  const MathFormulaEditor({
    required this.value,
    required this.onChanged,
    this.label = '수식·풀이 수정',
    this.enabled = true,
    super.key,
  });
  final String value, label;
  final ValueChanged<String> onChanged;
  final bool enabled;
  @override
  State<MathFormulaEditor> createState() => _MathFormulaEditorState();
}

class _MathFormulaEditorState extends State<MathFormulaEditor> {
  late final controller = TextEditingController(text: widget.value);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void insert(String source) {
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : controller.text.length;
    final end = selection.isValid ? selection.end : start;
    controller.value = TextEditingValue(
      text: controller.text.replaceRange(start, end, source),
      selection: TextSelection.collapsed(offset: start + source.length),
    );
    widget.onChanged(controller.text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (controller.text.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: MathStudentText(controller.text),
        ),
      Wrap(
        spacing: 6,
        children: [
          for (final item in const [
            ('분수', r'\frac{}{}'),
            ('지수', '^{}'),
            ('첨자', '_{}'),
            ('적분', r'\int_{}^{}'),
            ('괄호', r'\left(\right)'),
            ('부등호', r'\leq'),
            ('±', r'\pm'),
          ])
            ActionChip(
              label: Text(item.$1),
              onPressed: widget.enabled ? () => insert(item.$2) : null,
            ),
        ],
      ),
      TextField(
        controller: controller,
        enabled: widget.enabled,
        minLines: 2,
        maxLines: 8,
        maxLength: 10000,
        decoration: InputDecoration(
          labelText: widget.label,
          helperText: '기호를 넣은 뒤 빈칸을 채워 주세요. 원문은 별도로 보존됩니다.',
        ),
        onChanged: (v) {
          widget.onChanged(v);
          setState(() {});
        },
      ),
    ],
  );
}

bool unresolvedMath(String text) =>
    text.trim().isEmpty ||
    RegExp(
      r'UNCERTAIN|UNREADABLE|판독\s*(?:불가|불명|불확실)|인식\s*(?:불명|불가|불확실)|불명확|불확실|\[\s*분수식\s*\]|\?|？|�|\{\s*\}',
      caseSensitive: false,
    ).hasMatch(text);
