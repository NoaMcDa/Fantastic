/// Stub for the M1 `SymptomLog` fixture.
///
/// `SymptomLog` is domain-layer scope (M1 — see `design/architecture.md`),
/// out of bounds for the M0 Foundation epic (#4), which explicitly excludes
/// "any domain models or business logic." This file holds the intended
/// future API contract as documentation only, so it compiles cleanly now
/// and the M1 issue that introduces `SymptomLog` can fill in the real body
/// without anyone needing to rediscover the shape from scratch.
///
/// TODO(M1): once `SymptomLog` lands, replace this file with something
/// like:
/// ```dart
/// extension SymptomLogFixture on SymptomLog {
///   static SymptomLog fixture({
///     Id? id,
///     DateTime? date,
///     int energyScore = 3,
///     int clarityScore = 3,
///     int hungerScore = 3,
///     int physicalScore = 3,
///     int moodScore = 3,
///     String? notes,
///   }) => SymptomLog(
///     id: id,
///     date: date ?? DateTime(2026, 9, 9),
///     energyScore: energyScore,
///     clarityScore: clarityScore,
///     hungerScore: hungerScore,
///     physicalScore: physicalScore,
///     moodScore: moodScore,
///     notes: notes,
///   );
/// }
/// ```
/// All five scores are 1–5 scales per `design/ui_ux_design.md`. Default
/// date is fixed (not `DateTime.now()`) so tests stay deterministic —
/// keep that when filling this in.
library;
