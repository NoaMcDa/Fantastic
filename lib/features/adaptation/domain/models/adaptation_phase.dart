/// The three adaptation phases, in the order a user progresses through them.
///
/// Declaration order is the progression order, and the UI reads it that way.
/// It is *not* what gets persisted: `StreakStateMapper` writes the enum by
/// `name`, so reordering these values is safe for stored records — renaming
/// one is what would orphan them.
///
/// The day thresholds below are documented here but computed by
/// `AdaptationPhaseService` (#57) from the streak count — the enum carries no
/// thresholds of its own.
enum AdaptationPhase {
  /// Days 1–7 — Induction & Keto-Flu Management.
  induction,

  /// Days 8–27 — Fat-Adapted Transition.
  fatAdapted,

  /// Days 28+ — Deep Ketosis & Long-Term Maintenance.
  deepKetosis,
}
