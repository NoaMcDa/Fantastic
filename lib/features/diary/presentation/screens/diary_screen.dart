import 'package:fantastic/core/time/today_tracker.dart';
import 'package:fantastic/features/diary/presentation/screens/diary_day_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Diary tab: a horizontal strip of recent days above the selected day's
/// entries.
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  /// How many days back the strip offers.
  static const int visibleDays = 30;

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> with TodayTracker {
  /// The selected day. Starts on [today] and follows it across a rollover.
  ///
  /// Every chip is derived from [today] and every date-keyed provider is
  /// keyed on the result, so it must not be recomputed per build — see
  /// `DashboardScreen` for the same reasoning, and [TodayTracker] for why
  /// "resolved once" was not good enough.
  late DateTime _selectedDate = today;

  /// Keeps the selection on *today* across a midnight rollover.
  ///
  /// Only when it was already there: a user reading Tuesday at 00:01 on
  /// Wednesday asked for Tuesday and should keep it. A user sitting on today
  /// asked for today, and today has moved.
  @override
  void onTodayChanged(DateTime previous) {
    if (_selectedDate == previous) {
      _selectedDate = today;
    }
  }

  /// Newest first.
  ///
  /// Built by subtracting from the day-of-month rather than with a
  /// `Duration(days:)`, which is a fixed 24 hours and lands on the wrong day
  /// across a daylight-saving change. `DateTime` normalises a non-positive day
  /// into the previous month.
  List<DateTime> get _dates => [
    for (var i = 0; i < DiaryScreen.visibleDays; i++)
      DateTime(today.year, today.month, today.day - i),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('יומן')),
      body: Column(
        children: [
          SizedBox(
            height: 72,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _dates.length,
              itemBuilder: (context, index) {
                final date = _dates[index];
                return _DateChip(
                  date: date,
                  selected: date == _selectedDate,
                  isToday: date == today,
                  onTap: () => setState(() => _selectedDate = date),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Expanded(child: DiaryDayScreen(date: _selectedDate)),
        ],
      ),
    );
  }
}

/// One day in the strip: weekday letter above the date number.
class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool isToday;
  final VoidCallback onTap;

  /// Hebrew weekday initials, indexed by `DateTime.weekday` (1 = Monday).
  ///
  /// Hand-written rather than via `intl`: these are single characters with no
  /// formatting rules, and using `DateFormat` here would make every test that
  /// renders the strip depend on Hebrew locale data being initialised.
  static const List<String> _weekdayInitials = [
    'ב', // Monday
    'ג',
    'ד',
    'ה',
    'ו',
    'ש', // Saturday
    'א', // Sunday
  ];

  String get _weekdayInitial => _weekdayInitials[date.weekday - 1];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Material(
        color: selected ? colors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            // 44pt minimum touch target, per Apple's HIG.
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _weekdayInitial,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? colors.onPrimary
                        : colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${date.day}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: selected ? colors.onPrimary : colors.onSurface,
                    // Today stays distinguishable even when another day is
                    // selected — selection colour alone would hide it.
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
