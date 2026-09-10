import 'package:fantastic/core/router/app_shell.dart';
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
        GoRoute(path: '/', builder: (_, _) => const _InterimTab('בית')),
        GoRoute(path: '/lens', builder: (_, _) => const _InterimTab('מצלמה')),
        GoRoute(path: '/diary', builder: (_, _) => const _InterimTab('יומן')),
        GoRoute(
          path: '/adaptation',
          builder: (_, _) => const _InterimTab('התאמה'),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, _) => const _InterimTab('פרופיל'),
        ),
      ],
    ),
  ],
  errorBuilder: (_, _) => const _InterimTab('עמוד לא נמצא'),
);

/// Temporary per-tab screen for issue #17, standing in for the real
/// per-feature placeholder screens (issue #22) until they land. Private
/// to this file; #22 replaces each route's `builder:` with the real
/// placeholder widget.
class _InterimTab extends StatelessWidget {
  const _InterimTab(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(label)));
  }
}
