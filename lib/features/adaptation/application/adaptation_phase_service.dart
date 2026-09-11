import 'dart:math' as math;

import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'adaptation_phase_service.g.dart';

/// The adaptation state machine: compliant days advance the streak, a breach
/// opens a 24-hour grace period, and an expired grace period resets everything
/// but the personal best.
///
/// Pure orchestration over [StreakRepository] — no Flutter, no store types.
/// Every mutation goes through [StreakState.copyWith] and is persisted before
/// it is returned, so a caller never holds state the repository has not seen.
class AdaptationPhaseService {
  const AdaptationPhaseService(this._repository);

  final StreakRepository _repository;

  /// How long a user has to get back on plan before the streak resets.
  static const Duration gracePeriod = Duration(hours: 24);

  /// First day of [AdaptationPhase.fatAdapted].
  static const int fatAdaptedFromDay = 8;

  /// First day of [AdaptationPhase.deepKetosis].
  static const int deepKetosisFromDay = 28;

  /// The phase [state]'s streak length puts the user in.
  ///
  /// Pure: the same streak always yields the same phase, and the value stored
  /// on [state] is ignored. `StreakState.phase` is a cache of this function's
  /// output, written whenever the streak changes — never an input to it.
  AdaptationPhase currentPhase(StreakState state) =>
      _phaseFor(state.currentStreak);

  /// Banks [date] as a compliant day: the streak advances by one, the phase
  /// follows it, and any open grace period closes.
  ///
  /// **Idempotent per calendar day.** The trigger is per *meal* (#58), so
  /// without this guard three meals would leave a three-day streak. A day
  /// already banked returns the stored state untouched, with no write.
  ///
  /// **Advances by one from the [reconcile]d state, not from the stored one.**
  /// A streak that a skipped day has already broken restarts at 1 here rather
  /// than resuming where it left off.
  ///
  /// Known limitation: a day banked early cannot be un-banked by a later
  /// breach on the same day. Reversing it would need the previous
  /// `lastCompliantDate` to restore, which the singleton record does not keep.
  /// Deferred with the end-of-day evaluation job #58's background describes.
  Future<StreakState> recordCompliantDay(DateTime date) async {
    final current = reconcile(await _load(), date);
    final day = _dateOnly(date);
    if (_isSameDay(current.lastCompliantDate, day)) {
      return current;
    }

    final streak = current.currentStreak + 1;
    return _repository.save(
      current.copyWith(
        currentStreak: streak,
        highestStreak: math.max(current.highestStreak, streak),
        phase: _phaseFor(streak),
        lastCompliantDate: day,
        inGracePeriod: false,
        // The flag, not `gracePeriodEnd: null` — `copyWith` resolves a null
        // argument to the existing value, so passing null would leave a stale
        // expiry behind on a streak that is no longer at risk.
        clearGracePeriodEnd: true,
      ),
    );
  }

  /// Applies a breach observed at [now].
  ///
  /// Three outcomes, in the order they are checked:
  ///
  /// 1. [now]'s day is already banked compliant — no-op. A carb-heavy snack
  ///    after a compliant dinner must not open a grace period on a day that
  ///    is already won.
  /// 2. A grace period is open and has expired — the streak resets to zero
  ///    and the phase returns to induction. [StreakState.highestStreak] is the
  ///    only thing carried across: it is a personal best, not current state.
  /// 3. Otherwise the first breach opens a [gracePeriod] window from [now],
  ///    leaving the streak intact. A second breach inside an open window is a
  ///    no-op — one lapse, one penalty.
  Future<StreakState> handleBreach(DateTime now) async {
    // Reconciled first, so a breach arriving after a skipped day is applied to
    // the streak the skip already broke rather than to a stale one. The reset
    // reaches storage either way: a reconciled state is never in a grace
    // period, so the third branch below always writes.
    final current = reconcile(await _load(), now);

    if (_isSameDay(current.lastCompliantDate, _dateOnly(now))) {
      return current;
    }

    if (current.inGracePeriod) {
      final end = current.gracePeriodEnd;
      if (end == null || !now.isAfter(end)) {
        return current;
      }
      // Rebuilt rather than copied: every field but the personal best returns
      // to its initial value, and a field added to StreakState later resets
      // correctly here without anyone remembering to clear it.
      return _repository.save(
        StreakState(highestStreak: current.highestStreak),
      );
    }

    return _repository.save(
      current.copyWith(
        inGracePeriod: true,
        gracePeriodEnd: now.add(gracePeriod),
      ),
    );
  }

