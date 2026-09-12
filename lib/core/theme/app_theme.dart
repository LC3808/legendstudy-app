import 'package:flutter/material.dart';

abstract final class AppTokens {
  static const primary = Color(0xFFFFAC14);
  static const primaryDark = Color(0xFFE99500);
  static const primarySoft = Color(0xFFFFF3DC);
  static const background = Color(0xFFFFFFFF);
  static const surfaceWarm = Color(0xFFFFFDF9);
  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF666666);
  static const divider = Color(0xFFEEEEEE);
  static const spacing = 24.0;
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
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppTokens.surfaceWarm,
        indicatorColor: AppTokens.primarySoft,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
    );
  }
}
