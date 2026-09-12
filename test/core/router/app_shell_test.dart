import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/core/router/app_shell.dart';
import 'package:fantastic/main.dart';
import 'package:fantastic/features/onboarding/presentation/onboarding_placeholder.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen1.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen2.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen3.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen4.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/onboarding_gate_override.dart';

import '../../fixtures/fixtures.dart';

void main() {
  group('AppShell.activeIndexForLocation', () {
    test('matches each of the 6 tab paths exactly', () {
      expect(AppShell.activeIndexForLocation('/'), 0);
      expect(AppShell.activeIndexForLocation('/lens'), 1);
      expect(AppShell.activeIndexForLocation('/diary'), 2);
      expect(AppShell.activeIndexForLocation('/adaptation'), 3);
      expect(AppShell.activeIndexForLocation('/recipe'), 4);
      expect(AppShell.activeIndexForLocation('/profile'), 5);
    });

    test('a sub-route of a tab keeps that tab active', () {
      expect(AppShell.activeIndexForLocation('/diary/2026-09-09'), 2);
      expect(AppShell.activeIndexForLocation('/adaptation/detail'), 3);
    });

    // #120's two child routes — no change to `activeIndexForLocation` itself
    // was needed, and this is what proves that rather than assuming it.
    test(
      '/recipe/library and /recipe/saved/1 both activate the recipe tab',
      () {
        expect(AppShell.activeIndexForLocation('/recipe/library'), 4);
        expect(AppShell.activeIndexForLocation('/recipe/saved/1'), 4);
      },
    );

    // #364: `/lens/menu` is a child route of `/lens`, registered so the tab
    // bar stays — this is what makes that true.
    test('the menu scanner route keeps the lens tab active', () {
      expect(AppShell.activeIndexForLocation(kMenuScannerPath), 1);
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
    testWidgets('renders a NavigationBar with 6 destinations', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [completedOnboardingGate()],
          child: const FantasticApp(),
        ),
      );
      await tester.pumpAndSettle();

      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navigationBar.destinations, hasLength(6));
      expect(navigationBar.selectedIndex, 0);
    });

    testWidgets('tapping the already-active tab does not change the route', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [completedOnboardingGate()],
          child: const FantasticApp(),
        ),
      );
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
    test('every step is a real screen', () {
      expect(onboardingScreen(1, null), isA<OnboardingScreen1>());
      expect(onboardingScreen(2, null), isA<OnboardingScreen2>());
      expect(
        onboardingScreen(3, UserProfileFixture.partial()),
        isA<OnboardingScreen3>(),
      );
      expect(
        onboardingScreen(4, UserProfileFixture.data()),
        isA<OnboardingScreen4>(),
      );
    });

    // Unreachable through the route, which redirects such a step to the
    // start of the flow — but the fall-through must still be a screen
    // rather than a crash.
    test('a step with the wrong data falls through to the placeholder', () {
      expect(onboardingScreen(3, null), isA<OnboardingPlaceholder>());
      expect(
        onboardingScreen(4, UserProfileFixture.partial()),
        isA<OnboardingPlaceholder>(),
      );
    });
  });

  // A deep link, or a browser reload — `extra` is not serialisable, so a
  // reload mid-flow arrives at step 3 or 4 with nothing.
  group('onboardingStepHasData', () {
    test('steps 1 and 2 need nothing', () {
      expect(onboardingStepHasData(1, null), isTrue);
      expect(onboardingStepHasData(2, null), isTrue);
    });

    test('step 3 needs the screen-2 answers', () {
      expect(onboardingStepHasData(3, null), isFalse);
      expect(onboardingStepHasData(3, 'nonsense'), isFalse);
      expect(onboardingStepHasData(3, UserProfileFixture.partial()), isTrue);
    });

    test('step 4 needs the complete answers, not the partial ones', () {
      expect(onboardingStepHasData(4, null), isFalse);
      expect(onboardingStepHasData(4, UserProfileFixture.partial()), isFalse);
      expect(onboardingStepHasData(4, UserProfileFixture.data()), isTrue);
    });
  });
}
