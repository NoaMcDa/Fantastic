import 'package:isar_community/isar.dart';

part 'isar_meal_entry.g.dart';

/// Isar persistence shape for `MealEntry`.
///
/// Mirrors every domain field — the domain model stays free of Isar
/// annotations, and `MealEntryMapper` converts between the two. Field names
/// match the domain model exactly so a rename on either side fails to compile
/// rather than silently dropping data.
@collection
class IsarMealEntry {
  Id id = Isar.autoIncrement;

  late String mealName;
  late double fatG;
  late double netCarbsG;
  late double proteinG;
  late DateTime timestamp;

  /// Ingredient tokens, persisted so a saved meal round-trips intact.
  late List<String> ingredients;

  /// Optional reference to a captured label image.
  String? imageRef;

  /// yyyyMMdd derived from [timestamp], indexed so `findByDate` is a lookup
  /// rather than a full collection scan.
  @Index()
  late int dateIndex;
}
