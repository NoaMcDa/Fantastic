import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';

/// Test data for [StreakState].
///
/// Deterministic throughout — the grace-period and compliance dates are fixed,
/// not derived from `DateTime.now()`.
abstract final class StreakStateFixture {
  /// The fixed last-compliant date every fixture uses unless overridden.
  static final DateTime defaultCompliantDate = DateTime(2026, 9, 9);

  /// The fixed grace-period expiry — 24 hours after [defaultCompliantDate],
  /// matching the window `CLAUDE.md` describes.
  static final DateTime defaultGracePeriodEnd = DateTime(2026, 9, 10, 12);

  /// A first-launch user: zero streak, induction phase, no grace period.
  static StreakState initial() => StreakState.initial();

  /// A user [days] into an unbroken streak, with the phase left at the caller's
  /// choosing — phase derivation belongs to `AdaptationPhaseService` (#57),
  /// not to a fixture.
  static StreakState withStreak(
    int days, {
    AdaptationPhase phase = AdaptationPhase.induction,
    DateTime? lastCompliantDate,
  }) => StreakState(
    currentStreak: days,
    highestStreak: days,
    phase: phase,
    lastCompliantDate: lastCompliantDate ?? defaultCompliantDate,
  );

  /// A user who breached and is inside the 24-hour grace window.
  static StreakState inGracePeriod({int days = 5, DateTime? gracePeriodEnd}) =>
      withStreak(days).copyWith(
        inGracePeriod: true,
        gracePeriodEnd: gracePeriodEnd ?? defaultGracePeriodEnd,
      );
}
