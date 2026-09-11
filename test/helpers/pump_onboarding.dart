import 'package:fantastic/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// Where the last `context.push` or `context.go` inside a pumped onboarding
/// screen landed, or null if nothing navigated.
///
/// Reset by every [pumpOnboarding] call, so a test never reads a value left
/// behind by the previous one.
String? lastPushedLocation;

/// Pumps an onboarding screen inside a real router.
///
/// `pump_app.dart` puts its widget in a bare `Scaffold`, which is right for a
/// card or a list but not for a screen whose entire job is to navigate: a
/// `context.push` there throws for want of a `GoRouter` ancestor. This gives
/// the screen a router with a catch-all route that records where it was sent
/// and renders a marker, so a navigation assertion needs no second screen to
/// exist yet.
///
/// The RTL `Directionality`, the dark theme and the Hebrew locale match what
/// `FantasticApp` supplies at runtime, for the same reason `pumpApp` does.
Future<void> pumpOnboarding(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
  Object? extra,
}) async {
  lastPushedLocation = null;

  final router = GoRouter(
    initialLocation: '/start',
    routes: [
      GoRoute(path: '/start', builder: (_, _) => screen),
      GoRoute(
        path: '/:a',
        builder: (_, state) => _record(state),
        routes: [GoRoute(path: ':b', builder: (_, state) => _record(state))],
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.dark,
        locale: const Locale('he'),
        supportedLocales: const [Locale('he'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Where the last navigation landed, and what it carried.
Object? lastPushedExtra;

Widget _record(GoRouterState state) {
  lastPushedLocation = state.uri.toString();
  lastPushedExtra = state.extra;
  return const Scaffold(body: Center(child: Text('navigated')));
}
