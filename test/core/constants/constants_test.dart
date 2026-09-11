import 'package:fantastic/core/constants/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('KetoConstants', () {
    test('is importable via the barrel export', () {
      expect(KetoConstants.targetKetoRatioMin, 1.5);
      expect(KetoConstants.targetKetoRatioIdeal, 2.0);
      expect(KetoConstants.defaultNetCarbTargetG, 20.0);
      expect(KetoConstants.defaultFatTargetG, 150.0);
      expect(KetoConstants.defaultProteinTargetG, 80.0);
    });
  });

  group('ElectrolyteConstants', () {
    test('is importable via the barrel export', () {
      expect(ElectrolyteConstants.phase1SodiumMinMg, 3000);
      expect(ElectrolyteConstants.phase23MagnesiumMaxMg, 400);
    });

    test('phase ranges have a lower bound below their upper bound', () {
      expect(
        ElectrolyteConstants.phase1SodiumMinMg,
        lessThan(ElectrolyteConstants.phase1SodiumMaxMg),
      );
      expect(
        ElectrolyteConstants.phase1PotassiumMinMg,
        lessThan(ElectrolyteConstants.phase1PotassiumMaxMg),
      );
      expect(
        ElectrolyteConstants.phase1MagnesiumMinMg,
        lessThan(ElectrolyteConstants.phase1MagnesiumMaxMg),
      );
      expect(
        ElectrolyteConstants.phase23SodiumMinMg,
        lessThan(ElectrolyteConstants.phase23SodiumMaxMg),
      );
      expect(
        ElectrolyteConstants.phase23PotassiumMinMg,
        lessThan(ElectrolyteConstants.phase23PotassiumMaxMg),
      );
      expect(
        ElectrolyteConstants.phase23MagnesiumMinMg,
        lessThan(ElectrolyteConstants.phase23MagnesiumMaxMg),
      );
    });
  });

  group('IngredientRules', () {
    test('list lengths match the documented ingredient counts', () {
      expect(IngredientRules.forbiddenSeedOils, hasLength(6));
      expect(IngredientRules.insulinSpikingSweeteners, hasLength(6));
      expect(IngredientRules.cleanApprovedFats, hasLength(7));
      expect(IngredientRules.cleanSweeteners, hasLength(4));
    });

    test('has no duplicate entries within any list', () {
      for (final list in [
        IngredientRules.forbiddenSeedOils,
        IngredientRules.insulinSpikingSweeteners,
        IngredientRules.cleanApprovedFats,
        IngredientRules.cleanSweeteners,
      ]) {
        expect(list.toSet().length, list.length);
      }
    });

    test('every entry is lowercase, matching the classifier\'s '
        'case-insensitive lookup', () {
      for (final list in [
        IngredientRules.forbiddenSeedOils,
        IngredientRules.insulinSpikingSweeteners,
        IngredientRules.cleanApprovedFats,
        IngredientRules.cleanSweeteners,
      ]) {
        for (final entry in list) {
          expect(entry, entry.toLowerCase());
        }
      }
    });
  });

  group('IngredientRules Hebrew lists', () {
    const hebrewLists = [
      IngredientRules.forbiddenSeedOilsHebrew,
      IngredientRules.insulinSpikingSweetenersHebrew,
      IngredientRules.cleanApprovedFatsHebrew,
      IngredientRules.cleanSweetenersHebrew,
      IngredientRules.unspecifiedVegetableOils,
      IngredientRules.cleanOilSources,
    ];

    test('every Hebrew list is non-empty and free of duplicates', () {
      for (final list in hebrewLists) {
        expect(list, isNotEmpty);
        expect(list.toSet().length, list.length);
      }
    });

    test('no entry is blank or carries surrounding whitespace', () {
      for (final list in hebrewLists) {
        for (final entry in list) {
          expect(entry.trim(), entry, reason: 'untrimmed entry: "\$entry"');
          expect(entry, isNotEmpty);
        }
      }
    });

    test('every entry is lowercase', () {
      // A no-op for Hebrew, which is caseless, but the Latin entries in
      // `unspecifiedVegetableOils` and `cleanOilSources` are matched
      // against lowercased input like every other rule.
      for (final list in hebrewLists) {
        for (final entry in list) {
          expect(entry, entry.toLowerCase());
        }
      }
    });

    test('the combined lists hold every entry from both languages', () {
      expect(
        IngredientRules.allForbiddenSeedOils,
        hasLength(
          IngredientRules.forbiddenSeedOils.length +
              IngredientRules.forbiddenSeedOilsHebrew.length,
        ),
      );
      expect(
        IngredientRules.allInsulinSpikingSweeteners,
        hasLength(
          IngredientRules.insulinSpikingSweeteners.length +
              IngredientRules.insulinSpikingSweetenersHebrew.length,
        ),
      );
      expect(
        IngredientRules.allCleanIngredients,
        hasLength(
          IngredientRules.cleanApprovedFats.length +
              IngredientRules.cleanApprovedFatsHebrew.length +
              IngredientRules.cleanSweeteners.length +
              IngredientRules.cleanSweetenersHebrew.length,
        ),
      );
    });

    test('no rule appears in more than one combined list', () {
      // Overlap would make the classifier's severity order observable, and
      // the order is an implementation detail.
      final forbidden = IngredientRules.allForbiddenSeedOils.toSet();
      final caution = IngredientRules.allInsulinSpikingSweeteners.toSet();
      final clean = IngredientRules.allCleanIngredients.toSet();

      expect(forbidden.intersection(caution), isEmpty);
      expect(forbidden.intersection(clean), isEmpty);
      expect(caution.intersection(clean), isEmpty);
    });
  });
}
