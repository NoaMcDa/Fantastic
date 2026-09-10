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
      builder: (context, state, child) => _InterimShell(child: child),
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

/// Temporary shell for issue #17, standing in for the real `AppShell`
/// (issue #19) until it lands. Deliberately minimal — no nav-bar chrome,
/// just enough of a tab switcher to prove all 5 routes are reachable.
/// Private to this file; #19 replaces this `builder:` with `AppShell`.
class _InterimShell extends StatelessWidget {
  const _InterimShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final path in kTabPaths)
              TextButton(onPressed: () => context.go(path), child: Text(path)),
          ],
        ),
      ),
    );
  }
}

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
