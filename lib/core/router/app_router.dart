import 'package:fantastic/core/router/app_shell.dart';
import 'package:fantastic/features/adaptation/presentation/adaptation_placeholder.dart';
import 'package:fantastic/features/dashboard/presentation/dashboard_placeholder.dart';
import 'package:fantastic/features/diary/presentation/diary_placeholder.dart';
import 'package:fantastic/features/directory/presentation/directory_placeholder.dart';
import 'package:fantastic/features/keto_lens/presentation/keto_lens_placeholder.dart';
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

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) => GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const DashboardPlaceholder()),
        GoRoute(path: '/lens', builder: (_, _) => const KetoLensPlaceholder()),
        GoRoute(path: '/diary', builder: (_, _) => const DiaryPlaceholder()),
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
  ],
  errorBuilder: (_, _) => const _NotFoundScreen(),
);

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('עמוד לא נמצא')));
  }
}
