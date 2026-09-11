import 'package:fantastic/core/router/app_shell.dart';
import 'package:fantastic/features/adaptation/presentation/screens/phase_detail_screen.dart';
import 'package:fantastic/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:fantastic/features/diary/presentation/screens/diary_screen.dart';
import 'package:fantastic/features/directory/presentation/directory_placeholder.dart';
import 'package:fantastic/features/keto_lens/presentation/keto_lens_placeholder.dart';
import 'package:fantastic/features/onboarding/presentation/onboarding_placeholder.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen1.dart';
import 'package:fantastic/features/onboarding/domain/models/onboarding_data.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen2.dart';
import 'package:fantastic/features/onboarding/presentation/screens/onboarding_screen3.dart';
import 'package:fantastic/features/profile/presentation/profile_placeholder.dart';
import 'package:fantastic/features/recipe/presentation/recipe_placeholder.dart';
import 'package:fantastic/features/restaurant/presentation/restaurant_placeholder.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// The 5 MVP tab routes, in tab-bar order.
///
/// Kept here (not duplicated elsewhere) so nothing outside this file
/// hard-codes a route string, per the issue's Definition of Done.
const List<String> kTabPaths = [
  '/',
  '/lens',
  '/diary',
  '/adaptation',
  '/profile',
];

/// Number of screens in the onboarding flow (#69–#72).
const int kOnboardingStepCount = 4;

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) => GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DashboardScreen()),
        GoRoute(path: '/lens', builder: (_, _) => const KetoLensPlaceholder()),
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
        GoRoute(
          path: '/profile',
          builder: (_, _) => const ProfilePlaceholder(),
        ),
      ],
    ),
    // Deferred v1.1 features (design/architecture.md's fuller route table),
    // scaffolded here per the Epic's "all 7 feature directories" scope but
    // deliberately outside the ShellRoute — they aren't MVP tabs.
    GoRoute(
      path: '/restaurants',
      builder: (_, _) => const RestaurantPlaceholder(),
    ),
    GoRoute(path: '/recipe', builder: (_, _) => const RecipePlaceholder()),
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
  _ => OnboardingPlaceholder(step: step),
};

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('עמוד לא נמצא')));
  }
}
