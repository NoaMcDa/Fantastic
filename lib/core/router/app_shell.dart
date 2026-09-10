import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Persistent bottom tab bar shell for the app's 5 MVP tabs, rendered by
/// the `ShellRoute` in `app_router.dart`.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _labels = ['בית', 'מצלמה', 'יומן', 'התאמה', 'פרופיל'];
  static const _icons = [
    Icons.home,
    Icons.camera_alt,
    Icons.book,
    Icons.trending_up,
    Icons.person,
  ];

  /// Index of the tab whose path prefixes [location]. The root path ('/')
  /// only matches itself — otherwise it would swallow every other tab,
  /// since every path starts with '/'. Falls back to 0 (Home) for an
  /// unrecognised location.
  @visibleForTesting
  static int activeIndexForLocation(String location) {
    final index = kTabPaths.indexWhere(
      (path) => path == '/' ? location == '/' : location.startsWith(path),
    );
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final activeIndex = activeIndexForLocation(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeIndex,
        indicatorColor: AppTheme.accent.withValues(alpha: 0.24),
        onDestinationSelected: (index) => context.go(kTabPaths[index]),
        destinations: [
          for (var i = 0; i < kTabPaths.length; i++)
            NavigationDestination(
              icon: Icon(_icons[i]),
              selectedIcon: Icon(_icons[i], color: AppTheme.accent),
              label: _labels[i],
            ),
        ],
      ),
    );
  }
}
