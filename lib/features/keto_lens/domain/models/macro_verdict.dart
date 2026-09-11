import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:meta/meta.dart';

/// What the panel says about the product itself.
enum MacroJudgement { keto, moderation, notKeto, indeterminate }

/// Why a verdict could not be reached.
///
/// Shown to the user: "the panel disagrees with its own calorie figure" and
/// "no carbohydrate row was read" call for different actions from the person
/// holding the product.
enum MacroIndeterminacy {
  /// No carbohydrate row parsed, so there is nothing to judge.
  noCarbRow,

  /// Nothing the figures could be measured against.
  noBasis,

  /// The macros outweigh the food containing them.
  implausibleMass,

  /// The panel disagrees with its own calorie figure, so a digit was mis-read.
  energyMismatch,
}

/// The product-level verdict, taken from the nutrition panel.
///
/// Separate from `IngredientVerdict` because the two answer different
/// questions from different evidence, and **either can be absent**: a
/// nutrition-table crop has no ingredient list, an ingredient-list crop has no
/// macros. Collapsing them into one value is what let a 34.2 g-net-carb bread
/// render as a green tick (#306).
@immutable
class MacroVerdict {
  const MacroVerdict({
    required this.judgement,
    required this.netCarbsPer100,
    this.servingNetCarbsG,
    this.gramsToDailyBudget,
    this.basisAssumed = false,
    this.adjustedForPolyols = false,
  }) : reason = null,
       assert(
         judgement != MacroJudgement.indeterminate,
         'an indeterminate verdict must carry a reason — use '
         'MacroVerdict.indeterminate',
       ),
       assert(
         netCarbsPer100 != null || judgement == MacroJudgement.moderation,
         'only a per-serving label with no weight may judge without a density',
       );

  /// A verdict that could not be reached, and why.
  const MacroVerdict.indeterminate(MacroIndeterminacy this.reason)
    : judgement = MacroJudgement.indeterminate,
      netCarbsPer100 = null,
      servingNetCarbsG = null,
      gramsToDailyBudget = null,
      basisAssumed = false,
      adjustedForPolyols = false;

  final MacroJudgement judgement;

  /// Net carbs per 100 g or 100 ml, after any polyol adjustment.
  ///
  /// Null when the label declared a serving and no weight to scale it by —
  /// there is a cost but no density — and always null when indeterminate.
  final double? netCarbsPer100;

  /// What one declared serving costs. Null when the label declared none.
  final double? servingNetCarbsG;

  /// Grams of product that would exhaust a day's carbs.
  ///
  /// The number that turns a wide amber band from a shrug into an instruction.
  final double? gramsToDailyBudget;

  /// True when the label declared no basis and the figures were read as per
  /// 100 g. The sheet must say so.
  final bool basisAssumed;

  /// True when declared polyol grams were subtracted.
  final bool adjustedForPolyols;

  /// Why there is no judgement. Non-null exactly when indeterminate.
  final MacroIndeterminacy? reason;

  /// This verdict as a badge, or null when there is nothing to say.
  ///
  /// Null for indeterminate, so the caller reduces over the badges that
  /// *exist* rather than over an invented one: `VerdictBadge` is the
  /// ingredient severity ladder and has no member meaning "no opinion".
  ///
  /// An exhaustive `switch`, so a future [MacroJudgement] fails to compile.
  VerdictBadge? get badge => switch (judgement) {
    MacroJudgement.keto => VerdictBadge.cleanKeto,
    MacroJudgement.moderation => VerdictBadge.cautionQuantityDependent,
    MacroJudgement.notKeto => VerdictBadge.nonKeto,
    MacroJudgement.indeterminate => null,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MacroVerdict &&
          other.judgement == judgement &&
          other.netCarbsPer100 == netCarbsPer100 &&
          other.servingNetCarbsG == servingNetCarbsG &&
          other.gramsToDailyBudget == gramsToDailyBudget &&
          other.basisAssumed == basisAssumed &&
          other.adjustedForPolyols == adjustedForPolyols &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(
    judgement,
    netCarbsPer100,
    servingNetCarbsG,
    gramsToDailyBudget,
    basisAssumed,
    adjustedForPolyols,
    reason,
  );
}
