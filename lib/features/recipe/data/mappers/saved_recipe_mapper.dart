import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/outcome_source.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';
import 'package:fantastic/features/recipe/domain/models/substitution.dart';

/// Converts between [SavedRecipe] and its sembast record shape.
///
/// Called only by `SembastSavedRecipeRepository` — never from `domain/` or
/// `presentation/`, which must not see a persistence shape at all.
///
/// A record is a plain `Map<String, Object?>` whose values must survive the
/// store's JSON encoding, so `DateTime` is written as epoch milliseconds and
/// every sealed [IngredientOutcome] variant is flattened into one map with a
/// `type` discriminator, stored **by name**, never by ordinal — the
/// sealed-class analogue of `CLAUDE.md`'s enum rule and the same failure mode
/// if an ordinal were used. The record carries no id: sembast holds the key
/// outside the value, and [fromRecord] takes it as a separate argument.
abstract final class SavedRecipeMapper {
  static Map<String, Object?> toRecord(SavedRecipe recipe) => {
    'title': recipe.title,
    'originalText': recipe.originalText,
    'outcomes': recipe.outcomes.map(_outcomeToRecord).toList(),
    'savedAt': recipe.savedAt.millisecondsSinceEpoch,
    'servings': recipe.servings,
    'perServing': recipe.perServing == null
        ? null
        : {
            'fatG': recipe.perServing!.fatG,
            'netCarbsG': recipe.perServing!.netCarbsG,
            'proteinG': recipe.perServing!.proteinG,
          },
  };

  static SavedRecipe fromRecord(int key, Map<String, Object?> record) {
    final perServingRecord = record['perServing'] as Map<String, Object?>?;
    return SavedRecipe(
      id: key,
      title: record['title']! as String,
      originalText: record['originalText']! as String,
      outcomes: (record['outcomes']! as List)
          .map((raw) => _outcomeFromRecord(raw as Map<String, Object?>))
          .toList(),
      savedAt: DateTime.fromMillisecondsSinceEpoch(record['savedAt']! as int),
      servings: record['servings'] as int?,
      perServing: perServingRecord == null
          ? null
          : MacroTotals(
              // `as num` then `.toDouble()`, never `as double`: a whole
              // number written as 40.0 comes back from IndexedDB's JSON as
              // an int.
              fatG: (perServingRecord['fatG']! as num).toDouble(),
              netCarbsG: (perServingRecord['netCarbsG']! as num).toDouble(),
              proteinG: (perServingRecord['proteinG']! as num).toDouble(),
            ),
    );
  }

  static Map<String, Object?> _outcomeToRecord(IngredientOutcome outcome) {
    final ingredient = outcome.ingredient;
    final base = <String, Object?>{
      'name': ingredient.name,
      'quantity': ingredient.quantity,
      'unit': ingredient.unit,
      'raw': ingredient.raw,
      'replacement': null,
      'ratio': null,
      'reason': null,
      'source': null,
    };
    switch (outcome) {
      case AlreadyKeto():
        return {...base, 'type': 'alreadyKeto', 'source': outcome.source.name};
      case Substituted():
        return {
          ...base,
          'type': 'substituted',
          'replacement': outcome.substitution.replacement,
          'ratio': outcome.substitution.ratio,
          'reason': outcome.substitution.reason,
          'source': outcome.source.name,
        };
      case Flagged():
        return {...base, 'type': 'flagged'};
      case Unrecognised():
        return {...base, 'type': 'unrecognised'};
    }
  }

  static IngredientOutcome _outcomeFromRecord(Map<String, Object?> record) {
    final ingredient = ParsedIngredient(
      name: record['name']! as String,
      raw: record['raw']! as String,
      quantity: (record['quantity'] as num?)?.toDouble(),
      unit: record['unit'] as String?,
    );
    final type = record['type'] as String?;
    switch (type) {
      case 'alreadyKeto':
        return AlreadyKeto(ingredient, source: _sourceOf(record['source']));
      case 'substituted':
        return Substituted(
          ingredient,
          substitution: Substitution(
            replacement: record['replacement']! as String,
            ratio: (record['ratio']! as num).toDouble(),
            reason: record['reason']! as String,
          ),
          source: _sourceOf(record['source']),
        );
      case 'flagged':
        return Flagged(ingredient);
      case 'unrecognised':
        return Unrecognised(ingredient);
      default:
        // An unknown type has no safe default — unlike `source` below, there
        // is no reading of a stored outcome that is always right. This throws
        // a plain `StateError`, not a `PersistenceException` directly:
        // `guardPersistence`, wrapping the repository call this mapper runs
        // inside, is what converts it — a codec that throws on stored data is
        // itself a persistence-integrity failure.
        throw StateError('SavedRecipeMapper: unknown outcome type "$type"');
    }
  }

  /// The stored provenance, or [OutcomeSource.rule] for anything unreadable.
  ///
  /// **Null-tolerant by requirement, not by accident** — mirrors
  /// `MealEntryMapper._sourceOf`. `Flagged` and `Unrecognised` never write a
  /// `source`, and a record written by an older build may not either, so this
  /// must not throw on a missing or unknown value. Deliberately the opposite
  /// of the unknown-`type` handling above: an unknown provenance has a safe
  /// default, an unknown outcome type does not.
  ///
  /// `OutcomeSource.values.byName` is deliberately not used: it throws on an
  /// unknown name, which is what a downgrade or a restored backup written by
  /// a newer build looks like.
  static OutcomeSource _sourceOf(Object? stored) {
    if (stored is! String) {
      return OutcomeSource.rule;
    }
    return OutcomeSource.values.firstWhere(
      (value) => value.name == stored,
      orElse: () => OutcomeSource.rule,
    );
  }
}
