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
  /// **A grace period that closed before [date] has already cost the streak.**
  /// The window is what the user was given to get back on plan; a compliant
  /// day logged after it closed starts a new streak at 1 rather than resuming
  /// the old one. Checking it here and not only in [handleBreach] is what
  /// makes that true: the reset is lazy — nothing evaluates the state machine
  /// while the user logs nothing — so the *next* evaluation is where an
  /// expired window has to be noticed, and it is at least as likely to be a
  /// compliant meal as a breach.
  ///
  /// Known limitation: a day banked early cannot be un-banked by a later
  /// breach on the same day. Reversing it would need the previous
  /// `lastCompliantDate` to restore, which the singleton record does not keep.
  /// Deferred with the end-of-day evaluation job #58's background describes.
  Future<StreakState> recordCompliantDay(DateTime date) async {
    final current = await _load();
    final day = _dateOnly(date);
    if (_isSameDay(current.lastCompliantDate, day)) {
      return current;
    }

    // Rebuilt rather than copied, for the same reason [handleBreach] does it:
    // every field but the personal best returns to its initial value, and a
    // field added to StreakState later resets correctly without anyone
    // remembering to clear it.
    final base = _hasExpired(current, date)
        ? StreakState(highestStreak: current.highestStreak)
        : current;

    final streak = base.currentStreak + 1;
    return _repository.save(
      base.copyWith(
        currentStreak: streak,
        highestStreak: math.max(base.highestStreak, streak),
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
    final current = await _load();

    if (_isSameDay(current.lastCompliantDate, _dateOnly(now))) {
      return current;
    }

    if (current.inGracePeriod) {
      if (!_hasExpired(current, now)) {
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
  /// [date] carries the time of day, which **both** branches compare against
  /// the grace-period expiry — a midnight-normalised value would judge the
  /// window by its start rather than by when the evaluation happened. That is
  /// why `MealLoggingService` passes the wall clock on the delete path, where
  /// the only date it holds has been stripped to midnight.
  Future<StreakState> evaluateToday(DateTime date, {required bool compliant}) =>
      compliant ? recordCompliantDay(date) : handleBreach(date);

  /// The stored state, or the first-launch seed.
  ///
  /// Null from the repository is the never-logged sentinel, not an error — see
  /// [StreakRepository.load].
  Future<StreakState> _load() async =>
      await _repository.load() ?? StreakState.initial();

  static AdaptationPhase _phaseFor(int streak) {
    if (streak >= deepKetosisFromDay) {
      return AdaptationPhase.deepKetosis;
    }
    if (streak >= fatAdaptedFromDay) {
      return AdaptationPhase.fatAdapted;
    }
    return AdaptationPhase.induction;
  }

  /// Whether [state]'s grace period was open and had already closed by [at].
  ///
  /// Strictly after, so an evaluation landing on the exact expiry instant is
  /// still inside the window — the user is given the boundary, not denied it.
  ///
  /// An `inGracePeriod` with no [StreakState.gracePeriodEnd] cannot be judged
  /// expired: there is no instant to compare against, and guessing would
  /// reset a streak on a malformed record. Both callers leave such a state
  /// alone, which is what they did before this was factored out.
  static bool _hasExpired(StreakState state, DateTime at) {
    final end = state.gracePeriodEnd;
    return state.inGracePeriod && end != null && at.isAfter(end);
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
