import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';

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

  /// The induction net-carb allowance, in grams, and the **floor** every
  /// calculated net-carb target is clamped up to.
  ///
  /// It was `OnboardingService.inductionNetCarbsG` and it was the whole
  /// answer: every user got 20 g, whoever they were, while fat and protein
  /// were derived from their body. It is now the bottom of the band
  /// [netCarbTargetByActivity] starts from.
  static const double inductionNetCarbsG = 20.0;

  /// The calculator's starting net-carb target, in grams, by activity level.
  ///
  /// **Product defaults, not protocol.** The protocol invariant is the clamp
  /// in `OnboardingService.netCarbTargetFor` — every value here, and every
  /// value reachable after [athleticPerformanceNetCarbBonusG] and
  /// [weightLossNetCarbCapG] are applied, lies inside
  /// [inductionNetCarbsG]–[maxCompliantNetCarbsG], so the calculator can
  /// never propose a target that is itself a streak breach. Change the table
  /// freely; do not change the clamp.
  ///
  /// More activity means more glycogen turnover and more room for carbs
  /// before ketosis is disturbed, which is why the numbers rise with the
  /// tier. The two lowest tiers share the induction floor deliberately:
  /// somebody who barely moves has no such room.
  static const Map<ActivityLevel, double> netCarbTargetByActivity = {
    ActivityLevel.sedentary: 20.0,
    ActivityLevel.light: 20.0,
    ActivityLevel.moderate: 25.0,
    ActivityLevel.active: 30.0,
    ActivityLevel.veryActive: 35.0,
  };

  /// Added, in grams, when `KetoGoal.athleticPerformance` is one of the goals.
  static const double athleticPerformanceNetCarbBonusG = 5.0;

  /// The ceiling, in grams, when `KetoGoal.weightLoss` is one of the goals.
  ///
  /// A deficit is the point of that goal and carbs are the first thing held
  /// down, so this wins over [athleticPerformanceNetCarbBonusG] when the user
  /// chose both.
  static const double weightLossNetCarbCapG = 25.0;

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
