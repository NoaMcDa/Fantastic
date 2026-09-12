import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/models/substitution.dart';
import 'package:fantastic/features/recipe/domain/recipe_description_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/saved_recipe_fixture.dart';

void main() {
  group('RecipeDescriptionBuilder.build', () {
    test(
      'substituted lines carry the adjusted quantity and the replacement',
      () {
        const outcome = Substituted(
          ParsedIngredient(
            name: 'קמח',
            raw: '2 כוסות קמח',
            quantity: 2,
            unit: 'כוסות',
          ),
          substitution: Substitution(
            replacement: 'קמח שקדים',
            ratio: 0.25,
            reason: 'עתיר פחמימות',
          ),
        );

        final result = RecipeDescriptionBuilder.build([outcome]);

        // 2 * 0.25 = 0.5, through GramsText.format.
        expect(result.description, '0.5 כוסות קמח שקדים');
        expect(result.excluded, isEmpty);
      },
    );

    test('already-keto lines pass through as written', () {
      final result = RecipeDescriptionBuilder.build([
        SavedRecipeFixture.alreadyKeto() as AlreadyKeto,
      ]);

      expect(result.description, '2 כפות חמאה');
      expect(result.excluded, isEmpty);
    });

    test('flagged and unrecognised lines are excluded and returned', () {
      final flagged = SavedRecipeFixture.flagged() as Flagged;
      final unrecognised = SavedRecipeFixture.unrecognised() as Unrecognised;

      final result = RecipeDescriptionBuilder.build([flagged, unrecognised]);

      expect(result.description, isEmpty);
      expect(result.excluded, [
        flagged.ingredient.raw,
        unrecognised.ingredient.raw,
      ]);
    });

    test('a line with no quantity carries only the replacement', () {
      const outcome = Substituted(
        ParsedIngredient(name: 'סוכר', raw: 'קמצוץ סוכר'),
        substitution: Substitution(
          replacement: 'אריתריטול',
          ratio: 1,
          reason: 'ממתיק נטול פחמימות',
        ),
      );

      final result = RecipeDescriptionBuilder.build([outcome]);

      expect(result.description, 'אריתריטול');
    });

    test('mixes recognised lines in order, joined by newlines, excluding the '
        'rest', () {
      final already = SavedRecipeFixture.alreadyKeto() as AlreadyKeto;
      final substituted =
          SavedRecipeFixture.substitutedRuleUnitRatio() as Substituted;
      final flagged = SavedRecipeFixture.flagged() as Flagged;

      final result = RecipeDescriptionBuilder.build([
        already,
        substituted,
        flagged,
      ]);

      expect(result.description, '${already.ingredient.raw}\n1 כוס קמח שקדים');
      expect(result.excluded, [flagged.ingredient.raw]);
    });

    test('an empty outcome list produces an empty description and no '
        'excluded lines', () {
      final result = RecipeDescriptionBuilder.build(const []);

      expect(result.description, isEmpty);
      expect(result.excluded, isEmpty);
    });
  });
}
