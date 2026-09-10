import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:flutter/material.dart';

/// One logged meal: its name, the time it was logged, and its macros.
///
/// Deliberately not a `ConsumerWidget` — it takes the entry it renders, so it
/// can be shown from a list, a detail view or a test without any of them
/// needing a matching provider override.
class MealCard extends StatelessWidget {
  const MealCard({required this.meal, super.key});

  final MealEntry meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(meal.mealName),
        subtitle: Text(
          _macroSummary,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          _formattedTime,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          // Clock digits, not prose — forcing LTR stops "19:30" being
          // reordered inside the RTL layout.
          textDirection: TextDirection.ltr,
        ),
      ),
    );
  }

  /// `שומן 20 · פחמימות 5 · חלבון 15`, in grams.
  String get _macroSummary =>
      'שומן ${_grams(meal.fatG)} · '
      'פחמימות ${_grams(meal.netCarbsG)} · '
      'חלבון ${_grams(meal.proteinG)}';

  /// Trims a trailing `.0` so a whole number reads as `20`, not `20.0`, while
  /// a fractional one keeps its digit.
  static String _grams(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);

  /// `HH:mm`, zero-padded.
  ///
  /// Hand-formatted rather than via `intl`: this is a fixed 24-hour clock with
  /// no locale-dependent parts, and it keeps the widget free of a dependency
  /// that would need locale data initialised in every test that renders it.
  String get _formattedTime {
    final hour = meal.timestamp.hour.toString().padLeft(2, '0');
    final minute = meal.timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
