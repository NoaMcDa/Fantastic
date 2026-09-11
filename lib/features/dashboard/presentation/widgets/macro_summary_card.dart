import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/core/theme/keto_ratio_palette.dart';
import 'package:fantastic/features/dashboard/application/keto_ratio_calculator.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/diary/presentation/widgets/empty_meals_state.dart';
import 'package:fantastic/features/onboarding/application/providers/user_profile_providers.dart';
import 'package:fantastic/features/onboarding/domain/models/macro_targets.dart';
import 'package:fantastic/features/dashboard/presentation/widgets/macro_summary_card_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The dashboard's hero widget: four bars showing the day's fat, net carbs,
/// protein and keto ratio against their targets.
///
/// Targets come from the profile onboarding saved (#73), falling back to
/// `MacroTargets.defaults` — the `KetoConstants` values this card read
/// directly through M2 and M3 — until someone has onboarded. Epic #8's
/// Definition of Done requires the dashboard to show what onboarding set;
/// no M4 child issue asked for this change, which is why
/// `design/m4_preflight.md` §5.3 records it.
class MacroSummaryCard extends ConsumerWidget {
  const MacroSummaryCard({required this.date, super.key});

  /// Pass a date-only value — `todaysDailyLogProvider` is keyed on it, and a
  /// wall-clock time recomputed each build would refetch forever.
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(todaysDailyLogProvider(date));
    final targetsAsync = ref.watch(macroTargetsProvider);

    // `hasError` is checked before loading, and deliberately. riverpod 3
    // reports a provider that failed *before ever producing a value* as
    // `AsyncLoading` **with an error attached** — both flags are true — so an
    // `isLoading`-first check shows a spinner that never resolves. This cost
    // M3 three issues; see `design/m3_handoff.md`.
    if (logAsync.hasError || targetsAsync.hasError) {
      // A failed read is not "no meals" — saying so would be a lie the user
      // acts on. The card states the failure instead. That covers the targets
      // too: silently falling back to the defaults would show someone a goal
      // they never set, next to a number they are being judged against.
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('לא ניתן לטעון את הנתונים')),
        ),
      );
    }

    if (!logAsync.hasValue || !targetsAsync.hasValue) {
      return const MacroSummaryCardSkeleton();
    }

    // A day with nothing logged has no `DailyLog` at all, and every total on
    // one already defaults to zero — so a zeroed stand-in needs no zeroing
    // code and no `DailyLog.empty` factory (`design/m2_preflight.md` records
    // that symbol as one that does not exist and should not be invented).
    final stored = logAsync.requireValue;
    final log = stored ?? DailyLog(date: date);

    return _MacroSummary(
      log: log,
      ratio: _ratioOf(log, ref),
      targets: targetsAsync.requireValue,
      isEmptyDay: stored == null,
    );
  }

  double _ratioOf(DailyLog log, WidgetRef ref) => ref
      .watch(ketoRatioCalculatorProvider)
      .calculate(
        fat: log.totalFatG,
        netCarbs: log.totalNetCarbsG,
        protein: log.totalProteinG,
      );
}

class _MacroSummary extends StatelessWidget {
  const _MacroSummary({
    required this.log,
    required this.ratio,
    required this.targets,
    required this.isEmptyDay,
  });

  final DailyLog log;
  final double ratio;
  final MacroTargets targets;

