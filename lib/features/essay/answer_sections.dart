import 'package:flutter/material.dart';

/// Verified SWU 2026 official question pages 2/8, source SHA bd57ddfa…31be15.
/// These are writing sections, never new canonical questions/evaluation units.
List<String> essayAnswerSections(String? exam, String? question) {
  if (exam != '6679b5ff-d797-53c9-8a2a-424375d7210c') return const [];
  return switch (question) {
    'a69cb1c4-d6a4-5ae6-a68b-1bcec4a397f6' => const ['1-(1)', '1-(2)'],
    'd0862954-4d0d-5811-9b48-5dc8e319634d' => const ['2-(1)', '2-(2)'],
    _ => const [],
  };
}

String joinAnswerSections(List<String> labels, List<String> bodies) =>
    bodies.every((b) => b.isEmpty)
    ? ''
    : [for (var i = 0; i < labels.length; i++) '[${labels[i]}]\n${bodies[i]}']
          .join('\n\n');

/// Only our exact, unambiguous markers are split. Never infer legacy paragraphs.
List<String>? splitAnswerSections(String body, List<String> labels) {
  if (labels.length != 2) return null;
  if (body.isEmpty) return ['', ''];
  final first = '[${labels[0]}]\n', second = '\n\n[${labels[1]}]\n';
  if (!body.startsWith(first) || second.allMatches(body).length != 1) {
    return null;
  }
  final at = body.indexOf(second);
  if (at < first.length) return null;
  return [body.substring(first.length, at), body.substring(at + second.length)];
}

List<String> missingAnswerSections(String body, List<String> labels) {
  final parts = splitAnswerSections(body, labels);
  if (parts == null) return [];
  return [
    for (var i = 0; i < parts.length; i++)
      if (parts[i].trim().isEmpty) labels[i],
  ];
}

class SectionedAnswerInput extends StatefulWidget {
  const SectionedAnswerInput({
    super.key,
    required this.controller,
    required this.labels,
    required this.onChanged,
    required this.enabled,
  });
  final TextEditingController controller;
  final List<String> labels;
  final ValueChanged<String> onChanged;
  final bool enabled;
  @override
  State<SectionedAnswerInput> createState() => _SectionedAnswerInputState();
}

class _SectionedAnswerInputState extends State<SectionedAnswerInput> {
  late final parts = List.generate(
    widget.labels.length,
    (_) => TextEditingController(),
  );
  bool separated = false, updating = false;
  @override
  void initState() {
    super.initState();
    restore();
    widget.controller.addListener(restore);
  }

  void restore() {
    if (updating) return;
    final values = splitAnswerSections(widget.controller.text, widget.labels);
    separated = values != null;
    if (values != null) {
      for (var i = 0; i < parts.length; i++) {
        if (parts[i].text != values[i]) parts[i].text = values[i];
      }
    }
    if (mounted) setState(() {});
  }

  void edit() {
    updating = true;
    final body = joinAnswerSections(
      widget.labels,
      parts.map((p) => p.text).toList(),
    );
    widget.controller.value = TextEditingValue(
      text: body,
      selection: TextSelection.collapsed(offset: body.length),
    );
    widget.onChanged(body);
    updating = false;
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(restore);
    for (final p in parts) {
      p.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (separated) ...[
        for (var i = 0; i < parts.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextField(
              controller: parts[i],
              enabled: widget.enabled,
              minLines: 6,
              maxLines: null,
              maxLength:
                  (30000 -
                          widget.labels.fold<int>(
                            0,
                            (n, l) => n + l.length + 3,
                          ) -
                          2 -
                          parts
                              .where((p) => p != parts[i])
                              .fold<int>(0, (n, p) => n + p.text.length))
                      .clamp(1, 30000),
              decoration: InputDecoration(
                labelText: widget.labels[i],
                alignLabelWithHint: true,
              ),
              onChanged: (_) => edit(),
            ),
          ),
      ] else ...[
        Text(
          '${widget.labels.join(' · ')} 답안을 구분해 작성해 주세요. 기존 답안은 그대로 보존했습니다.',
        ),
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          minLines: 12,
          maxLines: null,
          maxLength: 30000,
          decoration: const InputDecoration(
            labelText: '내 답안',
            alignLabelWithHint: true,
          ),
          onChanged: widget.onChanged,
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final label in widget.labels)
              TextButton(
                onPressed: !widget.enabled
                    ? null
                    : () {
                        final old = widget.controller.text;
                        final selection = widget.controller.selection;
                        final at = selection.isValid
                            ? selection.extentOffset
                            : old.length;
                        final next = old.replaceRange(at, at, '\n\n[$label]\n');
                        if (next.length > 30000) return;
                        widget.controller.text = next;
                        widget.onChanged(next);
                      },
                child: Text('$label 표시 넣기'),
              ),
          ],
        ),
      ],
    ],
  );
}
