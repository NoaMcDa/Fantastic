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

  /// Net carbs, in grams, at or below which a logged day counts toward the
  /// streak. Above it the day is a breach and opens the grace window.
  ///
  /// A protocol constant, deliberately **not** [defaultNetCarbTargetG]: that
  /// is the dashboard's daily *target*, which onboarding lets the user edit,
  /// and a streak that moved with an editable target would let a user grant
  /// themselves a streak by raising a number on a settings screen. The streak
  /// measures adherence to one protocol; the target measures progress against
  /// a personal plan. #303.
  ///
  /// The boundary is inclusive — exactly 50.0 g is compliant.
  static const double maxCompliantNetCarbsG = 50.0;
}
