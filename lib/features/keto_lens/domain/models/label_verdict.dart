import 'package:fantastic/core/constants/ingredient_rules.dart';
import 'package:fantastic/features/keto_lens/domain/models/ingredient_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/macro_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';

/// Reduces the ingredient and macro verdicts into the one badge the user sees.
///
/// Pure domain, so the rule can be asserted without pumping a widget — it is
/// business logic, not presentation, and it was the last place in this feature
/// where a judgement would otherwise have lived inside a `build` method.
abstract final class LabelVerdict {
  /// The badge to show, or null when neither side carried evidence.
  ///
  /// `recognisedNothing` is excluded deliberately: recognising nothing is not
  /// evidence of cleanliness, which is the whole point of that flag.
  static VerdictBadge? combine({
    required IngredientVerdict ingredients,
    required MacroVerdict macros,
  }) {
    final evidence = <VerdictBadge>[
      if (!ingredients.recognisedNothing) ingredients.badge,
      ?macros.badge,
    ];
    if (evidence.isEmpty) {
      return null;
    }

    final worst = VerdictBadge.worst(evidence);
    return _escalates(ingredients: ingredients, macros: macros, worst: worst)
        ? VerdictBadge.nonKeto
        : worst;
  }

  /// Whether [combine] escalated an ingredient caution on macro evidence.
  ///
  /// The sheet says so in words: a red chip with no reason is a red chip the
  /// user argues with.
  static bool escalated({
    required IngredientVerdict ingredients,
    required MacroVerdict macros,
  }) {
    final evidence = <VerdictBadge>[
      if (!ingredients.recognisedNothing) ingredients.badge,
      ?macros.badge,
    ];
    if (evidence.isEmpty) {
      return false;
    }
    return _escalates(
      ingredients: ingredients,
      macros: macros,
      worst: VerdictBadge.worst(evidence),
    );
  }

  /// The amber ingredient badge is defined by `design/ui_ux_design.md` as
  /// *"insulin-spiking sweeteners **in small amount**"*. That is a claim about
  /// quantity which, until #306, nothing in the app could test — the
  /// classifier sees tokens, not grams. The macro verdict is exactly that
  /// test: `moderation` or worse means a normal portion costs more than
  /// `portionNetCarbBudgetG`, which is what the green edge *is*. So the
  /// premise of the caution has been falsified by the panel, and the honest
  /// badge is red.
  ///
  /// Evidence compounding, not two thresholds averaging. Three things it
  /// deliberately does **not** escalate:
  ///
  /// - **an unspecified vegetable oil**, the other source of an amber badge.
  ///   That caution is about *identity* — the oil may be palm or coconut — and
  ///   carbs say nothing about which oil it is. Which is why this tests the
  ///   flagged tokens rather than the badge alone;
  /// - **`keto` macros** — a trace of sorbitol in a 3 g/100 g product is
  ///   precisely the "small amount" the amber badge was written for;
  /// - **`indeterminate` macros** — no evidence, no escalation. A maltitol
  ///   product whose panel could not be read keeps the badge it ships with
  ///   today. No new claim without a number behind it.
  static bool _escalates({
    required IngredientVerdict ingredients,
    required MacroVerdict macros,
    required VerdictBadge worst,
  }) {
    if (worst != VerdictBadge.cautionQuantityDependent) {
      return false;
    }
    if (macros.judgement != MacroJudgement.moderation &&
        macros.judgement != MacroJudgement.notKeto) {
      return false;
    }
    return ingredients.flaggedIngredients.any(_isInsulinSpiking);
  }

  static bool _isInsulinSpiking(String flagged) {
    final token = flagged.toLowerCase();
    return IngredientRules.allInsulinSpikingSweeteners.any(
      (rule) => token.contains(rule.toLowerCase()),
    );
  }
}
