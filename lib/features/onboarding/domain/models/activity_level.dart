/// How active the user is on an ordinary day, as Mifflin-St Jeor's activity
/// factor needs it.
///
/// The five standard factors and nothing invented: `TDEE = BMR × multiplier`.
///
/// M4 asked no activity question at all and multiplied every user's BMR by
/// 1.2 — `OnboardingService.sedentaryActivityMultiplier`, now deleted — so
/// somebody who trains four times a week was measured against the targets of
/// somebody who never leaves the sofa. `design/m4_handoff.md` §Known gaps
/// calls that acceptable only because the number is editable on screen 4,
/// which is one edit, once, for every day that follows.
///
/// Stored by `name`, never by ordinal (`CLAUDE.md` §Local Persistence). A
/// record written before this field existed reads as [sedentary], because
/// 1.2 is exactly what its targets were computed with.
enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725),
  veryActive(1.9);

  const ActivityLevel(this.multiplier);

  /// The factor total daily energy expenditure is `BMR ×` this.
  final double multiplier;

  /// The tier a training day is computed at: one step up.
  ///
  /// Total, deliberately — [veryActive] is its own ceiling. Somebody who
  /// already reports training almost every day has no higher tier to borrow,
  /// and inventing a sixth factor for that one case would be a number nobody
  /// specified. The bump on such a day is therefore zero, which
  /// `DailyTargetsService.forDay` returns as the base targets unchanged.
  ActivityLevel get onTrainingDay =>
      this == veryActive ? veryActive : ActivityLevel.values[index + 1];
}
