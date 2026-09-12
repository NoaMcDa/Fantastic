import 'dart:async';

import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/features/recipe/data/providers.dart';
import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';
import 'package:fantastic/features/recipe/domain/repositories/saved_recipe_repository.dart';
import 'package:fantastic/features/recipe/presentation/screens/recipe_converter_screen.dart';
import 'package:fantastic/features/recipe/presentation/screens/saved_recipe_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockSavedRecipeRepository extends Mock
    implements SavedRecipeRepository {}

/// `/recipe/saved/:id`'s loader: reopens by path id, never by `extra`, and
/// never crashes on a bad or unknown one.
void main() {
  late _MockSavedRecipeRepository repository;

  setUp(() {
    repository = _MockSavedRecipeRepository();
  });

  Future<void> pumpLoader(WidgetTester tester, int? id) => pumpApp(
    tester,
    SavedRecipeLoader(id: id),
    overrides: [savedRecipeRepositoryProvider.overrideWithValue(repository)],
  );

  testWidgets('a known id renders the converter seeded', (tester) async {
    final recipe = SavedRecipeFixture.fixture(id: 3, title: 'שמור');
    when(() => repository.findById(3)).thenAnswer((_) async => recipe);

    await pumpLoader(tester, 3);
    await tester.pumpAndSettle();

    expect(find.byType(RecipeConverterScreen), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const Key('recipe_paste_field')),
    );
    expect(field.controller!.text, recipe.originalText);
    // The results are seeded, not re-run: `allOutcomeVariants()` puts
    // `AlreadyKeto` first.
    expect(find.byKey(const Key('outcome_already_keto_0')), findsOneWidget);
    expect(find.byKey(const Key('recipe_not_found_notice')), findsNothing);
  });

  testWidgets('an unknown id renders an empty converter with the notice', (
    tester,
  ) async {
    when(() => repository.findById(99)).thenAnswer((_) async => null);

    await pumpLoader(tester, 99);
    await tester.pumpAndSettle();

    expect(find.byType(RecipeConverterScreen), findsOneWidget);
    expect(find.byKey(const Key('recipe_not_found_notice')), findsOneWidget);
    expect(find.text(RecipeCopy.recipeNotFound), findsOneWidget);
    // Empty, not seeded — the paste field is blank.
    final field = tester.widget<TextField>(
      find.byKey(const Key('recipe_paste_field')),
    );
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('a non-numeric (null) id does not throw', (tester) async {
    // The router does `int.tryParse`, so a non-numeric path segment reaches
    // the widget as a null id — this is what that looks like here.
    await pumpLoader(tester, null);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('recipe_not_found_notice')), findsOneWidget);
  });

  testWidgets('a failed read also falls back to the not-found converter, '
      'never a stuck spinner', (tester) async {
    when(() => repository.findById(5))
        .thenAnswer((_) async => throw Exception('disk gone'));

    await pumpLoader(tester, 5);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byKey(const Key('recipe_not_found_notice')), findsOneWidget);
  });

  testWidgets('loading renders a static skeleton, no spinner', (tester) async {
    when(() => repository.findById(1))
        .thenAnswer((_) => Completer<SavedRecipe?>().future);

    await pumpLoader(tester, 1);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(RecipeConverterScreen), findsNothing);
  });
}
