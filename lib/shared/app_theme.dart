// Light/dark theme + design tokens. Kept consistent with Apon ERP so
// future integration doesn't visually clash.

import 'package:flutter/material.dart';

abstract class AppColors {
  static const Color brandPrimary = Color(0xFF1F6FEB);
  static const Color brandAccent = Color(0xFF2EA043);
  static const Color warning = Color(0xFFE3B341);
  static const Color error = Color(0xFFD7263D);
  static const Color success = Color(0xFF2EA043);

  static const Color lightBg = Color(0xFFF6F8FA);
  static const Color lightSurface = Colors.white;
  static const Color lightBorder = Color(0xFFE1E4E8);

  static const Color darkBg = Color(0xFF0D1117);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkBorder = Color(0xFF30363D);

  // Semantic status palette — used by StatusPill and any
  // success/warning/danger/info/muted surface.
  static const Color statusInfo = brandPrimary;
  static const Color statusSuccess = success;
  static const Color statusWarning = warning;
  static const Color statusDanger = error;
  static const Color statusMuted = Color(0xFF6B7280); // slate-500

  // Sidebar — always dark regardless of light/dark theme (Rysenova style).
  static const Color sidebarBg = Color(0xFF0F172A); // slate-900
  static const Color sidebarGroupLabel = Color(0xFF94A3B8); // slate-400
  static const Color sidebarItem = Color(0xFFCBD5E1); // slate-300
  static const Color sidebarItemActive = Colors.white;
  static const Color sidebarPill = Color(0x1FFFFFFF); // white @ ~12%
  static const Color sidebarDivider = Color(0xFF1E293B); // slate-800

  // Shift palette — pastel bands reused across schedules,
  // attendance log, dashboard and the duty roster grid so a
  // shift is recognizable from anywhere.
  static const List<Color> shiftPalette = <Color>[
    Color(0xFFF4B5AE), // coral
    Color(0xFFB5D4F4), // sky
    Color(0xFFC8E6C9), // mint
    Color(0xFFFFE0B2), // peach
    Color(0xFFD7BDE2), // lavender
    Color(0xFFB2EBF2), // cyan
  ];

  // Stable color for a shift identified by a string key — same
  // key always returns the same band so the color follows a shift
  // wherever it appears.
  static Color shiftColorFor(String key) {
    if (key.isEmpty) return shiftPalette[0];
    final hash =
        key.codeUnits.fold<int>(0, (a, b) => (a + b) & 0x7FFFFFFF);
    return shiftPalette[hash % shiftPalette.length];
  }
}

abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
}

abstract class AppTheme {
  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandAccent,
        surface: AppColors.lightSurface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.lightBg,
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.lightBorder),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightSurface,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandAccent,
        surface: AppColors.darkSurface,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.darkBg,
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
