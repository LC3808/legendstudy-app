import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const primary = Color(0xFFFFAC14);
  static const primaryDark = Color(0xFFE99500);
  static const primarySoft = Color(0xFFFFF3DC);
  static const background = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFFDF9);
  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF666666);
  static const divider = Color(0xFFE5E5E5);
  static const cardBorder = Color(0xFFDCDCDC);
  static const navigationIndicator = Color(0xFFFFE3B0);
  static const sectionTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
  static const pagePadding = 20.0;
  static const sectionGap = 24.0;
  static const smallGap = 8.0;
  static const cardRadius = 16.0;
  static const chipRadius = 24.0;
  static const spacing = pagePadding;
  static const radius = 20.0;
}

abstract final class AppTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppTokens.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppTokens.primary,
          onPrimary: AppTokens.textPrimary,
          primaryContainer: AppTokens.primarySoft,
          onPrimaryContainer: AppTokens.textPrimary,
          surface: AppTokens.background,
          onSurface: AppTokens.textPrimary,
          onSurfaceVariant: AppTokens.textSecondary,
          outlineVariant: AppTokens.divider,
        );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppTokens.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppTokens.background,
        foregroundColor: AppTokens.textPrimary,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(color: AppTokens.divider, space: 1),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppTokens.textPrimary,
        ),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 14, height: 1.5),
        labelMedium: TextStyle(fontSize: 12, color: AppTokens.textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppTokens.surfaceWarm,
        indicatorColor: AppTokens.navigationIndicator,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 12,
            color: AppTokens.textPrimary,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w400,
          ),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.textPrimary,
          minimumSize: const Size(48, 48),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.textPrimary,
          minimumSize: const Size(48, 48),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
  }
}
