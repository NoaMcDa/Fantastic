import 'package:fantastic/features/diary/domain/models/meal_entry.dart';

/// Converts between [MealEntry] and its sembast record shape.
///
/// Called only by `SembastMealRepository` — never from `domain/` or
/// `presentation/`, which must not see a persistence shape at all.
///
/// A record is a plain `Map<String, Object?>` whose values must survive the
/// store's JSON encoding, so `DateTime` is written as epoch milliseconds and
/// read back in local time. The record carries no id: sembast holds the key
/// outside the value, and [fromRecord] takes it as a separate argument.
abstract final class MealEntryMapper {
  static Map<String, Object?> toRecord(MealEntry entry) => {
    'mealName': entry.mealName,
    'fatG': entry.fatG,
    'netCarbsG': entry.netCarbsG,
    'proteinG': entry.proteinG,
    'timestamp': entry.timestamp.millisecondsSinceEpoch,
    'ingredients': entry.ingredients,
    'imageRef': entry.imageRef,
    // Denormalised so `findByDate` filters on an equality rather than a range
    // over `timestamp`, and does it with the same encoding [dateIndex] gives
    // the query.
    'dateIndex': dateIndex(entry.timestamp),
  };

  static MealEntry fromRecord(int key, Map<String, Object?> record) =>
      MealEntry(
        id: key,
        mealName: record['mealName']! as String,
        // `as num` then `.toDouble()`, never `as double`: a whole number
        // written as 40.0 comes back from IndexedDB's JSON as an int.
        fatG: (record['fatG']! as num).toDouble(),
        netCarbsG: (record['netCarbsG']! as num).toDouble(),
        proteinG: (record['proteinG']! as num).toDouble(),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          record['timestamp']! as int,
        ),
        // Copied, not cast: sembast hands back an immutable list that throws
        // on mutation, and `MealEntry` promises a plain list.
        ingredients: List<String>.from(record['ingredients']! as List),
        imageRef: record['imageRef'] as String?,
      );

  /// yyyyMMdd key for [date].
  ///
  /// Public because `SembastMealRepository` calls it to build its `findByDate`
  /// filter — the repository needs the same encoding the record was written
  /// with.
  static int dateIndex(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;
}
