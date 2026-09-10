import 'package:fantastic/features/diary/data/schemas/isar_meal_entry.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:isar_community/isar.dart';

/// Converts between [MealEntry] and its Isar persistence shape.
///
/// Called only by `IsarMealRepository` (#39) — never from `domain/` or
/// `presentation/`, which must not see Isar types at all.
abstract final class MealEntryMapper {
  static IsarMealEntry toIsar(MealEntry entry) => IsarMealEntry()
    ..id = entry.id ?? Isar.autoIncrement
    ..mealName = entry.mealName
    ..fatG = entry.fatG
    ..netCarbsG = entry.netCarbsG
    ..proteinG = entry.proteinG
    ..timestamp = entry.timestamp
    ..ingredients = entry.ingredients
    ..imageRef = entry.imageRef
    ..dateIndex = dateIndex(entry.timestamp);

  static MealEntry toDomain(IsarMealEntry schema) => MealEntry(
    id: schema.id,
    mealName: schema.mealName,
    fatG: schema.fatG,
    netCarbsG: schema.netCarbsG,
    proteinG: schema.proteinG,
    timestamp: schema.timestamp,
    ingredients: schema.ingredients,
    imageRef: schema.imageRef,
  );

  /// yyyyMMdd key for [date].
  ///
  /// Public because `IsarMealRepository` (#39) calls it to build its
  /// `findByDate` query — the repository needs the same encoding the schema
  /// was written with.
  static int dateIndex(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;
}
