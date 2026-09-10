/// Stub for the M1 `DailyLog` fixture.
///
/// `DailyLog` is domain-layer scope (M1 — see `design/architecture.md`),
/// out of bounds for the M0 Foundation epic (#4), which explicitly excludes
/// "any domain models or business logic." This file holds the intended
/// future API contract as documentation only, so it compiles cleanly now
/// and the M1 issue that introduces `DailyLog` can fill in the real body
/// without anyone needing to rediscover the shape from scratch.
///
/// TODO(M1): once `DailyLog` lands, replace this file with something like:
/// ```dart
/// extension DailyLogFixture on DailyLog {
///   static DailyLog fixture({
///     Id? id,
///     DateTime? date,
///     double totalFatG = 120,
///     double totalNetCarbsG = 18,
///     double totalProteinG = 90,
///     double waterMl = 2000,
///     double sodiumMg = 3500,
///     double potassiumMg = 3200,
///     double magnesiumMg = 350,
///     double ketoRatioAvg = 2.0,
///   }) => DailyLog(
///     id: id,
///     date: date ?? DateTime(2026, 9, 9),
///     totalFatG: totalFatG,
///     totalNetCarbsG: totalNetCarbsG,
///     totalProteinG: totalProteinG,
///     waterMl: waterMl,
///     sodiumMg: sodiumMg,
///     potassiumMg: potassiumMg,
///     magnesiumMg: magnesiumMg,
///     ketoRatioAvg: ketoRatioAvg,
///   );
/// }
/// ```
/// Field names/defaults follow the `DailyLog` schema sketch in
/// `design/architecture.md`'s "Schema Overview." Default date is fixed
/// (not `DateTime.now()`) so tests stay deterministic — keep that when
/// filling this in.
library;
