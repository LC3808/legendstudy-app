import 'package:flutter/material.dart';

/// Canonical LegendStudy brand logotype — **레전드스터디⁺**.
///
/// Owner brand standard (2026-10-09):
/// - Korean logotype is `레전드스터디` + a **superscript `+`**.
/// - The `+` is a *separate element* whose size and position are controlled here
///   (never the Unicode superscript character `⁺`), sitting smaller than the
///   body glyphs at the upper-right of the name.
/// - Accessibility / plain text keeps the official name `레전드스터디+`.
/// - Official English name is **LegendStudy Plus** (not `LegendStudy+`).
///
/// One widget so splash, onboarding and any future logotype surface render the
/// mark identically. Scales with [fontSize]; the `+` tracks it.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.fontSize = 26,
    this.color = const Color(0xFF12161F),
    this.fontWeight = FontWeight.w800,
    this.letterSpacing = -0.2,
  });

  /// Official plain-text / accessibility name.
  static const String name = '레전드스터디+';

  /// Official English name. Not `LegendStudy+`.
  static const String englishName = 'LegendStudy Plus';

  final double fontSize;
  final Color color;
  final FontWeight fontWeight;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    // Superscript `+`: half the body size, raised toward the cap line and set
    // just to the right of the last glyph.
    final plusSize = fontSize * 0.5;
    return Semantics(
      label: name,
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(text: '레전드스터디'),
            WidgetSpan(
              alignment: PlaceholderAlignment.top,
              child: Transform.translate(
                // Tiny gap before the mark; raised so it reads as a superscript
                // rather than sitting on the baseline.
                offset: Offset(fontSize * 0.04, -fontSize * 0.02),
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: plusSize,
                    fontWeight: fontWeight,
                    color: color,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: color,
          letterSpacing: letterSpacing,
          height: 1.1,
        ),
        textDirection: TextDirection.ltr,
      ),
    );
  }
}
