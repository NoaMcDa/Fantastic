import 'package:fantastic/core/constants/ingredient_rules.dart';
import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/core/constants/product_verdict_constants.dart';
import 'package:fantastic/features/keto_lens/domain/models/macro_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
import 'package:fantastic/features/keto_lens/domain/models/serving_basis.dart';
import 'package:fantastic/features/keto_lens/domain/services/macro_classifier.dart';

/// Whether a density is measured per 100 g or per 100 ml.
enum _Unit { solid, liquid }

/// The shipped [MacroClassifier].
///
/// Four stages, in order: the panel checks itself, polyols are subtracted
/// where they can be attributed, a density and a serving load are derived, and
/// a band is chosen and then overridden by what one serving actually costs.
class MacroClassifierImpl implements MacroClassifier {
  const MacroClassifierImpl();

  @override
  MacroVerdict classify(ParsedLabel label) {
    if (!_energyAgrees(label)) {
      return const MacroVerdict.indeterminate(
        MacroIndeterminacy.energyMismatch,
      );
    }

    final netCarbs = label.netCarbsG;
    if (netCarbs == null) {
      return const MacroVerdict.indeterminate(MacroIndeterminacy.noCarbRow);
    }

    final adjustment = _polyolAdjustment(label);
    final adjusted = (netCarbs - adjustment).clamp(0.0, double.infinity);

    // Zero is zero on every basis, so it needs no basis and no assumption.
    if (adjusted == 0) {
      return MacroVerdict(
        judgement: MacroJudgement.keto,
        netCarbsPer100: 0,
        servingNetCarbsG: label.servingGrams == null ? null : 0,
        adjustedForPolyols: adjustment > 0,
      );
    }

    return _band(label, adjusted, adjustedForPolyols: adjustment > 0);
  }

  // ---------------------------------------------------------------- stage 0

  /// Whether the panel's own calorie figure agrees with its macros.
  ///
  /// A mismatch means a digit was mis-read, and a confident band computed from
  /// a corrupted number is the deepest risk this feature carries. Verified on
  /// the real label: `9(3.3) + 4(10.9) + 4(41.2) = 238.1` against a declared
  /// **238**.
  ///
  /// **Skipped entirely when the energy row did not parse** — a label is never
  /// penalised for a row it did not print.
  ///
  /// Both fibre conventions are accepted: the Israeli `מתוכם סיבים` puts fibre
  /// *inside* carbohydrate, while `כלל סיבים` — which the real bread prints —
  /// is the EU shape where it sits outside.
  static bool _energyAgrees(ParsedLabel label) {
    final declared = label.energyKcal;
    final fat = label.fatG;
    final protein = label.proteinG;
    final carbs = label.totalCarbsG;
    if (declared == null ||
        fat == null ||
        protein == null ||
        carbs == null ||
        declared <= 0) {
      return true;
    }

    final predicted =
        ProductVerdictConstants.kcalPerGramFat * fat +
        ProductVerdictConstants.kcalPerGramProtein * protein +
        ProductVerdictConstants.kcalPerGramCarb * carbs;
    final withFibreOutside =
        predicted +
        ProductVerdictConstants.kcalPerGramFibre * (label.fibreG ?? 0);

    bool within(double value) =>
        (declared - value).abs() / declared <=
        ProductVerdictConstants.energyCrossCheckTolerance;

    return within(predicted) || within(withFibreOutside);
  }

  // ---------------------------------------------------------------- stage 1

  /// Declared polyol grams, when they can be honestly subtracted.
  ///
  /// All five conditions must hold, and each closes a way of buying a green
  /// tick with no evidence:
  ///
  /// 1. a polyol row actually parsed — an ingredient name carries no quantity;
  /// 2. the ingredients name a clean sweetener, so the polyols are attributable;
  /// 3. the ingredients name **no** insulin-spiking sweetener — a bar with both
  ///    erythritol and maltitol subtracts nothing, because the split is
  ///    unattributable;
  /// 4. the ingredient list is non-empty — a panel-only crop can attribute
  ///    nothing;
  /// 5. the declared polyols fit inside the carbohydrate residual. If they do
  ///    not, the panel was mis-read.
  static double _polyolAdjustment(ParsedLabel label) {
    final polyols = label.polyolsG;
    if (polyols == null || polyols <= 0 || label.ingredients.isEmpty) {
      return 0;
    }
    if (!_namesAny(label.ingredients, _cleanSweeteners) ||
        _namesAny(
          label.ingredients,
          IngredientRules.allInsulinSpikingSweeteners,
        )) {
      return 0;
    }

    final total = label.totalCarbsG;
    if (total == null) {
      return 0;
    }
    final residual = total - (label.fibreG ?? 0) - (label.sugarsG ?? 0);
    return polyols <= residual ? polyols : 0;
  }

  static const List<String> _cleanSweeteners = [
    ...IngredientRules.cleanSweeteners,
    ...IngredientRules.cleanSweetenersHebrew,
  ];

  static bool _namesAny(List<String> ingredients, List<String> rules) {
    final text = ingredients.join(' ').toLowerCase();
    return rules.any((rule) => text.contains(rule.toLowerCase()));
  }

