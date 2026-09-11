import 'dart:math' as math;

import 'package:fantastic/features/adaptation/application/streak_calculator.dart';
import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/day_compliance.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'adaptation_phase_service.g.dart';

/// The adaptation state machine: the streak is derived from the logged day
/// history, a breach opens a 24-hour grace period, and an expired grace period
/// resets everything but the personal best.
///
/// Pure orchestration over [StreakRepository] and [DailyLogRepository] — no
/// Flutter, no store types. The derived state is persisted before it is
/// returned, so a caller never holds state the repository has not seen.
///
/// **The counter is derived, not accumulated** (#303). It used to advance by
/// one per compliant meal-write, which made a retroactive edit impossible to
/// honour: back-dating a `+1` cannot know whether the days either side of it
/// are contiguous, and back-dating `lastCompliantDate` rewrites history
/// backwards. Counting back over `DailyLog` instead means a retroactive edit
/// is correct by construction — the walk reads whatever the history now says.
class AdaptationPhaseService {
  const AdaptationPhaseService({
    required this.repository,
    required this.dailyLogRepository,
  });

  /// Public, like `MealLoggingService`'s, because a named parameter cannot
  /// start with an underscore and `prefer_initializing_formals` wants one.
  final StreakRepository repository;
  final DailyLogRepository dailyLogRepository;

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

  /// Re-derives the streak after [changedDate]'s totals moved, and persists it.
  ///
  /// [at] is the instant to reason from: it decides grace-window opening and
  /// expiry, which [changedDate] cannot once it has been stripped to midnight.
  /// `MealLoggingService` passes the meal's own timestamp when logging and the
  /// wall clock when deleting, for exactly that reason.
  ///
  /// The single entry point, replacing the `recordCompliantDay` /
  /// `handleBreach` / `evaluateToday` trio. The caller no longer tells the
  /// service what the verdict is — the service derives it — which is what
  /// stops two copies of the compliance rule from reappearing.
  ///
  /// **A breach on a past day opens no window.** A grace period is a 24-hour
  /// chance to recover from a breach as it happens; granting one retroactively
  /// would write an already-expired window that arms an immediate reset.
  /// Re-deriving over a past breach simply shortens the streak, which is the
  /// honest answer.
  Future<StreakState> recomputeFor(
    DateTime changedDate, {
    required DateTime at,
  }) async {
    final current = await _load();
    final logs = await dailyLogRepository.findAll();

    var window = _expireIfClosed(current, at);
    window = _openWindowIfTodayBreached(
      window,
      logs: logs,
      changedDate: changedDate,
      at: at,
    );

    final derivation = StreakCalculator.derive(
      logs: logs,
      now: at,
      gracedDate: _gracedDate(window, at),
    );

    final streak = derivation.streak;
    return repository.save(
      window.copyWith(
        currentStreak: streak,
        highestStreak: math.max(current.highestStreak, streak),
        phase: _phaseFor(streak),
        lastCompliantDate: derivation.lastCompliantDate,
        // A streak of zero has nothing left to protect, so any window still
        // open is closed with it.
        inGracePeriod: streak == 0 ? false : window.inGracePeriod,
        clearGracePeriodEnd: streak == 0 || !window.inGracePeriod,
        clearLastCompliantDate: derivation.lastCompliantDate == null,
      ),
    );
  }

  /// [state] with a grace window that closed before [at] cleared.
  ///
  /// Rebuilt on the record rather than reset wholesale: the derivation that
  /// follows decides what the streak is worth now, so this only has to stop
  /// the stale window from forgiving a day it no longer covers.
  static StreakState _expireIfClosed(StreakState state, DateTime at) =>
      hasExpired(state, at)
      ? state.copyWith(inGracePeriod: false, clearGracePeriodEnd: true)
      : state;

  /// [state] with a fresh window when today is the day that just breached.
  ///
  /// Only for today, and only when no window is already open — one lapse, one
  /// penalty. A second breach on the same day cannot open a second window
  /// because a day has one [DayCompliance]; a breach on a *later* day finds
  /// the window already spent and lets the walk end there.
  static StreakState _openWindowIfTodayBreached(
    StreakState state, {
    required List<DailyLog> logs,
    required DateTime changedDate,
    required DateTime at,
  }) {
    if (state.inGracePeriod) {
      return state;
    }
    final today = StreakCalculator.dateOnly(at);
    if (StreakCalculator.dateOnly(changedDate) != today) {
      return state;
    }
    if (DayCompliance.of(_logFor(logs, today)) != DayStatus.breach) {
      return state;
    }
    return state.copyWith(
      inGracePeriod: true,
      gracePeriodEnd: at.add(gracePeriod),
    );
  }

  /// The log for [day], or null when the day has no record.
  static DailyLog? _logFor(List<DailyLog> logs, DateTime day) {
    for (final log in logs) {
      if (StreakCalculator.dateOnly(log.date) == day) {
        return log;
      }
    }
    return null;
  }

  /// The one breached day an open, unexpired window forgives.
  ///
  /// Derived from the expiry already on the record — the window runs
  /// [gracePeriod] from the breach — so **no field is added** to
  /// [StreakState].
  static DateTime? _gracedDate(StreakState state, DateTime at) {
    final end = state.gracePeriodEnd;
    if (!state.inGracePeriod || end == null || hasExpired(state, at)) {
      return null;
    }
    return StreakCalculator.dateOnly(end.subtract(gracePeriod));
  }

  /// The stored state, or the first-launch seed.
  ///
  /// Null from the repository is the never-logged sentinel, not an error — see
  /// [StreakRepository.load].
  Future<StreakState> _load() async =>
      await repository.load() ?? StreakState.initial();

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
  /// expired: there is no instant to compare against, and guessing would reset
  /// a streak on a malformed record.
  ///
  /// **Public because two widgets ask the same question** (#308):
  /// `GracePeriodBanner` decides whether it is showing a countdown or a
  /// notice, and `StreakRingWidget` decides whether the streak it was handed
  /// is still the user's. Two copies of "is this window still open" is how
  /// the write path and the display would come to disagree — and this is the
  /// definition the write path already uses, not a second one written to
  /// match it.
  static bool hasExpired(StreakState state, DateTime at) {
    final end = state.gracePeriodEnd;
    return state.inGracePeriod && end != null && at.isAfter(end);
  }
}

/// The state machine, wired to both repositories behind their domain
/// interfaces.
@riverpod
AdaptationPhaseService adaptationPhaseService(Ref ref) =>
    AdaptationPhaseService(
      repository: ref.watch(streakRepositoryProvider),
      dailyLogRepository: ref.watch(dailyLogRepositoryProvider),
    );
