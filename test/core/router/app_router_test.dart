import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/features/recipe/presentation/screens/recipe_converter_screen.dart';
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
}
