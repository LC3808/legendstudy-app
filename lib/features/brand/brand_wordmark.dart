import 'package:flutter/material.dart';

/// Canonical LegendStudy brand logotype — **레전드스터디⁺**.
///
/// Owner brand standard (2026-10-09, refined 2026-10-16):
/// - Korean logotype is `레전드스터디` + a **superscript `+`**.
/// - Rendered in the bundled **Pretendard** (SIL OFL) typeface — a modern
///   SemiBold sans-serif with slightly tightened tracking — so the mark reads as
///   a professional education-brand wordmark and is **identical on Android and
///   iOS** (never the per-platform system Gothic).
/// - Body is a deep navy; the `+` is the brand orange, set as a *separate
///   element* whose size and position are controlled here (never the Unicode
///   superscript `⁺`), sitting smaller than the body glyphs at the upper-right.
/// - Accessibility / plain text keeps the official name `레전드스터디+`.
/// - Official English name is **LegendStudy Plus** (not `LegendStudy+`).
///
/// One widget so splash and any future logotype surface render the mark
/// identically. Scales with [fontSize]; the `+` tracks it.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({
    super.key,
    this.fontSize = 26,
    this.color = brandNavy,
    this.plusColor = brandOrange,
    this.fontWeight = FontWeight.w600,
    this.letterSpacing = -0.5,
  });

  /// Deep navy body — professional, trustworthy, strong on a light splash.
  static const Color brandNavy = Color(0xFF17244B);

  /// Brand orange, matching the LegendStudy symbol (`AppTokens.brand`).
  static const Color brandOrange = Color(0xFFFFA300);

  /// Bundled wordmark typeface (see pubspec `fonts:` / fonts/OFL.txt).
  static const String fontFamily = 'Pretendard';

  /// Official plain-text / accessibility name.
  static const String name = '레전드스터디+';

  /// Official English name. Not `LegendStudy+`.
  static const String englishName = 'LegendStudy Plus';

  final double fontSize;
  final Color color;
  final Color plusColor;
  final FontWeight fontWeight;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    // Superscript `+`: half the body size, raised toward the cap line and set
    // just to the right of the last glyph, in the brand orange.
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
                    fontFamily: fontFamily,
                    fontSize: plusSize,
                    fontWeight: FontWeight.w600,
                    color: plusColor,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        style: TextStyle(
          fontFamily: fontFamily,
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
