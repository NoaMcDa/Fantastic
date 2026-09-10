/// The three adaptation phases, in the order a user progresses through them.
///
/// Ordinal order is persisted: `IsarStreakState` (#37) stores this as an
/// `@enumerated` ordinal via a mirror enum, so inserting or reordering a value
/// silently reinterprets every stored record. **Append only.**
///
/// The day thresholds below are documented here but computed by
/// `AdaptationPhaseService` (#57) from the streak count — the enum carries no
/// thresholds of its own.
enum AdaptationPhase {
  /// Days 1–7 — Induction & Keto-Flu Management.
  induction,

  /// Days 8–28 — Fat-Adapted Transition.
  fatAdapted,

  /// Days 28+ — Deep Ketosis & Long-Term Maintenance.
  deepKetosis,
}
