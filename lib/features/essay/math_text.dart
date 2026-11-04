import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Lossless glyph spelling for the renderer; never modifies stored evidence.
String displayMathSource(String source) => source
    .replaceAll('′', "'")
    .replaceAllMapped(
      RegExp(r'√([A-Za-zα-ωΑ-Ω]|[0-9]+)'),
      (m) => '\\sqrt{${m[1]}}',
    )
    .replaceAllMapped(RegExp('([A-Za-z])\u0304'), (m) => '\\bar{${m[1]}}');

/// Rendering is a projection only; malformed TeX remains selectable source text.
class MathText extends StatelessWidget {
  const MathText(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final pattern = RegExp(
      r'\$\$([\s\S]+?)\$\$|\\\[([\s\S]+?)\\\]|\\\(([\s\S]+?)\\\)|\$([^$\n]+?)\$',
    );
    final spans = <InlineSpan>[];
    var end = 0;
    for (final match in pattern.allMatches(text)) {
      spans.add(TextSpan(text: text.substring(end, match.start)));
      final source =
          match.group(1) ?? match.group(2) ?? match.group(3) ?? match.group(4)!;
      final bounded =
          source.length <= 6000 &&
          !RegExp(
            r'\\(def|gdef|edef|newcommand|renewcommand|include|href|html)',
          ).hasMatch(source);
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: bounded
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Math.tex(
                    displayMathSource(source),
                    onErrorFallback: (_) => SelectableText(match.group(0)!),
                  ),
                )
              : SelectableText(match.group(0)!),
        ),
      );
      end = match.end;
    }
    if (spans.isEmpty) return SelectableText(text);
    spans.add(TextSpan(text: text.substring(end)));
    return Text.rich(TextSpan(children: spans));
  }
}

/// Lossless layout boundaries. Never split a TeX environment/display expression
/// or an explicit table. Joining the blocks reproduces every source character.
List<String> mathAnswerBlocks(String text) {
  final blocks = <String>[];
  final token = RegExp(
    r'\\\[|\\\]|\\\(|\\\)|(?<!\\)\$\$|(?<!\\)\$|\\begin\{[^}]+\}|\\end\{[^}]+\}|(?<=[다요]\.)[ \t]+|[ \t]+(?=\(\d+-\d+\)[ \t])|\n',
  );
  String? delimiter;
  var environments = 0, start = 0;
  bool tableLine(String line) =>
      line.contains(' | ') ||
      (line.trim().startsWith('|') && line.trim().endsWith('|'));
  for (final m in token.allMatches(text)) {
    final value = m[0]!;
    if (value.startsWith(r'\begin')) {
      environments++;
      continue;
    }
    if (value.startsWith(r'\end')) {
      if (environments > 0) environments--;
      continue;
    }
    if (value == '\n' || value.trim().isEmpty) {
      if (delimiter != null || environments > 0) continue;
      final nextEnd = text.indexOf('\n', m.end);
      final next = text.substring(m.end, nextEnd < 0 ? text.length : nextEnd);
      final line = text.substring(start, m.start).split('\n').last;
      if (tableLine(line) && tableLine(next)) continue;
      blocks.add(text.substring(start, m.end));
      start = m.end;
    } else if (delimiter == null) {
      delimiter = switch (value) {
        r'\[' => r'\]',
        r'\(' => r'\)',
        r'\]' || r'\)' => null,
        _ => value,
      };
    } else if (value == delimiter) {
      delimiter = null;
    }
  }
  if (start < text.length) blocks.add(text.substring(start));
  return blocks.isEmpty ? [text] : blocks;
}

