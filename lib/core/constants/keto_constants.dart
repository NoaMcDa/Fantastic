/// Keto ratio and default macro target constants.
///
/// See `design/technology.md` §2 for the underlying formulas:
/// `Keto Ratio = fatG / (netCarbsG + proteinG)`,
/// `Net Carbs = totalCarbsG − dietaryFiberG`.
abstract final class KetoConstants {
  static const double targetKetoRatioMin = 1.5;
  static const double targetKetoRatioIdeal = 2.0;
  static const double defaultNetCarbTargetG = 20.0;
  static const double defaultFatTargetG = 150.0;
  static const double defaultProteinTargetG = 80.0;
}
