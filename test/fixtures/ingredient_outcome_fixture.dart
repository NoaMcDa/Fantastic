import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/outcome_source.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/models/substitution.dart';

/// Test data for [IngredientOutcome] and the models it carries.
///
/// **Every number is distinct** where two fields share a type, per
/// `CLAUDE.md` §Testing — `quantity` and `ratio` are both `double`s, and a
/// fixture where they happened to be equal would hide a mix-up between them.
abstract final class IngredientOutcomeFixture {
  static ParsedIngredient ingredient({
    String name = 'קמח',
    String raw = '2 כוסות קמח',
    double? quantity = 2,
    String? unit = 'כוסות',
  }) => ParsedIngredient(name: name, raw: raw, quantity: quantity, unit: unit);

  static Substitution substitution({
    String replacement = 'קמח שקדים',
    double ratio = 0.25,
    String reason = 'עתיר פחמימות',
  }) => Substitution(replacement: replacement, ratio: ratio, reason: reason);

  /// `2 כוסות קמח` at ratio 0.25 — the highest-value assertion in the file:
  /// the adjusted quantity is `0.5 כוסות`, never the original `2`.
  static Substituted substituted({
    ParsedIngredient? withIngredient,
    Substitution? withSubstitution,
    OutcomeSource source = OutcomeSource.rule,
  }) => Substituted(
    withIngredient ?? ingredient(),
    substitution: withSubstitution ?? substitution(),
    source: source,
  );

  /// A substituted line with no quantity at all — nothing should be
  /// invented in its place.
  static Substituted substitutedNoQuantity({
    OutcomeSource source = OutcomeSource.rule,
  }) => Substituted(
    ingredient(raw: 'קמח', quantity: null, unit: null),
    substitution: substitution(),
    source: source,
  );

  static AlreadyKeto alreadyKeto({
    ParsedIngredient? withIngredient,
    OutcomeSource source = OutcomeSource.rule,
  }) => AlreadyKeto(
    withIngredient ??
        ingredient(name: 'ביצים', raw: '3 ביצים', quantity: 3, unit: null),
    source: source,
  );

  static Flagged flagged({ParsedIngredient? withIngredient}) => Flagged(
    withIngredient ??
        ingredient(name: 'מלטיטול', raw: 'מלטיטול', quantity: null, unit: null),
  );

  static Unrecognised unrecognised({ParsedIngredient? withIngredient}) =>
      Unrecognised(
        withIngredient ??
            ingredient(
              name: 'קסמוקס',
              raw: 'קסמוקס',
              quantity: null,
              unit: null,
            ),
      );
}
