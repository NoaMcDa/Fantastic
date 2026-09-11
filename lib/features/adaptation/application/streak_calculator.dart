import 'package:fantastic/features/adaptation/domain/models/day_compliance.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:meta/meta.dart';

/// The counter and the most recent day that earned it.
@immutable
class StreakDerivation {
  const StreakDerivation({required this.streak, this.lastCompliantDate});

  /// Compliant days counted back from the evaluation instant.
  final int streak;

  /// The most recent day counted, or null when [streak] is zero.
  final DateTime? lastCompliantDate;
}

/// Derives the current streak from the logged day history.
///
/// Pure: no repository, no clock — `now` is a parameter, which is what keeps
/// every test of it deterministic.
///
/// The streak is one counter, as it always was. What changes is where the
/// number comes from: counting back over [DailyLog] rather than adding one per
/// compliant meal-write. That is what makes a retroactive edit correct by
/// construction — the walk reads whatever the history now says, whenever it
/// changed, with no back-dated arithmetic, no monotonicity guard and no `+1`
/// accumulation to get wrong (#303).
abstract final class StreakCalculator {
  /// How far back the walk will go before stopping regardless.
  ///
  /// A bound, not a rule: it exists so a corrupted or far-future record cannot
  /// spin the loop, not because a 366-day streak is disallowed.
  static const int maxDays = 365;

  /// Days counted back from [now] while each one qualifies.
  ///
  /// [gracedDate] is the one breached day an unexpired grace window forgives;
  /// null when there is none.
  ///
  /// Three things end the walk, and only three: an `unlogged` day that is not
  /// today, a `breach` that is not [gracedDate], and [maxDays].
  static StreakDerivation derive({
    required List<DailyLog> logs,
    required DateTime now,
    DateTime? gracedDate,
  }) {
    // Keyed by midnight-normalised DateTime rather than by the store's
    // `dateIndex` encoding: two DateTimes built from the same y/m/d compare
    // and hash equal, so this needs no encoding at all and cannot drift from
    // one. `logs` is whatever `findAll()` returned — no order is assumed.
    final byDay = <DateTime, DailyLog>{
      for (final log in logs) dateOnly(log.date): log,
    };

    var cursor = dateOnly(now);
    var streak = 0;
    DateTime? lastCompliantDate;

    for (var stepsBack = 0; stepsBack < maxDays; stepsBack++) {
      final status = DayCompliance.of(byDay[cursor]);

      if (status == DayStatus.compliant) {
        streak++;
        // The walk runs backwards, so the first compliant day it meets is the
        // most recent one.
        lastCompliantDate ??= cursor;
      } else if (status == DayStatus.unlogged && stepsBack == 0) {
        // Today is winnable until midnight: nothing logged yet is not a gap.
      } else if (status == DayStatus.breach && _isSameDay(cursor, gracedDate)) {
        // The breach an unexpired grace window is holding open. A day the user
        // breached is not a day they skipped — that window is exactly what the
        // breach bought them.
      } else {
        break;
      }

      cursor = _dayBefore(cursor);
    }

    return StreakDerivation(
      streak: streak,
      lastCompliantDate: lastCompliantDate,
    );
  }

  /// [value] with the time of day removed.
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// The calendar day before [day].
  ///
  /// Built by subtracting from the day-of-month, never with a
  /// `Duration(days: 1)`: a duration is a fixed 24 hours and lands on the wrong
  /// day across a daylight-saving change, which over a 365-step walk would
  /// skip or double-count a day. `DateTime` normalises a non-positive day into
  /// the previous month. Same technique as `AdaptationPhaseService._dayBefore`,
  /// deliberately — one day-arithmetic convention per feature.
  static DateTime _dayBefore(DateTime day) =>
      DateTime(day.year, day.month, day.day - 1);

  static bool _isSameDay(DateTime a, DateTime? b) =>
      b != null && a.year == b.year && a.month == b.month && a.day == b.day;
}
