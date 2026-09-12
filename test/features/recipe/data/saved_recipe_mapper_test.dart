import 'package:fantastic/features/recipe/data/mappers/saved_recipe_mapper.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/outcome_source.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/fixtures.dart';

/// True when [value] is JSON-compatible per sembast's own contract:
/// `null`, `num`, `String`, `bool`, `List`, or `Map`, recursively.
bool _isSembastLegal(Object? value) {
  if (value == null || value is num || value is String || value is bool) {
    return true;
  }
  if (value is List) {
    return value.every(_isSembastLegal);
  }
  if (value is Map) {
    return value.keys.every((k) => k is String) &&
        value.values.every(_isSembastLegal);
  }
  return false;
}

void main() {
  group('SavedRecipeMapper.toRecord', () {
    test('emits only sembast-legal values', () {
      final record = SavedRecipeMapper.toRecord(
        SavedRecipeFixture.withPerServing(),
      );

      expect(_isSembastLegal(record), isTrue, reason: '$record');
    });

    test('savedAt is stored as millisecondsSinceEpoch, not a DateTime', () {
      final recipe = SavedRecipeFixture.fixture();

      final record = SavedRecipeMapper.toRecord(recipe);

      expect(record['savedAt'], recipe.savedAt.millisecondsSinceEpoch);
      expect(record['savedAt'], isA<int>());
    });

    test('type and source are stored by name, never ordinal', () {
      final record = SavedRecipeMapper.toRecord(
        SavedRecipeFixture.fixture(
          outcomes: [SavedRecipeFixture.substitutedSuggested()],
        ),
      );

      final outcomeRecord = (record['outcomes']! as List).single as Map;
      expect(outcomeRecord['type'], 'substituted');
      expect(outcomeRecord['source'], 'suggested');
    });
  });

  group('round-trip', () {
    test('every outcome variant round-trips', () {
      final recipe = SavedRecipeFixture.fixture(
        outcomes: SavedRecipeFixture.allOutcomeVariants(),
      );

      final record = SavedRecipeMapper.toRecord(recipe);
      final decoded = SavedRecipeMapper.fromRecord(1, record);

      expect(decoded.outcomes, recipe.outcomes);
    });

    test('source round-trips for every OutcomeSource value', () {
      for (final source in OutcomeSource.values) {
        final recipe = SavedRecipeFixture.fixture(
          outcomes: [
            AlreadyKeto(
              const ParsedIngredient(name: 'שמן זית', raw: 'שמן זית'),
              source: source,
            ),
          ],
        );

        final decoded = SavedRecipeMapper.fromRecord(
          1,
          SavedRecipeMapper.toRecord(recipe),
        );

        expect(
          (decoded.outcomes.single as AlreadyKeto).source,
          source,
          reason: source.name,
        );
      }
    });

    test('an unknown stored source decodes as rule', () {
      final record = SavedRecipeMapper.toRecord(
        SavedRecipeFixture.fixture(
          outcomes: [SavedRecipeFixture.alreadyKeto()],
        ),
      );
      final outcomeRecord = Map<String, Object?>.from(
        (record['outcomes']! as List).first as Map,
      );
      outcomeRecord['source'] = 'someFutureSource';
      record['outcomes'] = [outcomeRecord];

      final decoded = SavedRecipeMapper.fromRecord(1, record);

      expect(
        (decoded.outcomes.single as AlreadyKeto).source,
        OutcomeSource.rule,
      );
    });

    test('ratio 1.0 round-trips as a double, including from an int', () {
      final recipe = SavedRecipeFixture.fixture(
        outcomes: [SavedRecipeFixture.substitutedRuleUnitRatio()],
      );

      final record = SavedRecipeMapper.toRecord(recipe);
      expect(
        (record['outcomes']! as List).single as Map,
        containsPair('ratio', 1.0),
      );

      // Simulate what IndexedDB's JSON round-trip does to a whole double:
      // it comes back as an int, and a direct `as double` cast would throw.
      final outcomeRecord = Map<String, Object?>.from(
        (record['outcomes']! as List).first as Map,
      );
      outcomeRecord['ratio'] = 1; // int, not 1.0
      record['outcomes'] = [outcomeRecord];

      final decoded = SavedRecipeMapper.fromRecord(1, record);
      final substitution =
          (decoded.outcomes.single as Substituted).substitution;
      expect(substitution.ratio, 1.0);
      expect(substitution.ratio, isA<double>());
    });

    test(
      'a record with no servings/perServing keys decodes with both null',
      () {
        final record = SavedRecipeMapper.toRecord(SavedRecipeFixture.fixture());

        final decoded = SavedRecipeMapper.fromRecord(1, record);

        expect(decoded.servings, isNull);
        expect(decoded.perServing, isNull);
      },
    );

    test('servings and perServing round-trip when present', () {
      final recipe = SavedRecipeFixture.withPerServing();

      final decoded = SavedRecipeMapper.fromRecord(
        1,
        SavedRecipeMapper.toRecord(recipe),
      );

      expect(decoded.servings, recipe.servings);
      expect(decoded.perServing, recipe.perServing);
    });

    test('perServing macros decode through num, not a direct double cast', () {
      final record = SavedRecipeMapper.toRecord(
        SavedRecipeFixture.withPerServing(),
      );
      final perServingRecord = Map<String, Object?>.from(
        record['perServing']! as Map,
      );
      // A whole double coming back as an int, as IndexedDB's JSON does.
      perServingRecord['fatG'] = 18;
      record['perServing'] = perServingRecord;

      final decoded = SavedRecipeMapper.fromRecord(1, record);

      expect(decoded.perServing!.fatG, 18.0);
      expect(decoded.perServing!.fatG, isA<double>());
    });
  });

  group('fromRecord failure', () {
    test('an unknown type throws', () {
      final record = SavedRecipeMapper.toRecord(
        SavedRecipeFixture.fixture(
          outcomes: [SavedRecipeFixture.alreadyKeto()],
        ),
      );
      final outcomeRecord = Map<String, Object?>.from(
        (record['outcomes']! as List).first as Map,
      );
      outcomeRecord['type'] = 'someFutureType';
      record['outcomes'] = [outcomeRecord];

      expect(() => SavedRecipeMapper.fromRecord(1, record), throwsA(anything));
    });
  });
}
