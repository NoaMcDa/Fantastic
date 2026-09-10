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

  /// The bundled UI face, from `design/design_system.md` §Typography.
  ///
  /// Named here rather than left to the platform default because the web
  /// renderer carries no Hebrew glyphs: without an explicit family the app
  /// falls back to downloading one from Google Fonts on first paint, and every
  /// Hebrew string renders as tofu boxes until — or unless — that request
  /// succeeds. Assistant covers Hebrew and Latin in one family, so the same
  /// text renders identically on iOS and in a browser.
  static const String fontFamily = 'Assistant';

  static ThemeData get dark => ThemeData.dark().copyWith(
    scaffoldBackgroundColor: primary,
    textTheme: ThemeData.dark().textTheme.apply(fontFamily: fontFamily),
    primaryTextTheme: ThemeData.dark().primaryTextTheme.apply(
      fontFamily: fontFamily,
    ),
    colorScheme: const ColorScheme.dark(
      primary: accent,
      surface: surface,
      error: danger,
    ),
  );
}
