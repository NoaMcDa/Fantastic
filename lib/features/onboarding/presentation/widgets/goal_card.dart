import 'package:flutter/material.dart';

/// One selectable goal on onboarding screen 3.
///
/// #71 names this widget in its Approach table and never writes it
/// (`design/m4_preflight.md` §2).
///
/// Selection is drawn with a border and a tinted fill rather than a
/// checkbox: three mutually exclusive cards are a radio group, and a card
/// that looks checkable individually invites a second tap.
class GoalCard extends StatelessWidget {
  const GoalCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Semantics(
      // A card in a single-select group is a radio button, whatever it is
      // drawn as. Without this a screen reader announces three unrelated
      // buttons and never says which one is chosen.
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      child: Card(
        // Zero margin: the column owns the spacing, so the cards cannot end
        // up with different gaps from the fields on the screen before.
        margin: EdgeInsets.zero,
        color: selected
            ? colors.primary.withValues(alpha: 0.12)
            : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 32,
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
