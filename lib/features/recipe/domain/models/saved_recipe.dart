import 'package:fantastic/core/utils/list_equality.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:meta/meta.dart';

/// A recipe the user converted and kept.
///
/// Pure domain: no Flutter, no persistence package. `SavedRecipeMapper`
/// converts to and from a record map.
@immutable
class SavedRecipe {
  const SavedRecipe({
    required this.title,
    required this.originalText,
    required this.outcomes,
    required this.savedAt,
    this.id,
    this.servings,
    this.perServing,
  });

  /// Null until first persisted; sembast assigns the auto-increment key.
  final int? id;

  final String title;

  /// The text as pasted, so a stale conversion can be re-run after the rule
  /// table grows without the user re-typing it.
  final String originalText;

  /// In input order. May be empty — a recipe of nothing but blank lines is
  /// refused at the save affordance (#120), not here; domain models in this
  /// repo do not police their constructors.
  final List<IngredientOutcome> outcomes;

  final DateTime savedAt;

  /// Both null until the per-serving macros issue (#397) writes them.
  final int? servings;
  final MacroTotals? perServing;

  SavedRecipe copyWith({
    int? id,
    String? title,
    String? originalText,
    List<IngredientOutcome>? outcomes,
    DateTime? savedAt,
    int? servings,
    MacroTotals? perServing,
  }) => SavedRecipe(
    id: id ?? this.id,
    title: title ?? this.title,
    originalText: originalText ?? this.originalText,
    outcomes: outcomes ?? this.outcomes,
    savedAt: savedAt ?? this.savedAt,
    servings: servings ?? this.servings,
    perServing: perServing ?? this.perServing,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedRecipe &&
          other.id == id &&
          other.title == title &&
          other.originalText == originalText &&
          other.savedAt == savedAt &&
          other.servings == servings &&
          other.perServing == perServing &&
          // Element-wise: two recipes with equal-but-not-identical outcome
          // lists are equal. A plain `==` on List compares identity.
          listEquals(other.outcomes, outcomes);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    originalText,
    listHash(outcomes),
    savedAt,
    servings,
    perServing,
  );

  @override
  String toString() =>
      'SavedRecipe(id: $id, title: $title, outcomes: $outcomes, '
      'savedAt: $savedAt, servings: $servings, perServing: $perServing)';
}

/// Three grams figures, nothing else.
///
/// Lives here rather than reusing `EstimateSucceeded` because a stored total
/// is not an estimate result — it is a persisted fact once #397 computes it.
@immutable
class MacroTotals {
  const MacroTotals({
    required this.fatG,
    required this.netCarbsG,
    required this.proteinG,
  });

  final double fatG;
  final double netCarbsG;
  final double proteinG;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroTotals &&
          other.fatG == fatG &&
          other.netCarbsG == netCarbsG &&
          other.proteinG == proteinG;

  @override
  int get hashCode => Object.hash(fatG, netCarbsG, proteinG);

  @override
  String toString() =>
      'MacroTotals(fatG: $fatG, netCarbsG: $netCarbsG, proteinG: $proteinG)';
}
