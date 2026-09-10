import 'package:fantastic/features/diary/domain/models/meal_entry.dart';

/// Persistence contract for [MealEntry].
///
/// The application layer and its tests depend on this abstraction, never on
/// the store. Methods return plain futures and **throw** typed exceptions on
/// failure — see `design/base_design.md` §Error Handling Contract for why
/// `Result<T>` was dropped. A null or empty result means "absent", never
/// "failed".
abstract interface class MealRepository {
  /// Persists [entry] and returns the saved copy with a non-null id.
  ///
  /// Upsert: a null [MealEntry.id] inserts, a non-null id overwrites.
  Future<MealEntry> save(MealEntry entry);

  /// Returns the entry with [id], or null if not found.
  Future<MealEntry?> findById(int id);

  /// Returns every entry whose [MealEntry.timestamp] falls on [date],
  /// compared in local time with the time component stripped.
  Future<List<MealEntry>> findByDate(DateTime date);

  /// Returns every stored entry, newest first.
  Future<List<MealEntry>> findAll();

  /// Permanently deletes the entry with [id]. No-op if not found.
  Future<void> delete(int id);
}
