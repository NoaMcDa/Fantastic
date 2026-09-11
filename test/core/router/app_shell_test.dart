import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/core/router/app_shell.dart';
import 'package:fantastic/main.dart';
import 'package:fantastic/features/onboarding/presentation/onboarding_placeholder.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen1.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppShell.activeIndexForLocation', () {
    test('matches each of the 5 tab paths exactly', () {
      expect(AppShell.activeIndexForLocation('/'), 0);
      expect(AppShell.activeIndexForLocation('/lens'), 1);
      expect(AppShell.activeIndexForLocation('/diary'), 2);
      expect(AppShell.activeIndexForLocation('/adaptation'), 3);
      expect(AppShell.activeIndexForLocation('/profile'), 4);
    });

    test('a sub-route of a tab keeps that tab active', () {
      expect(AppShell.activeIndexForLocation('/diary/2026-09-09'), 2);
      expect(AppShell.activeIndexForLocation('/adaptation/detail'), 3);
    });

    test('an unrecognised location defaults to index 0 (Home)', () {
      expect(AppShell.activeIndexForLocation('/does-not-exist'), 0);
    });

    test('the root path does not swallow every other tab', () {
      // A naive `location.startsWith('/')` check for every path would
      // match '/' first for any location, since every path starts with
      // '/'. Confirms that isn't happening.
      expect(AppShell.activeIndexForLocation('/lens'), isNot(0));
    });
  });

  group('AppShell widget', () {
    testWidgets('renders a NavigationBar with 5 destinations', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
      await tester.pumpAndSettle();

      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navigationBar.destinations, hasLength(5));
      expect(navigationBar.selectedIndex, 0);
    });

    testWidgets('tapping the already-active tab does not change the route', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
      await tester.pumpAndSettle();

      final routerBefore = ProviderScope.containerOf(
        tester.element(find.byType(NavigationBar)),
      ).read(appRouterProvider);
      final locationBefore = routerBefore
          .routerDelegate
          .currentConfiguration
          .uri
          .toString();

      await tester.tap(find.text('בית').first);
      await tester.pumpAndSettle();

      final locationAfter = routerBefore.routerDelegate.currentConfiguration.uri
          .toString();
      expect(locationAfter, locationBefore);
    });
  });

  group('onboardingStep', () {
    test('returns the step for each of the 4 real screens', () {
      for (var step = 1; step <= kOnboardingStepCount; step++) {
        expect(onboardingStep({'step': '$step'}), step);
      }
    });

    test('falls back to step 1 for a step above the flow length', () {
      expect(onboardingStep({'step': '9'}), 1);
    });

    test('falls back to step 1 for a zero or negative step', () {
      expect(onboardingStep({'step': '0'}), 1);
      expect(onboardingStep({'step': '-2'}), 1);
    });

    test('falls back to step 1 for a non-numeric or missing step', () {
      expect(onboardingStep({'step': 'abc'}), 1);
      expect(onboardingStep(const {}), 1);
    });
  });

  group('onboardingScreen', () {
    test('step 1 is the real welcome screen', () {
      expect(onboardingScreen(1), isA<OnboardingScreen1>());
    });

    // The flow stays reachable end to end while M4 is being built: a step
    // whose screen has not landed yet still renders the placeholder rather
    // than a blank route.
    test('a step M4 has not replaced yet still renders', () {
      for (var step = 2; step <= kOnboardingStepCount; step++) {
        expect(onboardingScreen(step), isA<OnboardingPlaceholder>());
      }
    });
  });
}
