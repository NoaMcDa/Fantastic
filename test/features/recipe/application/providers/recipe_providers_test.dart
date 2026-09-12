import 'package:fantastic/features/recipe/application/providers/recipe_providers.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
