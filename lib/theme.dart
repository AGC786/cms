import 'package:flutter/material.dart';

/// Central color + gradient definitions matching the AIT ERP prototype.
class AppColors {
  static const maroon = Color(0xFF8C1848);
  static const maroonDark = Color(0xFF6E1236);
  static const magenta = Color(0xFFC31E73);
  static const blueMid = Color(0xFF1C4FA0);
  static const blueDark = Color(0xFF123A7A);
  static const purple = Color(0xFF6A2F8F);
  static const green = Color(0xFF1E8A3C);
  static const red = Color(0xFFC62828);
  static const orange = Color(0xFFE07A1F);
  static const gold = Color(0xFFC79A12);
  static const ink = Color(0xFF1C1C28);
  static const muted = Color(0xFF8A8A99);
  static const line = Color(0xFFE6E6EF);

  /// Diagonal gradient used on the role-select + dashboard grid panels.
  static const panelGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E3D8F),
      Color(0xFF4A2F8F),
      Color(0xFF8A1F8F),
      Color(0xFFC21F75),
      Color(0xFFE01E8A),
      Color(0xFFC2185B),
    ],
    stops: [0.0, 0.14, 0.30, 0.48, 0.66, 0.84],
  );

  static const purpleHeaderGradient = LinearGradient(
    colors: [purple, Color(0xFFA5227E)],
  );

  static const blueHeaderGradient = LinearGradient(
    colors: [blueDark, Color(0xFF1C56A8)],
  );

  static const footerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD62285),
      Color(0xFFC13584),
      Color(0xFF853587),
      Color(0xFF00558C),
    ],
  );
}

/// Shared text sizes referenced across the notification/salary-detail
/// screens, so those font sizes stay in one place instead of being
/// re-guessed per screen.
class AppTextStyles {
  static const double headingSize = 16;
  static const double bodySize = 14;
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.maroon),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.maroon,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
