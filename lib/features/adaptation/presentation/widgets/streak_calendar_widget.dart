import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/adaptation/domain/models/day_compliance.dart';
import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A month of compliance at a glance: one cell per day, coloured by whether
/// that day's net carbs stayed within the streak's limit.
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
              ),
            );
          },
        ),
      ],
    );
  }

  /// How [date] should be coloured, given the log it does or does not have.
  ///
  /// Delegates to [DayCompliance], which is the *only* definition of a
  /// compliant day. This method used to compute a keto ratio and compare it to
  /// the target — a second, independent copy of the streak's rule, so the month
  /// grid and the ring could disagree about the same day and changing one
  /// changed only half the app (#303).
  ///
  /// The future guard stays here: it is a rendering concern, not a compliance
  /// one. A day that has not happened is neither compliant nor a breach.
  static _DayStatus _statusFor(DateTime date, DailyLog? log) {
    if (date.isAfter(DateTime.now())) {
      return _DayStatus.future;
    }
    return switch (DayCompliance.of(log)) {
      DayStatus.compliant => _DayStatus.compliant,
      DayStatus.breach => _DayStatus.breach,
      DayStatus.unlogged => _DayStatus.unlogged,
    };
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