  /// Routes [date] to [recordCompliantDay] or [handleBreach].
  ///
  /// [date] carries the time of day, which [handleBreach] compares against the
  /// grace-period expiry — a midnight-normalised value would judge the window
  /// by its start rather than by when the breach happened.
  Future<StreakState> evaluateToday(DateTime date, {required bool compliant}) =>
      compliant ? recordCompliantDay(date) : handleBreach(date);

  /// [state] as the passage of time alone has left it, at [now].
  ///
  /// Pure, and the only thing in the app that applies a rule nothing else
  /// can: **a skipped day breaks the streak.** Every other transition is
  /// driven by a meal being logged, so without this a user could log a
  /// compliant day in January, vanish until March, log one more, and be told
  /// they were on a two-day streak. `currentStreak` was a lifetime count of
  /// compliant days, not a streak.
  ///
  /// A day counts as skipped once a whole calendar day has passed with
  /// nothing banked — so [lastCompliantDate] of today or yesterday is intact,
  /// and anything older is broken. Yesterday has to stay intact: today is
  /// still winnable until midnight.
  ///
  /// **An open grace window survives the gap it creates.** A day the user
  /// *breached* is not a day they skipped — the 24-hour window is exactly
  /// what a breach buys them, and `CLAUDE.md` promises the streak resumes if
  /// a compliant day lands inside it. So a state inside an unexpired window
  /// is intact however old its last compliant day is.
  ///
  /// Resetting rebuilds from scratch rather than copying, so a field added to
  /// [StreakState] later resets correctly without anyone remembering to clear
  /// it. [StreakState.highestStreak] is carried across: it is a personal
  /// best, not current state.
  ///
  /// **Reconciliation happens on write, not on read.** Nothing persists this
  /// until the user's next logged meal, so a stored record can sit stale in
  /// between and the ring will show the old number until then — the "streak
  /// resets lazily" gap `design/m3_handoff.md` records. Applying it on read
  /// would mean a provider calling `DateTime.now()`, which makes every widget
  /// test that stubs a streak time-dependent.
  StreakState reconcile(StreakState state, DateTime now) {
    final last = state.lastCompliantDate;
    if (last == null) {
      // Nothing has ever been banked, so there is no streak to break.
      return state;
    }

    final today = _dateOnly(now);
    if (_isSameDay(last, today) || _isSameDay(last, _dayBefore(today))) {
      return state;
    }

    if (state.inGracePeriod &&
        state.gracePeriodEnd != null &&
        !now.isAfter(state.gracePeriodEnd!)) {
      return state;
    }

    return StreakState(highestStreak: state.highestStreak);
  }

  /// The stored state, or the first-launch seed.
  ///
  /// Null from the repository is the never-logged sentinel, not an error — see
  /// [StreakRepository.load].
  Future<StreakState> _load() async =>
      await _repository.load() ?? StreakState.initial();

  /// The calendar day before [day].
  ///
  /// Built by subtracting from the day-of-month, never with a
  /// `Duration(days: 1)`: a duration is a fixed 24 hours and lands on the
  /// wrong day across a daylight-saving change. `DateTime` normalises a
  /// non-positive day into the previous month.
  static DateTime _dayBefore(DateTime day) =>
      DateTime(day.year, day.month, day.day - 1);

  static AdaptationPhase _phaseFor(int streak) {
    if (streak >= deepKetosisFromDay) {
      return AdaptationPhase.deepKetosis;
    }
    if (streak >= fatAdaptedFromDay) {
      return AdaptationPhase.fatAdapted;
    }
    return AdaptationPhase.induction;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool _isSameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;
}

/// The state machine, wired to the repository behind its domain interface.
@riverpod
AdaptationPhaseService adaptationPhaseService(Ref ref) =>
    AdaptationPhaseService(ref.watch(streakRepositoryProvider));
