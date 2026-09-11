import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:fantastic/features/onboarding/application/providers/onboarding_gate.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen1.dart';
import 'package:fantastic/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/onboarding_gate_override.dart';

/// The first-launch gate, exercised through the real router (#74).
void main() {
  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
        listen: false,
      );

  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required bool completed,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: completed ? [completedOnboardingGate()] : const [],
        child: const FantasticApp(),
      ),
    );
    await tester.pumpAndSettle();
    // Read from the provider rather than `GoRouter.of`: the inherited
    // widget lives below `MaterialApp.router`, and which screen is mounted
    // is exactly what these tests are trying to find out.
    return containerOf(tester).read(appRouterProvider);
  }

  String locationOf(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  group('a first launch', () {
    testWidgets('redirects the initial route into the flow', (tester) async {
      final router = await pumpApp(tester, completed: false);

      expect(locationOf(router), '/onboarding/1');
      expect(find.byType(OnboardingScreen1), findsOneWidget);
    });

    testWidgets('redirects any tab away from itself', (tester) async {
      final router = await pumpApp(tester, completed: false);

      for (final path in kTabPaths) {
        router.go(path);
        await tester.pumpAndSettle();

        expect(locationOf(router), '/onboarding/1', reason: 'from $path');
      }
    });

    // The loop #74 warns about: the redirect must let an onboarding route
    // through, or every step bounces back to step 1 and the flow cannot be
    // walked.
    testWidgets('does not loop while inside the flow', (tester) async {
      final router = await pumpApp(tester, completed: false);

      router.go('/onboarding/2');
      await tester.pumpAndSettle();

      expect(locationOf(router), '/onboarding/2');
    });
  });

  group('a returning user', () {
    testWidgets('lands on the dashboard, not the flow', (tester) async {
      final router = await pumpApp(tester, completed: true);

      expect(locationOf(router), '/');
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('reaches every tab without being redirected', (tester) async {
      final router = await pumpApp(tester, completed: true);

      for (final path in kTabPaths) {
        router.go(path);
        await tester.pumpAndSettle();

        expect(locationOf(router), path);
      }
    });

    // Not in #74, and needed: without it a deep link back into the flow
    // re-runs it and overwrites the targets the user already set.
    testWidgets('is redirected out of the onboarding flow', (tester) async {
      final router = await pumpApp(tester, completed: true);

      router.go('/onboarding/1');
      await tester.pumpAndSettle();

      expect(locationOf(router), '/');
    });
  });

  // What actually flips the gate mid-session. Nothing else in the app does,
  // and #74's plan — `OnboardingService` calling `ref.invalidate` — cannot:
  // the service holds no `Ref`.
  testWidgets('opening the gate mid-session lets the dashboard through', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();
    final container = containerOf(tester);
    final router = container.read(appRouterProvider);
    expect(locationOf(router), '/onboarding/1');

    container.read(onboardingGateProvider.notifier).markCompleted();
    router.go('/');
    await tester.pumpAndSettle();

    expect(locationOf(router), '/');
    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
