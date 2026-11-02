import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

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
                    source,
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
    final isolatedFormula =
        !hasDelimiters &&
        !text.contains('\n') &&
        !RegExp(r'[가-힣]').hasMatch(text) &&
        !RegExp(r'[A-Za-z]{3,}')
            .hasMatch(text.replaceAll(RegExp(r'\\[A-Za-z]+'), '')) &&
        RegExp(r'\\[a-zA-Z]+|[=^_∫]').hasMatch(text);
    return MathText(isolatedFormula ? '\\[$text\\]' : text);
  }
}
