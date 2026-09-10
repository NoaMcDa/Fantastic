/// Stub for the M1 `MealEntry` fixture.
///
/// `MealEntry` is domain-layer scope (M1 — see `design/architecture.md`),
/// out of bounds for the M0 Foundation epic (#4), which explicitly excludes
/// "any domain models or business logic." This file holds the intended
/// future API contract as documentation only, so it compiles cleanly now
/// and the M1 issue that introduces `MealEntry` can fill in the real body
/// without anyone needing to rediscover the shape from scratch.
///
/// TODO(M1): once `MealEntry` lands, replace this file with:
/// ```dart
/// extension MealEntryFixture on MealEntry {
///   static MealEntry fixture({
///     Id? id,
///     DateTime? timestamp,
///     double fatG = 20,
///     double netCarbsG = 5,
///     double proteinG = 15,
///     String mealName = 'Test Meal',
///     List<String> ingredients = const [],
///   }) => MealEntry(
///     id: id,
///     timestamp: timestamp ?? DateTime(2026, 9, 9, 12, 0),
///     fatG: fatG,
///     netCarbsG: netCarbsG,
///     proteinG: proteinG,
///     mealName: mealName,
///     ingredients: ingredients,
///   );
/// }
/// ```
/// Default timestamp is fixed (not `DateTime.now()`) so tests stay
/// deterministic — keep that when filling this in.
library;
