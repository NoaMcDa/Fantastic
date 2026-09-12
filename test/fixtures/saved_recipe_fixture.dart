import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/outcome_source.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';
import 'package:fantastic/features/recipe/domain/models/substitution.dart';

/// Test data for [SavedRecipe] and its nested [IngredientOutcome] variants.
///
/// Every field is deliberately distinct from every other same-typed field
/// (`design/m1_handoff.md`'s all-neutral-fixture warning): a mapper that
/// crossed two fields — swapping `ratio` and `quantity`, say — would still
/// pass a fixture where both happened to be the same number.
abstract final class SavedRecipeFixture {
  static final DateTime defaultSavedAt = DateTime(2026, 9, 9, 12);

  /// One [AlreadyKeto], sourced from the rule table.
  static IngredientOutcome alreadyKeto() => const AlreadyKeto(
    ParsedIngredient(
      name: 'חמאה',
      raw: '2 כפות חמאה',
      quantity: 2,
      unit: 'כפות',
    ),
  );

  /// One [Substituted], sourced from a model — the outcome that is
  /// [OutcomeSource.suggested], and whose ratio is not `1.0`.
  static IngredientOutcome substitutedSuggested() => const Substituted(
    ParsedIngredient(
      name: 'סוכר',
      raw: '3/4 כוס סוכר',
      quantity: 0.75,
      unit: 'כוס',
    ),
    substitution: Substitution(
      replacement: 'אריתריטול',
      ratio: 0.75,
      reason: 'ממתיק נטול פחמימות',
    ),
    source: OutcomeSource.suggested,
  );

  /// A second [Substituted], sourced from the rule table, whose ratio is
  /// exactly `1.0` — most seed ratios are, so this is the common path, not
  /// an edge case.
  static IngredientOutcome substitutedRuleUnitRatio() => const Substituted(
    ParsedIngredient(name: 'קמח', raw: 'כוס קמח', quantity: 1, unit: 'כוס'),
    substitution: Substitution(
      replacement: 'קמח שקדים',
      ratio: 1.0,
      reason: 'תחליף קמח קלאסי',
    ),
  );

  /// One [Flagged] — known non-keto, no substitute.
  static IngredientOutcome flagged() => const Flagged(
    ParsedIngredient(name: 'דבש', raw: 'כף דבש', quantity: 1, unit: 'כף'),
  );

  /// One [Unrecognised] — genuinely unknown to the engine.
  static IngredientOutcome unrecognised() =>
      const Unrecognised(ParsedIngredient(name: 'קסניתן', raw: 'קסניתן'));

  /// One of each of the four [IngredientOutcome] variants, plus a second
  /// [Substituted] so both a `1.0` ratio and a non-`1.0` ratio are present.
  static List<IngredientOutcome> allOutcomeVariants() => [
    alreadyKeto(),
    substitutedSuggested(),
    substitutedRuleUnitRatio(),
    flagged(),
    unrecognised(),
  ];

  /// A recipe carrying every optional field and every outcome variant, for
  /// round-trip tests that need to prove nothing is silently dropped.
  static SavedRecipe fixture({
    int? id,
    String title = 'פשטידת כרובית',
    String originalText = 'כוס קמח\n2 כפות חמאה\n3/4 כוס סוכר\nכף דבש\nקסניתן',
    List<IngredientOutcome>? outcomes,
    DateTime? savedAt,
    int? servings,
    MacroTotals? perServing,
  }) => SavedRecipe(
    id: id,
    title: title,
    originalText: originalText,
    outcomes: outcomes ?? allOutcomeVariants(),
    savedAt: savedAt ?? defaultSavedAt,
    servings: servings,
    perServing: perServing,
  );

  /// A recipe with [MacroTotals.perServing] and [SavedRecipe.servings] set —
  /// distinct fat/net-carb/protein figures, so a mapper that crossed two of
  /// the three fields would still fail.
  static SavedRecipe withPerServing({int? id}) => fixture(
    id: id,
    servings: 6,
    perServing: const MacroTotals(fatG: 18, netCarbsG: 4, proteinG: 9),
  );
}
