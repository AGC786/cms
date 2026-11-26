import 'package:flutter/material.dart';

/// App Theme Colors
class AppColors {
  AppColors._();

  // Brand Colors
  static const maroonBtn = Color(0xFF8C1848);
  static const maroonDk = Color(0xFF6E1236);
  static const magenta = Color(0xFFC31E73);
  static const blueMid = Color(0xFF1C4FA0);
  static const blueDk = Color(0xFF0E3F78);
  static const purple = Color(0xFF6A2F8F);
  static const green = Color(0xFF1E8A3C);
  static const red = Color(0xFFC62828);
  static const orange = Color(0xFFE07A1F);
  static const gold = Color(0xFFC79A12);

  static const ink = Color(0xFF1C1C28);
  static const muted = Color(0xFF8A8A99);
  static const line = Color(0xFFE6E6EF);

  static const scaffoldBg = Color(0xFFF8F8FA);
  static const statusBar = Color(0xFF0D0D14);

  /// Header Background gradient starting from top-right.
  static const heroGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF1653B5),
      Color(0xFF3163C4),
      Color(0xFF7C3AB6),
      Color(0xFFB83597),
    ],
    stops: [0.0, 0.3, 0.68, 1.0],
  );

  /// Main card / role panel gradient.
  static const roleGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF1F5ABE),
      Color(0xFF4B339C),
      Color(0xFF8A2E9A),
      Color(0xFFC5298A),
    ],
  );

  /// Footer accent gradient — matches the splash screen's URL bar.
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

  /// Logo Ring
  static const crestGradient = SweepGradient(
    colors: [
      Color(0xFF1C7A3D),
      Color(0xFF2FAE56),
      Color(0xFF1C7A3D),
    ],
  );
}