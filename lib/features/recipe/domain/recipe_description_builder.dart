import 'package:fantastic/core/utils/numeric_input.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';

/// Turns a converted recipe's outcomes into one Hebrew description for
/// `MacroEstimator`.
///
/// Pure Dart, no I/O — `RecipeMacrosSection` is the only caller, and it owns
/// the network call this builder's output feeds.
///
/// **The original recipe is never estimated.** Only the keto version — the
/// replacement names at their adjusted quantities — is worth a request, and
/// estimating the original too would double the quota cost for a total
/// nobody logs.
///
/// **`Flagged` and `Unrecognised` lines are excluded, not estimated.** Their
/// macros are unknown or ignorable, and folding a guess about either into the
/// batch total would be exactly the silently-dropped-ingredient failure this
/// milestone is built to avoid — so they come back in [excluded] and the
/// caller shows them as unidentified instead.
///
/// Not capped here. `MacroEstimationPrompt.maxDescriptionLength` belongs to
/// the estimator's own data-layer prompt builder, and this is a domain file
/// with no reach into `data/` — the estimator caps what it receives, this
/// builder only assembles it.
abstract final class RecipeDescriptionBuilder {
  /// One line per [AlreadyKeto] or [Substituted] outcome in [outcomes],
  /// joined with newlines, plus the raw lines of every [Flagged] and
  /// [Unrecognised] outcome the caller should show as unidentified.
  static ({String description, List<String> excluded}) build(
    List<IngredientOutcome> outcomes,
  ) {
    final lines = <String>[];
    final excluded = <String>[];

    for (final outcome in outcomes) {
      switch (outcome) {
        case AlreadyKeto():
          lines.add(outcome.ingredient.raw);
        case Substituted():
          lines.add(_substitutedLine(outcome));
        case Flagged():
          excluded.add(outcome.ingredient.raw);
        case Unrecognised():
          excluded.add(outcome.ingredient.raw);
      }
    }

    return (description: lines.join('\n'), excluded: excluded);
  }

  /// `<adjusted quantity> <unit> <replacement>`, or just `<replacement>` when
  /// the ingredient carried no quantity.
  ///
  /// The quantity is the *adjusted* one — `IngredientOutcomeRow` applies the
  /// same ratio for the same reason: the original amount of the ingredient
  /// being replaced describes a different, inedible recipe.
  static String _substitutedLine(Substituted outcome) {
    final quantity = outcome.ingredient.quantity;
    final replacement = outcome.substitution.replacement;
    if (quantity == null) {
      return replacement;
    }
    final adjusted = GramsText.format(quantity * outcome.substitution.ratio);
    final unit = outcome.ingredient.unit;
    return unit == null
        ? '$adjusted $replacement'
        : '$adjusted $unit $replacement';
  }
}
