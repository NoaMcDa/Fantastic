import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/core/utils/numeric_input.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/outcome_source.dart';
import 'package:flutter/material.dart';

/// One [IngredientOutcome], rendered as a card.
///
/// An exhaustive `switch` over the sealed [IngredientOutcome], no `default`
/// — a fifth variant becomes a compile error rather than a silently
/// unstyled row. Every variant carries its own icon **and** its own colour
/// (`design/m6_handoff.md` convention 8): colour alone is not accessible,
/// and an [Unrecognised] line must never be mistakable for an [AlreadyKeto]
/// one — the whole reason [IngredientOutcome] has four variants and not
/// three.
///
/// **The ratio is applied to the quantity, not just displayed beside it.**
/// `2 כוסות קמח` substituted at ratio 0.25 renders `0.5 כוסות`, never the
/// original `2` — a converter that keeps the original quantity produces an
/// inedible result.
class IngredientOutcomeRow extends StatelessWidget {
  const IngredientOutcomeRow({required this.outcome, super.key});

  final IngredientOutcome outcome;

  static const _cardPadding = EdgeInsetsDirectional.symmetric(
    horizontal: 12,
    vertical: 12,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // No `default`: a fifth `IngredientOutcome` variant must fail to
    // compile here, not fall through unstyled.
    return switch (outcome) {
      final Substituted substituted => _substitutedCard(theme, substituted),
      final AlreadyKeto alreadyKeto => _simpleCard(
        theme,
        icon: Icons.check_circle_outline,
        label: RecipeCopy.alreadyKeto,
        color: AppTheme.success,
        raw: alreadyKeto.ingredient.raw,
        source: alreadyKeto.source,
      ),
      final Flagged flagged => _simpleCard(
        theme,
        icon: Icons.remove_circle_outline,
        label: RecipeCopy.flagged,
        color: AppTheme.danger,
        raw: flagged.ingredient.raw,
      ),
      final Unrecognised unrecognised => _simpleCard(
        theme,
        icon: Icons.help_outline,
        label: RecipeCopy.unrecognised,
        color: AppTheme.caution,
        raw: unrecognised.ingredient.raw,
      ),
    };
  }

  Widget _substitutedCard(ThemeData theme, Substituted substituted) {
    final quantity = substituted.ingredient.quantity;
    // No quantity → no quantity shown. Never invented.
    final adjustedQuantity = quantity == null
        ? null
        : GramsText.format(quantity * substituted.substitution.ratio);
    final unit = substituted.ingredient.unit;
    final quantityLabel = adjustedQuantity == null
        ? null
        : (unit == null ? adjustedQuantity : '$adjustedQuantity $unit');

    return Card(
      child: Padding(
        padding: _cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              substituted.ingredient.raw,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.swap_horiz, color: AppTheme.accent, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      // The digit run is wrapped LTR on its own — inside the
                      // ambient RTL layout a bare number reorders.
                      if (quantityLabel != null)
                        Text(
                          quantityLabel,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Text(
                        substituted.substitution.replacement,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppTheme.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              substituted.substitution.reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (substituted.source == OutcomeSource.suggested)
              _suggestedMarker(theme, AppTheme.accent),
          ],
        ),
      ),
    );
  }

  Widget _simpleCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required String raw,
    OutcomeSource? source,
  }) {
    return Card(
      child: Padding(
        padding: _cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(raw, style: theme.textTheme.bodyMedium)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
            if (source == OutcomeSource.suggested)
              _suggestedMarker(theme, color),
          ],
        ),
      ),
    );
  }

  Widget _suggestedMarker(ThemeData theme, Color color) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 4),
    child: Text(
      RecipeCopy.suggestedMarker,
      style: theme.textTheme.labelSmall?.copyWith(color: color),
    ),
  );
}
