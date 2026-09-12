import 'package:fantastic/features/recipe/application/providers/recipe_providers.dart';
import 'package:fantastic/features/recipe/data/providers.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/repositories/saved_recipe_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';

class _MockSavedRecipeRepository extends Mock
    implements SavedRecipeRepository {}

/// The provider is one line, so the only thing worth asserting is the thing a
/// one-line change could silently break: that it hands back an engine seeded
/// from the **shipped** tables rather than an empty one.
///
/// `SubstitutionEngine`'s own suite passes its own small table, so swapping
/// this provider to `SubstitutionEngine(substitutions: [])` would leave every
/// one of those tests green while the real app answered `Unrecognised` to
/// every line of every recipe. Only a test that reads the provider and
/// classifies against the real table catches that.
void main() {
  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  ParsedIngredient ingredient(String name) =>
      ParsedIngredient(name: name, raw: name);

  test('resolves to an engine seeded from the shipped substitution table', () {
    final outcome = container()
        .read(substitutionEngineProvider)
        .classify(ingredient('קמח'));

    expect(outcome, isA<Substituted>());
  });

  test('resolves to an engine seeded from the shipped staples table', () {
    final outcome = container()
        .read(substitutionEngineProvider)
        .classify(ingredient('ביצים'));

    expect(outcome, isA<AlreadyKeto>());
  });

  test('is const-constructed, so two reads share one instance', () {
    final c = container();

    expect(
      identical(
        c.read(substitutionEngineProvider),
        c.read(substitutionEngineProvider),
      ),
      isTrue,
    );
  });

  group('savedRecipesProvider (#120)', () {
    test('forwards to the repository\'s findAll', () async {
      final repository = _MockSavedRecipeRepository();
      final recipes = [
        SavedRecipeFixture.fixture(id: 1, title: 'א'),
        SavedRecipeFixture.fixture(id: 2, title: 'ב'),
      ];
      when(repository.findAll).thenAnswer((_) async => recipes);

      final c = ProviderContainer(
        overrides: [
          savedRecipeRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(c.dispose);

      expect(await c.read(savedRecipesProvider.future), recipes);
    });
  });

  group('savedRecipeProvider (#120)', () {
    test('forwards to the repository\'s findById', () async {
      final repository = _MockSavedRecipeRepository();
      final recipe = SavedRecipeFixture.fixture(id: 3);
      when(() => repository.findById(3)).thenAnswer((_) async => recipe);

      final c = ProviderContainer(
        overrides: [
          savedRecipeRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(c.dispose);

      expect(await c.read(savedRecipeProvider(3).future), recipe);
    });

    test('resolves to null for an id the repository does not know', () async {
      final repository = _MockSavedRecipeRepository();
      when(() => repository.findById(99)).thenAnswer((_) async => null);

      final c = ProviderContainer(
        overrides: [
          savedRecipeRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(c.dispose);

      expect(await c.read(savedRecipeProvider(99).future), isNull);
    });
  });
}
