/// Stub for the M1 `StreakState` / `AdaptationPhase` fixture.
///
/// `StreakState` and `AdaptationPhase` are domain-layer scope (M1 — see
/// `design/architecture.md`), out of bounds for the M0 Foundation epic
/// (#4), which explicitly excludes "any domain models or business logic."
/// This file holds the intended future API contract as documentation
/// only, so it compiles cleanly now and the M1 issue that introduces
/// `StreakState` can fill in the real body without anyone needing to
/// rediscover the shape from scratch.
///
/// TODO(M1): once `StreakState`/`AdaptationPhase` land, replace this file
/// with:
/// ```dart
/// extension StreakStateFixture on StreakState {
///   static StreakState initial() => const StreakState(
///     currentStreak: 0,
///     highestStreak: 0,
///     phase: AdaptationPhase.induction,
///     inGracePeriod: false,
///   );
///
///   static StreakState withStreak(int days) =>
///     initial().copyWith(currentStreak: days, highestStreak: days);
/// }
/// ```
library;
