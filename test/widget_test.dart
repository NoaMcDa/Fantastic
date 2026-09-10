import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('sets RTL direction at the app root, inherited by nested '
      'Scaffolds', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    expect(
      Directionality.of(tester.element(find.text('בית').first)),
      TextDirection.rtl,
    );
  });

  testWidgets('applies the dark theme with AppTheme colour tokens', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme!.scaffoldBackgroundColor, AppTheme.primary);
    expect(materialApp.theme!.colorScheme.primary, AppTheme.accent);
    expect(materialApp.theme!.colorScheme.surface, AppTheme.surface);
    expect(materialApp.theme!.colorScheme.error, AppTheme.danger);
  });

  testWidgets('renders the dashboard tab at the initial route', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    // 2 matches for the active tab: the NavigationBar's label plus the
    // placeholder screen's body. Every other tab's label still shows in
    // the bar even when inactive, so this is what distinguishes "active"
    // from "just listed in the tab bar".
    expect(find.text('בית'), findsNWidgets(2));
  });

  testWidgets('every one of the 5 tab routes navigates without error', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.text('בית').first));

    const routesAndLabels = {
      '/': 'בית',
      '/lens': 'מצלמה',
      '/diary': 'יומן',
      '/adaptation': 'התאמה',
      '/profile': 'פרופיל',
    };

    for (final entry in routesAndLabels.entries) {
      router.go(entry.key);
      await tester.pumpAndSettle();
      expect(find.text(entry.value), findsNWidgets(2));
    }
  });

  testWidgets('an unknown route falls through to the error screen, not a '
      'crash', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.text('בית').first));
    router.go('/does-not-exist');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'the 3 deferred-feature routes (outside the tab shell) render their '
    'placeholders',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: FantasticApp()));
      await tester.pumpAndSettle();

      final router = GoRouter.of(tester.element(find.text('בית').first));

      const routesAndLabels = {
        '/restaurants': 'מסעדות',
        '/recipe': 'מתכונים',
        '/directory': 'ספרייה',
      };

      for (final entry in routesAndLabels.entries) {
        router.go(entry.key);
        await tester.pumpAndSettle();
        // Only 1 match: these routes sit outside the ShellRoute, so no
        // NavigationBar (and no second, tab-label match) wraps them.
        expect(find.text(entry.value), findsOneWidget);
      }
    },
  );
}
