import 'package:fantastic/core/widgets/app_illustration.dart';
import 'package:fantastic/core/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';

/// Shown in place of the macro bars when a day has nothing logged.
///
/// Zeroed progress bars read as "you have eaten nothing and are failing every
/// target" rather than "there is no data yet" — the two look identical but
/// mean opposite things. This says which one it is.
///
/// Carries no call-to-action button: the parent screen's FAB is the action,
/// and a second button competing with it would be the wrong affordance.
///
/// Kept as a named widget rather than folded into [EmptyStateWidget] at every
/// call site: the dashboard, its own tests and an e2e flow all name it, and
/// `EmptyStateWidget` is deliberately not named after any one feature (#91).
class EmptyMealsState extends StatelessWidget {
  const EmptyMealsState({super.key});

  /// The headline, as its own constant.
  ///
  /// `MacroSummaryCard` shows this line *above* its bars on a day with nothing
  /// logged, where the full centred block would be a header taller than the
  /// content it introduces — enough to push the streak ring off the first
  /// screen. One definition either way, so the two cannot drift (#301).
  static const String headline = 'לא נרשמו ארוחות להיום';

  @override
  Widget build(BuildContext context) => EmptyStateWidget(
    icon: Icons.restaurant_menu_outlined,
    illustration: EmptyPlateIllustration(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    headline: headline,
    subtitle: 'הקש על + כדי להוסיף ארוחה',
  );
}
