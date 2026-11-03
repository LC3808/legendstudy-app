import 'package:flutter/material.dart';

abstract final class AcademicPurple {
  static const primary = Color(0xFF6340C8),
      dark = Color(0xFF5032A8),
      soft = Color(0xFFF5F2FF),
      emphasis = Color(0xFFEDE7FF),
      background = Color(0xFFF8F9FC),
      card = Colors.white,
      ink = Color(0xFF1B2B49),
      secondary = Color(0xFF667085),
      success = Color(0xFF16A34A),
      error = Color(0xFFDC2626);
  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: ink,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 1.4,
          color: ink,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.45,
          color: ink,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(
          fontSize: 16,
          height: 1.65,
          color: ink,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          fontSize: 16,
          height: 1.65,
          color: ink,
        ),
        bodySmall: base.textTheme.bodySmall?.copyWith(
          fontSize: 13,
          height: 1.5,
          color: secondary,
        ),
      ),
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: emphasis,
        onPrimaryContainer: dark,
        surface: card,
        onSurface: ink,
        onSurfaceVariant: secondary,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          side: BorderSide(color: emphasis),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dark,
          minimumSize: const Size(48, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: base.textTheme.labelLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          side: const BorderSide(color: primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: emphasis,
        space: 28,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: emphasis),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: secondary,
        indicatorColor: primary,
      ),
    );
  }
}

class MathMobileTheme extends StatelessWidget {
  const MathMobileTheme({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Theme(data: AcademicPurple.theme(context), child: child);
}

class MathCard extends StatelessWidget {
  const MathCard({
    required this.child,
    this.tinted = false,
    this.border,
    super.key,
  });
  final Widget child;
  final bool tinted;
  final BorderSide? border;
  @override
  Widget build(BuildContext context) => Card(
    color: tinted ? AcademicPurple.soft : AcademicPurple.card,
    shape: border == null
        ? null
        : RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: border!,
          ),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

/// Presentation only: labels never rewrite or summarize the stored feedback.
class MathContentSection extends StatelessWidget {
  const MathContentSection({
    required this.label,
    required this.child,
    super.key,
  });
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.titleSmall
            ?.copyWith(color: AcademicPurple.dark),
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}

class MathFormulaSurface extends StatelessWidget {
  const MathFormulaSurface({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AcademicPurple.soft,
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
}
