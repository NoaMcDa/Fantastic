import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/features/dashboard/application/keto_ratio_calculator.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/diary/presentation/widgets/empty_meals_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The dashboard's hero widget: four bars showing the day's fat, net carbs,
/// protein and keto ratio against their targets.
///
/// Targets are the `KetoConstants` defaults for MVP. Onboarding (M4) will
/// persist per-user targets and this reads them instead.
class MacroSummaryCard extends ConsumerWidget {
  const MacroSummaryCard({required this.date, super.key});

  /// Pass a date-only value — `todaysDailyLogProvider` is keyed on it, and a
  /// wall-clock time recomputed each build would refetch forever.
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(todaysDailyLogProvider(date));

    return logAsync.when(
      // A bare progress spinner is deliberate rather than a skeleton: the
      // skeleton (#88-#94, M7 polish) does not exist yet, and the issue's
      // reference to "issue #75" points into M5's symptom-diary range.
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      // A failed read is not "no meals" — saying so would be a lie the user
      // acts on. The card states the failure instead.
      error: (_, _) => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text('לא ניתן לטעון את הנתונים')),
        ),
      ),
      data: (log) => log == null
          ? const Card(child: EmptyMealsState())
          : _MacroSummary(log: log, ratio: _ratioOf(log, ref)),
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
  const _MacroSummary({required this.log, required this.ratio});

  final DailyLog log;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MacroProgressRow(
              label: 'שומן',
              logged: log.totalFatG,
              target: KetoConstants.defaultFatTargetG,
              unit: 'ג׳',
              color: colors.tertiary,
            ),
            _MacroProgressRow(
              label: 'פחמימות נטו',
              logged: log.totalNetCarbsG,
              target: KetoConstants.defaultNetCarbTargetG,
              unit: 'ג׳',
              color: colors.error,
            ),
            _MacroProgressRow(
              label: 'חלבון',
              logged: log.totalProteinG,
              target: KetoConstants.defaultProteinTargetG,
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
              color: colors.primary,
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
  });

  final String label;
  final double logged;
  final double target;
  final String unit;
  final Color color;
  final int decimals;

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
              Text(label, style: theme.textTheme.bodyMedium),
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
