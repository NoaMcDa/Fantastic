import 'package:fantastic/core/router/app_shell.dart';
import 'package:fantastic/features/adaptation/presentation/screens/phase_detail_screen.dart';
import 'package:fantastic/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:fantastic/features/diary/presentation/screens/diary_screen.dart';
import 'package:fantastic/features/directory/presentation/directory_placeholder.dart';
import 'package:fantastic/features/keto_lens/presentation/screens/camera_screen.dart';
import 'package:fantastic/features/onboarding/presentation/onboarding_placeholder.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen1.dart';
import 'package:fantastic/features/onboarding/application/providers/onboarding_gate.dart';
import 'package:fantastic/features/onboarding/domain/models/onboarding_data.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen2.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen3.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen4.dart';
import 'package:fantastic/features/profile/presentation/screens/profile_screen.dart';
import 'package:fantastic/features/recipe/presentation/screens/recipe_converter_screen.dart';
import 'package:fantastic/features/recipe/presentation/screens/recipe_library_screen.dart';
import 'package:fantastic/features/recipe/presentation/screens/saved_recipe_loader.dart';
import 'package:fantastic/features/restaurant/presentation/restaurant_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// The 6 tab routes, in tab-bar order.
///
/// Kept here (not duplicated elsewhere) so nothing outside this file
/// hard-codes a route string, per the issue's Definition of Done. Only the
/// first 5 are MVP; `kRecipePath` (#119) is the first post-MVP tab,
/// inserted before Profile — which stays last by platform convention.
const List<String> kTabPaths = [
  '/',
  '/lens',
  '/diary',
  '/adaptation',
  kRecipePath,
  kProfilePath,
];

/// The Profile tab's path.
///
/// Named because something outside the tab bar now navigates to it: the
/// estimation failures that say "sort the key out" take the user there, and
/// `kTabPaths` is a positional list rather than something to index by hand.
const String kProfilePath = '/profile';

/// The Recipe Converter tab's path (#119). Named for the same reason as
/// [kProfilePath] — nothing outside this file should spell `/recipe` by
/// hand.
const String kRecipePath = '/recipe';

