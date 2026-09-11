/// What the user wants keto to do for them, chosen on onboarding screen 3.
///
/// Only [weightLoss] changes the arithmetic today: it applies a 20% deficit
/// to TDEE in `OnboardingService.calculateMacroTargets`. The other two are
/// recorded for the post-MVP dashboard emphasis `design/ui_ux_design.md` §1c
/// describes, and are deliberately identical in effect until then rather than
/// invented differences nobody has specified.
///
/// These three values, and not `ui_ux_design.md`'s original
/// energy/medical pair, are the ones that ship — see
/// `design/m4_preflight.md` §6.1, which also records why the choice is worth
/// revisiting.
///
/// Stored by `name`, never by ordinal (`CLAUDE.md` §Local Persistence).
enum KetoGoal { weightLoss, metabolicHealth, athleticPerformance }
