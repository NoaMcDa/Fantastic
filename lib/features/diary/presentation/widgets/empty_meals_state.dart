import 'package:flutter/material.dart';

/// Shown in place of the macro bars when a day has nothing logged.
///
/// Zeroed progress bars read as "you have eaten nothing and are failing every
/// target" rather than "there is no data yet" — the two look identical but
/// mean opposite things. This says which one it is.
///
/// Carries no call-to-action button: the parent screen's FAB is the action,
/// and a second button competing with it would be the wrong affordance.
class EmptyMealsState extends StatelessWidget {
  const EmptyMealsState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Colours come from the theme, not hardcoded greys: the palette is
    // dark-mode first, and a literal `Colors.grey` disappears against it.
    final mutedColor = theme.colorScheme.onSurfaceVariant;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 48,
              color: mutedColor,
              // Decorative — the text beside it already carries the meaning,
              // so a screen reader should not announce it twice.
              semanticLabel: null,
            ),
            const SizedBox(height: 12),
            Text(
              'לא נרשמו ארוחות להיום',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'הקש על + כדי להוסיף ארוחה',
              style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
