import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/dashboard/application/keto_ratio_calculator.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A month of compliance at a glance: one cell per day, coloured by whether
/// that day's keto ratio cleared the target.
class StreakCalendarWidget extends ConsumerWidget {
  const StreakCalendarWidget({required this.month, super.key});

  /// Any day inside the month to draw. Only the year and month are read.
  ///
  /// **Pass a date-only value** — `monthlyDailyLogsProvider` is a family
  /// keyed on it, and a wall-clock time recomputed each build would allocate
  /// a new provider every frame.
  final DateTime month;

  /// Sunday first, as the Hebrew week runs.
  ///
  /// The issue offsets by `firstWeekday - 1`, which is Monday-first. In an
  /// Israeli calendar that shifts every cell by one column and puts Saturday
  /// at the start of the week.
  static const List<String> weekdayInitials = [
    'א',
    'ב',
    'ג',
    'ד',
    'ה',
    'ו',
    'ש',
  ];

  /// Blank cells before the first of the month.
  ///
  /// `DateTime.weekday` is 1=Monday…7=Sunday, so `% 7` maps Sunday to 0 and
  /// leaves the rest in Sunday-first order.
  static int leadingBlanks(DateTime month) =>
      DateTime(month.year, month.month).weekday % 7;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(monthlyDailyLogsProvider(month));
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final blanks = leadingBlanks(month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final initial in weekdayInitials)
              Expanded(
                child: Center(
                  child: Text(
                    initial,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          // The grid is inside a scrolling parent; it must not scroll itself.
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: blanks + days,
          itemBuilder: (context, index) {
            final day = index - blanks + 1;
            if (day < 1) {
              return const SizedBox.shrink();
            }
            return _DayCell(
              day: day,
              status: _statusFor(
                DateTime(month.year, month.month, day),
                logsAsync.value?[day],
                ref,
              ),
            );
          },
        ),
      ],
    );
  }

  /// How [date] should be coloured, given the log it does or does not have.
  ///
  /// A day whose net carbs and protein are both zero counts as **unlogged**,
  /// not as a breach. The ratio is `fat / (netCarbs + protein)` and
  /// `KetoRatioCalculator` reports a zero denominator as `0`, which would
  /// paint a fat-only morning red — and would contradict the streak, since
  /// `MealLoggingService` deliberately does not evaluate such a day either
  /// (`design/m3_preflight.md` §1.3).
  static _DayStatus _statusFor(DateTime date, DailyLog? log, WidgetRef ref) {
    if (date.isAfter(DateTime.now())) {
      return _DayStatus.future;
    }
    if (log == null || log.totalNetCarbsG + log.totalProteinG == 0) {
      return _DayStatus.unlogged;
    }
    final ratio = ref
        .watch(ketoRatioCalculatorProvider)
        .calculate(
          fat: log.totalFatG,
          netCarbs: log.totalNetCarbsG,
          protein: log.totalProteinG,
        );
    return ratio >= KetoConstants.targetKetoRatioIdeal
        ? _DayStatus.compliant
        : _DayStatus.breach;
  }
}

enum _DayStatus { compliant, breach, unlogged, future }

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.status});

  final int day;
  final _DayStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = switch (status) {
      _DayStatus.compliant => AppTheme.success,
      _DayStatus.breach => AppTheme.danger,
      _DayStatus.unlogged => scheme.surfaceContainerHighest,
      // Fainter than unlogged: a day that has not happened yet is not the
      // same as one the user skipped.
      _DayStatus.future => scheme.surfaceContainerHighest.withValues(
        alpha: 0.4,
      ),
    };
    final onFill = switch (status) {
      _DayStatus.compliant || _DayStatus.breach => Colors.white,
      _ => scheme.onSurfaceVariant,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          '$day',
          style: Theme.of(context).textTheme.labelMedium
              ?.copyWith(color: onFill),
          // A bare digit run needs its own direction inside the RTL layout.
          textDirection: TextDirection.ltr,
        ),
      ),
    );
  }
}
