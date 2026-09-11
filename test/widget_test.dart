import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen1.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen2.dart';
import 'package:fantastic/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Which tab the shell currently shows as active.
///
/// Read from the `NavigationBar` rather than by counting how many times a tab
/// label appears. The old count-of-2 assertion relied on each tab's body being
/// a placeholder whose text happened to equal its label — which stopped being
/// true the moment #49 replaced the dashboard placeholder with a real screen,
/// and will stop being true for each remaining tab as M3-M6 replace theirs.
int activeTabIndex(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

void main() {
  testWidgets('sets RTL direction at the app root, inherited by nested '
      'Scaffolds', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.text('בית').first)),
      TextDirection.rtl,
    );
  });

  testWidgets('applies the dark theme with AppTheme colour tokens', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme!.scaffoldBackgroundColor, AppTheme.primary);
    expect(materialApp.theme!.colorScheme.primary, AppTheme.accent);
    expect(materialApp.theme!.colorScheme.surface, AppTheme.surface);
    expect(materialApp.theme!.colorScheme.error, AppTheme.danger);
  });

  testWidgets('renders the dashboard tab at the initial route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    expect(activeTabIndex(tester), 0);
    expect(find.byType(DashboardScreen), findsOneWidget);
  });

  testWidgets('every one of the 5 tab routes navigates without error', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.text('בית').first));

    const routesAndLabels = {
      '/': 'בית',
      '/lens': 'מצלמה',
      '/diary': 'יומן',
      '/adaptation': 'התאמה',
      '/profile': 'פרופיל',
    };

    var index = 0;
    for (final entry in routesAndLabels.entries) {
      router.go(entry.key);
      await tester.pumpAndSettle();
      expect(
        activeTabIndex(tester),
        index,
        reason: '${entry.key} should activate the ${entry.value} tab',
      );
      expect(tester.takeException(), isNull);
      index++;
    }
  });

  testWidgets('an unknown route falls through to the error screen, not a '
      'crash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.text('בית').first));
    router.go('/does-not-exist');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the 3 deferred-feature routes (outside the tab shell) render their '
    'placeholders',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
      await tester.pumpAndSettle();

      final router = GoRouter.of(tester.element(find.text('בית').first));

      const routesAndLabels = {
        '/restaurants': 'מסעדות',
        '/recipe': 'מתכונים',
        '/directory': 'ספרייה',
      };

      for (final entry in routesAndLabels.entries) {
        router.go(entry.key);
        await tester.pumpAndSettle();
        // Only 1 match: these routes sit outside the ShellRoute, so no
        // NavigationBar (and no second, tab-label match) wraps them.
        expect(find.text(entry.value), findsOneWidget);
      }
    },
  );

  testWidgets('each of the 4 onboarding routes renders a screen', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.text('בית').first));

    // Steps 1 and 2 are real screens (#69, #70) and need no navigation
    // data. Every step must resolve to *something* — a step that fell
    // through to the error screen would break the flow for a deep link.
    router.go('/onboarding/1');
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen1), findsOneWidget);

    router.go('/onboarding/2');
    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen2), findsOneWidget);
  });

  // Screens 3 and 4 take the earlier answers as required arguments, and
  // `extra` does not survive a browser reload or a cold deep link. Rather
  // than crash, the flow restarts — the same policy `onboardingStep`
  // already applies to an out-of-range step.
  testWidgets('a later onboarding step reached with no data restarts the '
      'flow', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.text('בית').first));

    for (var step = 3; step <= kOnboardingStepCount; step++) {
      router.go('/onboarding/$step');
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingScreen1), findsOneWidget);
      expect(
        router.routerDelegate.currentConfiguration.uri.toString(),
        '/onboarding/1',
      );
    }
  });

  testWidgets('onboarding renders outside the tab shell, with no '
      'NavigationBar', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.text('בית').first));
    router.go('/onboarding/1');
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('/dashboard redirects to the dashboard tab at /', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.text('בית').first));
    router.go('/lens');
    await tester.pumpAndSettle();

    router.go('/dashboard');
    await tester.pumpAndSettle();

    // The dashboard tab is active inside the shell — the redirect landed on
    // '/', not on a second, parallel dashboard route.
    expect(activeTabIndex(tester), 0);
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
