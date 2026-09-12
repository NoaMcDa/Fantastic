/// What the user wants keto to do for them, chosen on onboarding screen 3.
///
/// **Chosen as a set, not one at a time** — the reasons are not exclusive,
/// and M4's radio group made somebody who wants both drop one. See
/// `OnboardingData.goals`.
///
/// Two of the three change the arithmetic. [weightLoss] applies a 20% deficit
/// to TDEE, and to the training-day bump on top of it. [athleticPerformance]
/// raises the net-carb target by
/// `KetoConstants.athleticPerformanceNetCarbBonusG` — and weight loss caps the
/// result when both are chosen, because a deficit is the point of that goal.
/// [metabolicHealth] is recorded for the post-MVP dashboard emphasis
/// `design/ui_ux_design.md` §1c describes, and is deliberately without effect
/// until then rather than given a difference nobody has specified.
///
/// These three values, and not `ui_ux_design.md`'s original
/// energy/medical pair, are the ones that ship — see
/// `design/m4_preflight.md` §6.1, which also records why the choice is worth
/// revisiting.
///
/// Stored by `name`, never by ordinal (`CLAUDE.md` §Local Persistence).
enum KetoGoal { weightLoss, metabolicHealth, athleticPerformance }