  // ------------------------------------------------------- stages 2 and 3

  static MacroVerdict _band(
    ParsedLabel label,
    double netCarbs, {
    required bool adjustedForPolyols,
  }) {
    final serving = label.servingGrams;
    final plausible =
        serving != null &&
        serving >= ProductVerdictConstants.minPlausibleServingG &&
        serving <= ProductVerdictConstants.maxPlausibleServingG;

    var unit = _Unit.solid;
    double? density;
    double? perServing;
    var assumed = false;

    switch (label.basis) {
      case ServingBasis.per100g:
        density = netCarbs;
      case ServingBasis.per100ml:
        unit = _Unit.liquid;
        density = netCarbs;
      case ServingBasis.perServing:
        perServing = netCarbs;
        density = plausible
            ? netCarbs / serving * ProductVerdictConstants.densityBasis
            : null;
      case ServingBasis.unknown:
        density = netCarbs;
        assumed = true;
        final mass = _declaredMass(label);
        if (mass != null) {
          // Three macros cannot outweigh the food containing them.
          if (mass > ProductVerdictConstants.densityBasis) {
            return const MacroVerdict.indeterminate(
              MacroIndeterminacy.implausibleMass,
            );
          }
          // One-directional: this can prove per-100, never per-serving.
          if (plausible && mass > serving) {
            assumed = false;
          }
        }
    }

    if (density != null && (!density.isFinite || density < 0)) {
      return const MacroVerdict.indeterminate(MacroIndeterminacy.noBasis);
    }
    if (density == null && perServing == null) {
      return const MacroVerdict.indeterminate(MacroIndeterminacy.noBasis);
    }

    if (density != null && plausible && perServing == null) {
      perServing = density * serving / ProductVerdictConstants.densityBasis;
    }

    var judgement = density == null
        // A declared serving with no weight: there is a cost, but no density
        // evidence either way.
        ? MacroJudgement.moderation
        : _bandFor(density, unit);

    if (perServing != null) {
      if (perServing > ProductVerdictConstants.servingNotKetoNetCarbG) {
        judgement = MacroJudgement.notKeto;
      } else if (perServing > ProductVerdictConstants.portionNetCarbBudgetG) {
        judgement = _worse(judgement, MacroJudgement.moderation);
      } else if (perServing <=
              ProductVerdictConstants.negligibleServingNetCarbG &&
          serving != null &&
          serving <= ProductVerdictConstants.negligibleServingMaxG) {
        // The condiment rescue: it costs almost nothing and the pack says so.
        judgement = MacroJudgement.keto;
      }
    }

    // Green is withheld under an assumed basis, and only green. If the figures
    // were really per serving and are read as per 100 g the computed density
    // understates the truth by 2.5-5x — the error is always *optimistic*,
    // because a serving is never more than 100 g. `notKeto` stays right
    // whichever reading is true and `moderation` is a request to measure;
    // `keto` is the only band that tells the user not to think.
    if (assumed && judgement == MacroJudgement.keto) {
      judgement = MacroJudgement.moderation;
    }

    return MacroVerdict(
      judgement: judgement,
      netCarbsPer100: density,
      servingNetCarbsG: perServing,
      gramsToDailyBudget: density == null || density <= 0
          ? null
          : ProductVerdictConstants.densityBasis *
                KetoConstants.defaultNetCarbTargetG /
                density,
      basisAssumed: assumed,
      adjustedForPolyols: adjustedForPolyols,
    );
  }

  /// Fat + net carbs + protein, only when all three parsed.
  ///
  /// Substituting `0` for a missing one would fire the mass proof on labels it
  /// can prove nothing about, and is forbidden anyway — a null macro means
  /// "not found", never zero.
  static double? _declaredMass(ParsedLabel label) {
    final fat = label.fatG;
    final carbs = label.netCarbsG;
    final protein = label.proteinG;
    if (fat == null || carbs == null || protein == null) {
      return null;
    }
    return fat + carbs + protein;
  }

  static MacroJudgement _bandFor(double density, _Unit unit) {
    final keto = unit == _Unit.solid
        ? ProductVerdictConstants.ketoDensitySolid
        : ProductVerdictConstants.ketoDensityLiquid;
    final notKeto = unit == _Unit.solid
        ? ProductVerdictConstants.notKetoDensitySolid
        : ProductVerdictConstants.notKetoDensityLiquid;

    if (density <= keto) {
      return MacroJudgement.keto;
    }
    return density <= notKeto
        ? MacroJudgement.moderation
        : MacroJudgement.notKeto;
  }

  /// The more severe of two judgements. Never called with `indeterminate`.
  static MacroJudgement _worse(MacroJudgement a, MacroJudgement b) =>
      _severity(a) >= _severity(b) ? a : b;

  static int _severity(MacroJudgement judgement) => switch (judgement) {
    MacroJudgement.keto => 0,
    MacroJudgement.moderation => 1,
    MacroJudgement.notKeto => 2,
    MacroJudgement.indeterminate => -1,
  };
}
