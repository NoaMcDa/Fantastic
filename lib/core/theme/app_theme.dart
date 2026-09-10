import 'package:flutter/material.dart';

/// App-wide colour tokens and the dark theme built from them.
///
/// Values match `design/ui_ux_design.md`'s colour palette exactly — no
/// hardcoded colour value should appear anywhere outside this class.
abstract final class AppTheme {
  static const Color primary = Color(0xFF1C1C1E);
  static const Color surface = Color(0xFF2C2C2E);
  static const Color accent = Color(0xFFF5A623);
  static const Color success = Color(0xFF30D158);
  static const Color caution = Color(0xFFFFD60A);
  static const Color danger = Color(0xFFFF453A);

  static ThemeData get dark => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: primary,
    colorScheme: const ColorScheme.dark(
      primary: accent,
      surface: surface,
      error: danger,
    ),
  );
}