  /// Whether the day has no `DailyLog` at all.
  ///
  /// The message goes **above** the bars rather than replacing them.
  /// `EmptyMealsState`'s own doc comment makes the objection this has to
  /// survive: *"zeroed progress bars read as 'you have eaten nothing and are
  /// failing every target' rather than 'there is no data yet' — the two look
  /// identical but mean opposite things."* That is correct, and the answer is
  /// to show both, so the message disambiguates the zeros instead of hiding
  /// the targets the user just agreed to (#301).
  ///
  /// A `DailyLog` that exists with all-zero totals is **not** this: a
  /// logged-then-emptied day is a different fact from an unlogged one.
  final bool isEmptyDay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isEmptyDay) ...[
              // The line, not the whole centred block: as a header above the
              // bars the full treatment is taller than the content it
              // introduces, and on a 640px screen it pushes the streak ring
              // below the fold on first launch.
              Text(
                EmptyMealsState.headline,
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            _MacroProgressRow(
              label: 'שומן',
              logged: log.totalFatG,
              target: targets.fatG,
              unit: 'ג׳',
              color: colors.tertiary,
            ),
            _MacroProgressRow(
              label: 'פחמימות נטו',
              logged: log.totalNetCarbsG,
              target: targets.netCarbsG,
              unit: 'ג׳',
              color: colors.error,
            ),
            _MacroProgressRow(
              label: 'חלבון',
              logged: log.totalProteinG,
              target: targets.proteinG,
              unit: 'ג׳',
              color: colors.secondary,
            ),
            _MacroProgressRow(
              label: 'יחס קטו',
              logged: ratio,
              target: KetoConstants.targetKetoRatioIdeal,
              // A ratio is dimensionless, and one decimal is the precision
              // the number is meaningful to.
              unit: '',
              decimals: 1,
              // **The one row whose colour is a verdict.** The three above
              // carry fixed hues so fat, carbs and protein can be told apart
              // from one another — an identity, not a judgement, and
              // recolouring those by progress is a different and much larger
              // product decision. This row's *value* has a good/marginal/bad
              // reading, and it used to be painted a fixed gold that said
              // nothing while the streak ring directly above it said green,
              // amber or red about the same number (#305).
              //
              // An unlogged day is neutral rather than red. A ratio of 0.0
              // from an empty day is not a bad day — it is no day yet, and a
              // red bar on someone's first morning, under a headline saying
              // nothing has been logged, is a verdict on something that has
              // not happened. The issue left this open; this is the answer.
              color: isEmptyDay
                  ? colors.onSurfaceVariant
                  : KetoRatioPalette.colourFor(ratio),
              icon: isEmptyDay ? null : KetoRatioPalette.iconFor(ratio),
              semanticLabel: isEmptyDay
                  ? null
                  : KetoRatioPalette.labelFor(ratio),
            ),
          ],
        ),
      ),
    );
  }
}

/// One labelled bar: name on one side, `logged / target` on the other.
class _MacroProgressRow extends StatelessWidget {
  const _MacroProgressRow({
    required this.label,
    required this.logged,
    required this.target,
    required this.unit,
    required this.color,
    this.decimals = 0,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final double logged;
  final double target;
  final String unit;
  final Color color;
  final int decimals;

  /// A non-colour signal beside the label.
  ///
  /// Null on the three macro rows, and on the ratio row for an unlogged day.
  /// Colour is never the only signal (`design/m6_handoff.md` convention 8),
  /// but a fixed hue that identifies a macro has nothing to signal.
  final IconData? icon;

  /// What [icon] means, in words.
  ///
  /// An icon without one is no better than a colour for a screen reader.
  final String? semanticLabel;

  /// Clamped to `[0, 1]`.
  ///
  /// Over-target is capped so the bar cannot overflow its track — the numeric
  /// readout beside it still shows the real figure, so nothing is hidden. A
  /// zero or negative target would divide by zero, so it reads as empty.
  double get _progress {
    if (target <= 0) {
      return 0;
    }
    return (logged / target).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: color,
                      semanticLabel: semanticLabel,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(label, style: theme.textTheme.bodyMedium),
                ],
              ),
              Text(
                '${logged.toStringAsFixed(decimals)}'
                '/${target.toStringAsFixed(decimals)}$unit',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                // The readout is digits either way; forcing LTR keeps
                // "120/150" from being reordered inside the RTL layout.
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              color: color,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
