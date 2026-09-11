import 'package:flutter/material.dart';

/// The app's one empty-state treatment: an icon, a headline, an optional
/// subtitle, and optionally an action.
///
/// Shared rather than per-feature because the two that existed before it —
/// `EmptyMealsState` in the diary and a private `_Empty` in the symptom
/// section — had drifted into two different looks, and one of them was being
/// imported across a feature boundary to reach the dashboard (#91).
///
/// Composition only: no provider access and no business logic, which is
/// Epic #11's invariant for this layer.
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    required this.icon,
    required this.headline,
    this.subtitle,
    this.action,
    super.key,
  });

  /// Decorative. The text beside it already carries the meaning, so it is
  /// excluded from semantics rather than announced twice.
  final IconData icon;

  /// What is absent. One line, stated plainly.
  final String headline;

  /// The line under the headline. Says what to do, not that there is nothing
  /// — the headline already said that.
  ///
  /// Optional because not every empty state has one to say: the symptom
  /// section's headline stands alone, and giving it a subtitle here would be
  /// inventing user-visible copy inside a refactor.
  final String? subtitle;

  /// Optional. Omit where the surrounding screen already offers the action:
  /// [EmptyMealsState] has no button because the screen's FAB is the
  /// affordance, and two would compete.
  final Widget? action;

  /// Taken from `EmptyMealsState`'s original values, so that widget renders
  /// identically after the move and its tests need no loosening.
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    vertical: 32,
    horizontal: 16,
  );
  static const double _iconSize = 48;
  static const double _gapAfterIcon = 12;
  static const double _gapAfterHeadline = 4;
  static const double _gapBeforeAction = 8;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Colours come from the theme, not hardcoded greys: the palette is
    // dark-mode first, and a literal `Colors.grey` disappears against it.
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final subtitleText = subtitle;
    final actionWidget = action;

    return Center(
      child: Padding(
        padding: _padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: _iconSize, color: mutedColor, semanticLabel: null),
            const SizedBox(height: _gapAfterIcon),
            Text(
              headline,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (subtitleText != null) ...[
              const SizedBox(height: _gapAfterHeadline),
              Text(
                subtitleText,
                style: theme.textTheme.bodySmall?.copyWith(color: mutedColor),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionWidget != null) ...[
              const SizedBox(height: _gapBeforeAction),
              actionWidget,
            ],
          ],
        ),
      ),
    );
  }
}
