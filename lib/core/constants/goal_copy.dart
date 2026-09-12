import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';

/// Hebrew copy for each [KetoGoal].
///
/// Const strings in `core/` rather than literals inside the widget, following
/// `PhaseCopy`: the text is reviewable in one place, a copy change is not a
/// widget change, and a later profile screen showing the chosen goal reads
/// the same words the user picked.
///
/// One or more of these may be chosen: the reasons are not exclusive, and
/// asking somebody who wants to lose weight *and* train well to drop one was
/// a limitation of M4's radio group, not a product decision.
///
/// These three goals replace the energy/medical pair
/// `design/ui_ux_design.md` §1c originally listed — see
/// `design/m4_preflight.md` §6.1, which also records why that is worth
/// revisiting.
abstract final class GoalCopy {
  /// The order the cards are shown in, and the order `UserProfileMapper`
  /// writes a goal set in, so two profiles with the same goals produce
  /// byte-identical records. Weight loss first: it is the most common reason
  /// people start keto.
  static const List<KetoGoal> order = [
    KetoGoal.weightLoss,
    KetoGoal.metabolicHealth,
    KetoGoal.athleticPerformance,
  ];

  static const Map<KetoGoal, String> titles = {
    KetoGoal.weightLoss: 'ירידה במשקל',
    KetoGoal.metabolicHealth: 'בריאות מטבולית',
    KetoGoal.athleticPerformance: 'ביצועים ספורטיביים',
  };

  /// Said on screen 3, because a set of cards that each look tappable does
  /// not by itself say more than one may be chosen.
  static const String pickMoreThanOneHint = 'אפשר לבחור יותר מאחת';

  static const Map<KetoGoal, String> subtitles = {
    KetoGoal.weightLoss: 'שריפת שומן תוך שמירה על מסת שריר',
    KetoGoal.metabolicHealth: 'איזון סוכר וסמנים דלקתיים',
    KetoGoal.athleticPerformance: 'אנרגיה יציבה לאורך היום, בלי נפילות',
  };
}
