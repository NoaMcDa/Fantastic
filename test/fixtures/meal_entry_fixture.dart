import 'package:fantastic/features/diary/domain/models/meal_entry.dart';

/// Test data for [MealEntry].
///
/// Every default is keto-valid and deterministic — the timestamp is fixed, not
/// `DateTime.now()`, so a fixture-backed assertion can never flake.
abstract final class MealEntryFixture {
  /// The fixed timestamp every fixture uses unless overridden.
  static final DateTime defaultTimestamp = DateTime(2026, 9, 9, 12);

  /// A keto-valid meal: 20g fat / 5g net carbs / 15g protein gives a ratio of
  /// 1.0 against `CLAUDE.md`'s formula.
  static MealEntry fixture({
    int? id,
    DateTime? timestamp,
    double fatG = 20,
    double netCarbsG = 5,
    double proteinG = 15,
    String mealName = 'Test Meal',
    List<String> ingredients = const [],
    String? imageRef,
  }) => MealEntry(
    id: id,
    timestamp: timestamp ?? defaultTimestamp,
    fatG: fatG,
    netCarbsG: netCarbsG,
    proteinG: proteinG,
    mealName: mealName,
    ingredients: ingredients,
    imageRef: imageRef,
  );

  /// A meal carrying every optional field, for round-trip tests that need to
  /// prove nothing is silently dropped.
  static MealEntry complete({int? id}) => fixture(
    id: id,
    ingredients: const ['olive oil', 'butter'],
    imageRef: 'labels/test.png',
  );
}
