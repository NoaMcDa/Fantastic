import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';

/// What one calendar day is worth to the streak.
enum DayStatus {
  /// Meals were logged and the day's net carbs are within the limit.
  compliant,

  /// Meals were logged and the day's net carbs exceed the limit.
  breach,

  /// Nothing was logged. Not a failure on today, which is still winnable;
  /// a break on any earlier day.
  unlogged,
}

/// The single definition of a compliant day.
///
/// The rule lived in two places — the streak evaluation in
/// `MealLoggingService` and `StreakCalendarWidget._statusFor` — so the ring
/// and the month grid could disagree about the same day, and changing one
/// silently changed only half the app (#303).
///
/// **The keto ratio does not participate.** It used to: compliance was
/// `ketoRatioAvg >= 2.0`, and since the ratio is `fat / (netCarbs + protein)`
/// protein sat in the denominator beside carbs. A disciplined 8 g-carb day
/// with 90 g of protein scored 0.31 and broke the streak; 100 g of fat with
/// 50 g of carbs and no protein scored exactly 2.0 and passed. The rule was
/// close to inverted relative to what a keto user expects.
abstract final class DayCompliance {
  /// What [log] is worth, where null means the day has no record at all.
  static DayStatus of(DailyLog? log) {
    if (log == null || _nothingLogged(log)) {
      return DayStatus.unlogged;
    }
    return log.totalNetCarbsG <= KetoConstants.maxCompliantNetCarbsG
        ? DayStatus.compliant
        : DayStatus.breach;
  }

  /// Whether [log] exists but records no food.
  ///
  /// **A log with no meals is not the same thing as a zero-carb day**, and
  /// `DailyLog` carries no meal count to tell them apart. `MealLoggingService`
  /// upserts a row with zeroed macros when the last meal of a day is deleted —
  /// water and the three electrolytes live on the same row and must survive —
  /// so an all-zero macro triple is the only available signal that nothing was
  /// eaten.
  ///
  /// All three macros, not two. The old calendar test read
  /// `totalNetCarbsG + totalProteinG == 0`, which made a fat-only morning
  /// *unlogged*. Under a carb rule that same day has 0 g of net carbs, which
  /// is the best possible day — so fat has to count as food.
  ///
  /// The consequence, stated rather than buried: **a meal logged with all
  /// three macros at zero reads as an unlogged day.** That is degenerate
  /// input. The alternative — a `mealCount` field on `DailyLog` — changes the
  /// model, the mapper, the contract suite and every stored record, where a
  /// missing key would decode as `0` and make every existing day read unlogged,
  /// wiping the user's streak on upgrade. Rejected for that reason; recorded
  /// here so the next reader does not "fix" it casually.
  static bool _nothingLogged(DailyLog log) =>
      log.totalFatG == 0 && log.totalNetCarbsG == 0 && log.totalProteinG == 0;
}
