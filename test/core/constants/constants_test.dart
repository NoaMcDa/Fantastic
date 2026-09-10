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
}
