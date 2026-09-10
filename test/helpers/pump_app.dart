import 'package:fantastic/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
// `Override` is not among the symbols `flutter_riverpod` 3.0.3 re-exports,
// even though `ProviderScope.overrides` is typed `List<Override>`.
// `riverpod_annotation` does export it and is already a direct dependency, so
// this avoids adding `riverpod` itself just to name a parameter type.
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Pumps [widget] inside the same shell `FantasticApp` gives it at runtime.
///
/// Every M2 widget is Hebrew and right-to-left, reads Riverpod providers, and
/// uses `Theme.of(context)` for its text styles. Pumping a bare widget instead
/// would test it under defaults it never actually runs with — an LTR direction
/// and a light theme — so a widget that only lays out correctly in RTL, or a
/// colour that only reads on the dark palette, would pass here and fail on
/// device.
///
/// [overrides] replaces providers with test doubles, which is how a widget
/// test supplies data without a database.
Future<void> pumpApp(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.dark,
        locale: const Locale('he'),
        supportedLocales: const [Locale('he'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: widget),
        ),
      ),
    ),
  );
}