/// Confirmed student evidence can be a formula or a full prose transcript.
/// Keep prose/line breaks intact; only wrap an isolated, undelimited expression.
class MathStudentText extends StatelessWidget {
  const MathStudentText(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final hasDelimiters =
        text.contains(r'$') || text.contains(r'\[') || text.contains(r'\(');
    bool formula(String value) {
      final words = value
          .replaceAll(
            RegExp(
              r'\\[A-Za-z]+|\{(?:p|b|B|v|V)?matrix\}|\{(?:aligned|cases|array)\}',
            ),
            '',
          )
          .replaceAll(
            RegExp(r'\b(sin|cos|tan|log|ln|lim|max|min|exp|det|dx|dy|dt)\b'),
            '',
          );
      return !RegExp(r'[가-힣]|[A-Za-z]{2,}').hasMatch(words) &&
          RegExp(r'\\[A-Za-z]+|[=^_∫≤≥<>]').hasMatch(value);
    }

    final tables = RegExp(
      r'^[^\n]*[ \t]\|[ \t][^\n]*(?:\n[^\n]*[ \t]\|[ \t][^\n]*)+',
      multiLine: true,
    ).allMatches(text).toList();
    if (tables.isNotEmpty &&
        (tables.first.start != 0 || tables.first.end != text.length)) {
      final segments = <Widget>[];
      var end = 0;
      for (final table in tables) {
        if (end < table.start) {
          segments.add(MathStudentText(text.substring(end, table.start)));
        }
        segments.add(MathStudentText(table.group(0)!));
        end = table.end;
      }
      if (end < text.length) segments.add(MathStudentText(text.substring(end)));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: segments,
      );
    }
    final blocks = mathAnswerBlocks(text);
    if (blocks.length > 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final block in blocks)
            Padding(
              // A physical OCR line is not automatically a paragraph.
              padding: EdgeInsets.only(
                bottom: block.trim().isEmpty
                    ? 12
                    : RegExp(r'[다요]\.[ \t\r\n]*$').hasMatch(block)
                    ? 10
                    : 2,
              ),
              child: MathStudentText(block.replaceFirst(RegExp(r'\r?\n$'), '')),
            ),
        ],
      );
    }
    final marker = RegExp(
      r'^(\s*(?:\([ivx]+\)|[ivx]+\)|\(\d+-\d+\)|\(?\d+\)|\d+\.(?=\s))\s*)([\s\S]+)$',
    ).firstMatch(text);
    if (marker != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(marker[1]!),
          const SizedBox(width: 6),
          Expanded(child: MathStudentText(marker[2]!)),
        ],
      );
    }
    if (hasDelimiters) return MathText(text);
    final lines = text.split('\n');
    if (lines.length > 1 &&
        lines.every(
          (l) =>
              l.contains(' | ') ||
              (l.trim().length >= 2 &&
                  l.trim().startsWith('|') &&
                  l.trim().endsWith('|')),
        )) {
      final rows = lines
          .map(
            (l) => l
                .trim()
                .replaceFirst(RegExp(r'^\|'), '')
                .replaceFirst(RegExp(r'\|$'), '')
                .split('|')
                .map((c) => c.trim())
                .toList(),
          )
          .toList();
      if (rows.first.length > 1 &&
          rows.every((r) => r.length == rows.first.length)) {
        final header = rows[1].every((c) => RegExp(r'^:?-{3,}:?$').hasMatch(c));
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: const Color(0xFFDCD5F1)),
            children: [
              for (var i = 0; i < rows.length; i++)
                if (!header || i != 1)
                  TableRow(
                    children: [
                      for (final cell in rows[i])
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: MathStudentText(cell),
                        ),
                    ],
                  ),
            ],
          ),
        );
      }
    }
    if (formula(text)) return MathText(r'\[' + text + r'\]');
    // Display delimiters only: keep all source characters and line breaks.
    final rendered = lines
        .map((line) {
          if (formula(line)) return r'\[' + line + r'\]';
          final parts = line.split(RegExp(r'(?=[가-힣])|(?<=[가-힣])'));
          return parts
              .map((part) => formula(part) ? r'\(' + part + r'\)' : part)
              .join();
        })
        .join('\n');
    return MathText(rendered);
  }
}
