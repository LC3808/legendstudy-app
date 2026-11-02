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
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
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
  const MathCard({required this.child, this.tinted = false, super.key});
  final Widget child;
  final bool tinted;
  @override
  Widget build(BuildContext context) => Card(
    color: tinted ? AcademicPurple.soft : AcademicPurple.card,
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}