/// Number of screens in the onboarding flow (#69–#72).
const int kOnboardingStepCount = 4;

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) => GoRouter(
  // '/' and not '#74''s `initialLocation: '/dashboard'`: the tab shell
  // registers the dashboard at '/', `kTabPaths` lists it, and AppShell's
  // active-tab matching keys on it. '/dashboard' exists only as an alias
  // that redirects here (`design/m4_preflight.md` §5.2).
  initialLocation: '/',
  // The first-launch gate (#74). Synchronous, and reading a value seeded
  // before `runApp` — see `OnboardingGate` for why an awaited redirect
  // cannot ship.
  //
  // The second clause is not in the issue and is needed: without it a
  // returning user who deep-links into the flow runs it again and
  // overwrites the targets they already set.
  redirect: (_, state) {
    final completed = ref.read(onboardingGateProvider);
    final onOnboarding = state.matchedLocation.startsWith('/onboarding');
    if (!completed && !onOnboarding) {
      return '/onboarding/1';
    }
    if (completed && onOnboarding) {
      return '/';
    }
    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
        GoRoute(path: '/lens', builder: (_, _) => const CameraScreen()),
        GoRoute(path: '/diary', builder: (_, _) => const DiaryScreen()),
        GoRoute(
          path: '/adaptation',
          builder: (_, _) => const PhaseDetailScreen(),
          routes: [
            // #64's badge pushes '/adaptation/phase'. The tab already *is*
            // the phase screen, so rather than registering a second copy
            // outside the shell — which would lose the tab bar and stack a
            // duplicate on top of itself — the child path redirects onto the
            // tab. Kept as a child route so AppShell's prefix matching still
            // resolves it to the adaptation tab.
            GoRoute(path: 'phase', redirect: (_, _) => '/adaptation'),
          ],
        ),
        // The sixth tab (#119) — moved inside the `ShellRoute` so it renders
        // with the tab bar still on screen, unlike the deferred placeholders
        // below. Inserted before `kProfilePath`, matching `kTabPaths`.
        GoRoute(
          path: kRecipePath,
          builder: (_, _) => const RecipeConverterScreen(),
          routes: [
            // Both children are relative paths — `'library'`, not
            // `'/library'` — and both stay inside the `ShellRoute` as a
            // result, mirroring `/adaptation`'s `phase` child. A leading
            // slash would make either top-level and lose the tab bar.
            // `AppShell.activeIndexForLocation` matches on
            // `startsWith('/recipe')`, so both light the recipe tab with no
            // change to that method — see `app_shell_test.dart`.
            GoRoute(
              path: 'library',
              builder: (_, _) => const RecipeLibraryScreen(),
            ),
            GoRoute(
              path: 'saved/:id',
              // A missing or non-numeric id becomes null here, never a
              // throw — `SavedRecipeLoader` renders the empty converter
              // with a notice rather than crashing on a bad deep link.
              builder: (_, state) => SavedRecipeLoader(
                id: int.tryParse(state.pathParameters['id'] ?? ''),
              ),
            ),
          ],
        ),
        GoRoute(path: kProfilePath, builder: (_, _) => const ProfileScreen()),
      ],
    ),
    // Deferred v1.1 features (design/architecture.md's fuller route table),
    // scaffolded here per the Epic's "all 7 feature directories" scope but
    // deliberately outside the ShellRoute — they aren't MVP tabs.
    GoRoute(
      path: '/restaurants',
      builder: (_, _) => const RestaurantPlaceholder(),
    ),
    GoRoute(
      path: '/directory',
      builder: (_, _) => const DirectoryPlaceholder(),
    ),
    // Onboarding is MVP feature 4, but the tab-bar issue registered no route
    // for it, so #69–#74 were written against paths that did not exist.
    // Deliberately outside the ShellRoute: the flow is full-screen, with no
    // tab bar. #69–#72 replace the placeholder with the real screens.
    GoRoute(
      path: '/onboarding/:step',
      // Screens 3 and 4 are pushed with the previous screens' answers in
      // `extra`, and a step reached without them cannot render. Rather than
      // crash on a deep link — or on a browser reload, which drops `extra`
      // because it is not serialisable — the flow restarts at step 1. Same
      // policy as `onboardingStep`'s clamp, for the same reason.
      redirect: (_, state) =>
          onboardingStepHasData(
            onboardingStep(state.pathParameters),
            state.extra,
          )
          ? null
          : '/onboarding/1',
      builder: (_, state) =>
          onboardingScreen(onboardingStep(state.pathParameters), state.extra),
    ),
    // Downstream issues address the dashboard as '/dashboard' (see #74's
    // `initialLocation`), while the tab shell registers it as '/'. Keep '/'
    // canonical — AppShell's active-tab matching depends on it — and alias
    // '/dashboard' onto it so both spellings resolve.
    GoRoute(path: '/dashboard', redirect: (_, _) => '/'),
  ],
  errorBuilder: (_, _) => const _NotFoundScreen(),
);

/// Onboarding step from a route's path parameters, clamped to a screen that
/// exists.
///
/// An out-of-range or non-numeric step falls back to the first screen rather
/// than throwing — a bad deep link should start the flow, not crash the app.
@visibleForTesting
int onboardingStep(Map<String, String> pathParameters) {
  final parsed = int.tryParse(pathParameters['step'] ?? '');
  if (parsed == null || parsed < 1 || parsed > kOnboardingStepCount) {
    return 1;
  }
  return parsed;
}

/// Whether [step] can be rendered with the [extra] it was navigated with.
///
/// Screens 3 and 4 take the previous screens' answers as required
/// constructor arguments, so a step reached without them has nothing to
/// build. The route redirects such a step to the start of the flow.
@visibleForTesting
bool onboardingStepHasData(int step, Object? extra) => switch (step) {
  3 => extra is PartialOnboardingData,
  4 => extra is OnboardingData,
  _ => true,
};

/// The screen for a 1-based onboarding [step], given its navigation [extra].
///
/// A switch rather than four `GoRoute`s because the flow is one route with a
/// path parameter, which is what `#69`-`#72` were written against. Steps the
/// milestone has not replaced yet still render `OnboardingPlaceholder`, so
/// the flow stays reachable end to end while it is being built.
///
/// A step whose `extra` is missing or of the wrong type falls through to the
/// placeholder here, but the route's `redirect` means it is never actually
/// reached — the two are kept consistent by
/// `onboardingStepHasData`.
@visibleForTesting
Widget onboardingScreen(int step, Object? extra) => switch (step) {
  1 => const OnboardingScreen1(),
  2 => const OnboardingScreen2(),
  3 when extra is PartialOnboardingData => OnboardingScreen3(partial: extra),
  4 when extra is OnboardingData => OnboardingScreen4(data: extra),
  _ => OnboardingPlaceholder(step: step),
};

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('עמוד לא נמצא')));
  }
}
