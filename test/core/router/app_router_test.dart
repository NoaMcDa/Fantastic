import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/features/recipe/presentation/screens/recipe_converter_screen.dart';
import 'package:fantastic/features/recipe/presentation/screens/recipe_library_screen.dart';
import 'package:fantastic/features/recipe/presentation/screens/saved_recipe_loader.dart';
import 'package:fantastic/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/onboarding_gate_override.dart';

/// #119 — `/recipe` inside the `ShellRoute` as the sixth tab.
void main() {
  testWidgets('/recipe renders RecipeConverterScreen inside the shell', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [completedOnboardingGate()],
        child: const FantasticApp(),
      ),
    );
    await tester.pumpAndSettle();

    final router = GoRouter.of(tester.element(find.text('בית').first));
    router.go(kRecipePath);
    await tester.pumpAndSettle();

    expect(find.byType(RecipeConverterScreen), findsOneWidget);
    // Still inside the shell — the tab bar is still on screen, unlike the
    // deferred placeholders outside the `ShellRoute`.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // #120's two children of the `/recipe` route. Both stay inside the
  // `ShellRoute` — a leading slash on either child path would have made it
  // top-level and lost the tab bar, which is exactly what this proves did
  // not happen.
  testWidgets(
    'both child routes render inside the shell, with the NavigationBar '
    'still present',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [completedOnboardingGate()],
          child: const FantasticApp(),
        ),
      );
      await tester.pumpAndSettle();

      final router = GoRouter.of(tester.element(find.text('בית').first));

      router.go('/recipe/library');
      await tester.pumpAndSettle();
      expect(find.byType(RecipeLibraryScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);

      router.go('/recipe/saved/1');
      await tester.pumpAndSettle();
      expect(find.byType(SavedRecipeLoader), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
