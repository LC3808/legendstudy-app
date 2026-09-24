import 'package:flutter/material.dart';

/// Owner-confirmed icon brand #FFA300 with neutral selection surfaces. Functional color roles, never per-screen accents.
abstract final class AppTokens {
  static const primary = Color(0xFFFFA300);
  static const primaryDark = Color(0xFF9A5800);
  static const primarySoft = Color(0xFFE6E9EE);
  static const brand = Color(0xFFFFA300);
  static const background = Color(0xFFF4F6F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceWarm = surface; // Compatibility alias for existing cards.
  static const textPrimary = Color(0xFF1B2A4A);
  static const textSecondary = Color(0xFF5B6472);
  static const textTertiary = Color(0xFF8A93A3);
  // Palette orange is a fill, not small text on white. Accessible ink variants.
  static const primaryInk = Color(0xFFA94B00);
  static const dangerInk = Color(0xFFB42332);
  static const info = Color(0xFF2563A8);
  static const success = Color(0xFF1F9D57);
  static const warning = Color(0xFFE8A400);
  static const danger = Color(0xFFE5484D);
  static const disabled = Color(0xFFC2C7D0);
  static const divider = Color(0xFFEDF0F3);
  static const cardBorder = Color(0xFFE6E9EE);
  static const homeCardVerticalPadding = space8;
  static const homeCardGap = space8;
  static const navigationIndicator = primarySoft;
  static const space2 = 2.0, space4 = 4.0, space8 = 8.0, space12 = 12.0;
  static const space16 = 16.0, space20 = 20.0, space24 = 24.0, space32 = 32.0;
  static const radiusSm = 10.0,
      radiusMd = 14.0,
      radiusLg = 20.0,
      radiusPill = 999.0;
  static const iconSize = 24.0, iconDense = 20.0, iconNav = 22.0;
  static const pageTitle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static const hero = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.15,
  );
  static const sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );
  static const cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );
  static const body = TextStyle(fontSize: 15, height: 1.5);
  static const secondary = TextStyle(
    fontSize: 14,
    height: 1.5,
    color: textSecondary,
  );
  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: textSecondary,
  );
  static const button = TextStyle(fontSize: 15, fontWeight: FontWeight.w700);
  static const shadowSm = [
    BoxShadow(color: Color(0x0F141E32), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const shadowMd = [
    BoxShadow(color: Color(0x1A141E32), offset: Offset(0, 4), blurRadius: 12),
  ];
  static const pagePadding = space20, sectionGap = space24, smallGap = space8;
  static const cardRadius = radiusMd, chipRadius = radiusPill;
  static const spacing = pagePadding, radius = radiusLg;
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
          secondary: AppTokens.primaryInk,
          onSecondary: AppTokens.surface,
          secondaryContainer: AppTokens.primarySoft,
          onSecondaryContainer: AppTokens.textPrimary,
          surfaceTint: Colors.transparent,
          surface: AppTokens.surface,
          onSurface: AppTokens.textPrimary,
          surfaceContainerLowest: AppTokens.surface,
          surfaceContainerLow: AppTokens.background,
          surfaceContainer: AppTokens.background,
          surfaceContainerHigh: AppTokens.divider,
          surfaceContainerHighest: AppTokens.cardBorder,
          onSurfaceVariant: AppTokens.textSecondary,
          outline: AppTokens.textSecondary,
          outlineVariant: AppTokens.cardBorder,
          error: AppTokens.dangerInk,
        );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTokens.radiusSm),
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
      iconTheme: const IconThemeData(
        size: AppTokens.iconSize,
        color: AppTokens.textSecondary,
      ),
      dividerTheme: const DividerThemeData(color: AppTokens.divider, space: 1),
      cardTheme: CardThemeData(
        color: AppTokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
        shadowColor: const Color(0x0F141E32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        minVerticalPadding: 8,
        minTileHeight: 48,
        iconColor: AppTokens.textSecondary,
      ),
      textTheme:
          const TextTheme(
            headlineSmall: AppTokens.pageTitle,
            titleLarge: AppTokens.sectionTitle,
            titleMedium: AppTokens.cardTitle,
            bodyLarge: AppTokens.body,
            bodyMedium: AppTokens.body,
            bodySmall: AppTokens.secondary,
            labelMedium: AppTokens.caption,
            labelLarge: AppTokens.button,
          ).apply(
            bodyColor: AppTokens.textPrimary,
            displayColor: AppTokens.textPrimary,
          ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppTokens.surface,
        contentPadding: const EdgeInsets.all(AppTokens.space16),
        hintStyle: AppTokens.secondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          borderSide: const BorderSide(color: AppTokens.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          borderSide: const BorderSide(color: AppTokens.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
          borderSide: const BorderSide(color: AppTokens.primaryInk, width: 2),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppTokens.surface,
        selectedColor: AppTokens.primarySoft,
        checkmarkColor: AppTokens.primaryInk,
        labelStyle: AppTokens.secondary.copyWith(color: AppTokens.textPrimary),
        side: const BorderSide(color: AppTokens.cardBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppTokens.surface,
        indicatorColor: AppTokens.navigationIndicator,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: AppTokens.iconNav,
            color: s.contains(WidgetState.selected)
                ? AppTokens.primaryInk
                : AppTokens.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontSize: 12,
            color: s.contains(WidgetState.selected)
                ? AppTokens.primaryInk
                : AppTokens.textSecondary,
            fontWeight: s.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
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
          side: const BorderSide(color: AppTokens.cardBorder),
          shape: shape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: shape,
        ),
      ),
    );
  }
}
