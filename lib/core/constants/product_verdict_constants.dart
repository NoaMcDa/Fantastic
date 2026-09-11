/// Portions and a carb budget for judging one packaged product.
///
/// Every band edge in the product verdict is **computed** from these, never
/// typed — which is what makes the edges answerable. "Why 25 g per 100 g?"
/// has an answer: it is 5 g of carbs in a 20 g portion.
///
/// A separate file rather than more of `KetoConstants`: that one is about a
/// user's *daily targets*, and these are about *one product*.
abstract final class ProductVerdictConstants {
  /// A quarter of `KetoConstants.defaultNetCarbTargetG` — the cost of one
  /// food, four of which are a day.
  ///
  /// The single judgement call in the scheme; everything else is division.
  static const double portionNetCarbBudgetG = 5.0;

  /// Half the day in one unit the manufacturer itself calls a serving.
  static const double servingNotKetoNetCarbG = 10.0;

  /// A portion you never have to measure.
  static const double freePortionG = 100.0;

  /// A portion you do.
  static const double measuredPortionG = 20.0;

  /// The same, for a liquid: a glass.
  static const double freePortionMl = 250.0;

  /// And a splash.
  static const double measuredPortionMl = 100.0;

  /// A condiment: it costs almost nothing and the pack says so.
  static const double negligibleServingNetCarbG = 1.0;
  static const double negligibleServingMaxG = 20.0;

  /// A declared serving outside this range was mis-read, not printed.
  static const double minPlausibleServingG = 1.0;
  static const double maxPlausibleServingG = 500.0;

  /// Atwater factors, for the panel's check on itself.
  static const double kcalPerGramFat = 9.0;
  static const double kcalPerGramCarb = 4.0;
  static const double kcalPerGramProtein = 4.0;
  static const double kcalPerGramFibre = 2.0;

  /// How far the panel may disagree with itself before it is treated as
  /// mis-read.
  ///
  /// A mis-read detector, not a precision instrument: it has to absorb the
  /// fibre-inside-or-outside-carbohydrate convention ambiguity, polyols at
  /// 2.4 kcal/g and rounding, while a dropped or transposed digit in the carb
  /// row moves the energy figure by far more.
  static const double energyCrossCheckTolerance = 0.25;

  /// Unit conversion, not a threshold: densities are "per hundred".
  static const double densityBasis = 100.0;

  /// Net carbs per 100 g at or below which a solid is [MacroJudgement.keto] —
  /// the budget spent over a portion you never measure.
  static double get ketoDensitySolid =>
      portionNetCarbBudgetG / freePortionG * densityBasis;

  /// And above which it is [MacroJudgement.notKeto] — the budget spent over a
  /// portion you do.
  static double get notKetoDensitySolid =>
      portionNetCarbBudgetG / measuredPortionG * densityBasis;

  /// The liquid equivalents, per 100 ml.
  static double get ketoDensityLiquid =>
      portionNetCarbBudgetG / freePortionMl * densityBasis;

  static double get notKetoDensityLiquid =>
      portionNetCarbBudgetG / measuredPortionMl * densityBasis;
}
