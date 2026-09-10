import 'package:fantastic/core/router/app_shell.dart';
import 'package:fantastic/features/adaptation/presentation/adaptation_placeholder.dart';
import 'package:fantastic/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:fantastic/features/diary/presentation/screens/diary_screen.dart';
import 'package:fantastic/features/directory/presentation/directory_placeholder.dart';
import 'package:fantastic/features/keto_lens/presentation/keto_lens_placeholder.dart';
import 'package:fantastic/features/onboarding/presentation/onboarding_placeholder.dart';
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
          builder: (_, _) => const AdaptationPlaceholder(),
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
      builder: (_, state) =>
          OnboardingPlaceholder(step: onboardingStep(state.pathParameters)),
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

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('עמוד לא נמצא')));
  }
}
