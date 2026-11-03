import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

/// Lossless glyph spelling for the renderer; never modifies stored evidence.
String displayMathSource(String source) => source
    .replaceAllMapped(
      RegExp(r'√([A-Za-zα-ωΑ-Ω]|[0-9]+)'),
      (m) => '\\sqrt{${m[1]}}',
    )
    .replaceAllMapped(
      RegExp('([A-Za-z])\u0304'),
      (m) => '\\bar{${m[1]}}',
    );

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
