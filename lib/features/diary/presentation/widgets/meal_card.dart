import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/presentation/macro_source_copy.dart';
import 'package:flutter/material.dart';

/// One logged meal: its name, the time it was logged, and its macros.
///
/// Deliberately not a `ConsumerWidget` — it takes the entry it renders, so it
/// can be shown from a list, a detail view or a test without any of them
/// needing a matching provider override. The provenance badge changes nothing
/// about that: it is derived from `meal.source`, with no new state, no new
/// provider and no database read.
///
/// **A meal the user typed, a meal Tesseract read off a printed panel and a
/// meal a model guessed rendered identically until this badge existed.** They
/// are not the same kind of datum. `MealLoggingService` rolls all three into
/// the day's `DailyLog` and hands the day to `AdaptationPhaseService`, so a
/// wrong estimate can break a streak — and a user looking at the day that
/// broke theirs has to be able to see, without tapping anything, which of its
/// meals were measured and which were guessed. Otherwise the only available
/// conclusion is that the app is wrong, which they cannot check.
///
/// The M6 precedent is `IngredientVerdict.recognisedNothing`, which exists so
/// the UI can tell "nothing here is bad" from "nothing here was readable".
/// Same problem, different screen.
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
        subtitle: _Subtitle(meal: meal, summary: _macroSummary),
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

/// The macro summary, and the provenance badge when there is one.
///
/// A `Wrap` rather than a `Row`: a long meal name with a badge beside it is
/// the overflow case, and at the smallest phone width with the largest text
/// scale the badge has to drop to its own line rather than paint a yellow
/// stripe across the card.
class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.meal, required this.summary});

  final MealEntry meal;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final label = meal.source.badgeLabel;
    if (label == null) {
      // A manual meal's card is byte-identical to what it was before this
      // badge existed. Most meals are manual, and manual entry is the whole
      // milestone's regression surface.
      return Text(summary, style: style);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(summary, style: style),
        _SourceBadge(source: meal.source, label: label, style: style),
      ],
    );
  }
}

/// The quiet marker itself.
///
/// Subordinate to the macro figures on purpose — it is drawn in the same
/// `bodySmall` on `onSurfaceVariant` the summary uses rather than in the
/// accent. An estimate is still the user's own data, not a warning, and a
/// badge that shouted would make every estimated meal look like a mistake.
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({
    required this.source,
    required this.label,
    required this.style,
  });

  final MacroSource source;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = source.badgeDescription;

    // `container` and `excludeSemantics` together, not `label` alone. Without
    // them the node merges with its own children and a screen reader
    // announces the two-character chip text — "הערכה" — instead of the
    // sentence that says what it means. The description subsumes the label,
    // so dropping the child's semantics loses nothing.
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: description,
      child: Tooltip(
        message: description ?? '',
        child: Container(
          key: const Key('meal_card_source_badge'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                source.badgeIcon,
                size: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              // `Flexible`, because a `Wrap` hands its child the run's width
              // and the chip has to fit inside it. At the largest text scale
              // on the narrowest phone this row overflows by 12 px without
              // it — measured, not guessed.
              Flexible(child: Text(label, style: style)),
            ],
          ),
        ),
      ),
    );
  }
}
