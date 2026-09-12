import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  group('SavedRecipe.==', () {
    test('is element-wise over outcomes', () {
      final a = SavedRecipeFixture.fixture(
        outcomes: SavedRecipeFixture.allOutcomeVariants(),
      );
      // A different List instance holding equal-but-not-identical elements.
      final b = SavedRecipeFixture.fixture(
        outcomes: SavedRecipeFixture.allOutcomeVariants(),
      );

      expect(identical(a.outcomes, b.outcomes), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('two recipes with a different outcome are not equal', () {
      final a = SavedRecipeFixture.fixture(
        outcomes: [SavedRecipeFixture.alreadyKeto()],
      );
      final b = SavedRecipeFixture.fixture(
        outcomes: [SavedRecipeFixture.flagged()],
      );

      expect(a, isNot(b));
    });

    test('an empty outcome list is not equal to a non-empty one', () {
      final a = SavedRecipeFixture.fixture(outcomes: const []);
      final b = SavedRecipeFixture.fixture(
        outcomes: [SavedRecipeFixture.alreadyKeto()],
      );

      expect(a, isNot(b));
    });

    test('differs when any scalar field differs', () {
      final base = SavedRecipeFixture.fixture();

      expect(base, isNot(base.copyWith(title: 'אחר')));
      expect(base, isNot(base.copyWith(id: 42)));
      expect(base, isNot(base.copyWith(savedAt: DateTime(2020))));
    });
  });

  group('SavedRecipe.copyWith', () {
    test('overrides only the given fields', () {
      final base = SavedRecipeFixture.fixture(id: 1);

      final copy = base.copyWith(title: 'כותרת חדשה');

      expect(copy.title, 'כותרת חדשה');
      expect(copy.id, base.id);
      expect(copy.originalText, base.originalText);
      expect(copy.outcomes, base.outcomes);
      expect(copy.savedAt, base.savedAt);
    });
  });

  group('MacroTotals', () {
    test('== compares every field', () {
      const a = MacroTotals(fatG: 18, netCarbsG: 4, proteinG: 9);
      const b = MacroTotals(fatG: 18, netCarbsG: 4, proteinG: 9);
      const c = MacroTotals(fatG: 18, netCarbsG: 5, proteinG: 9);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
