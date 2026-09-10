import 'package:fantastic/features/diary/data/mappers/meal_entry_mapper.dart';
import 'package:fantastic/features/diary/data/schemas/isar_meal_entry.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/domain/repositories/meal_repository.dart';
import 'package:isar_community/isar.dart';

/// Isar-backed [MealRepository].
///
/// The only class in the diary feature that touches Isar for meals —
/// everything above it depends on the interface, which is what keeps Isar out
/// of `application/`, `domain/` and `presentation/`.
class IsarMealRepository implements MealRepository {
  const IsarMealRepository(this._isar);

  final Isar _isar;

  @override
  Future<MealEntry> save(MealEntry entry) async {
    final schema = MealEntryMapper.toIsar(entry);
    // `put` upserts by id and writes the assigned id back into `schema` in
    // place, so mapping after the transaction is what carries a new id out to
    // the caller.
    await _isar.writeTxn(() => _isar.isarMealEntrys.put(schema));
    return MealEntryMapper.toDomain(schema);
  }

  @override
  Future<MealEntry?> findById(int id) async {
    final schema = await _isar.isarMealEntrys.get(id);
    return schema == null ? null : MealEntryMapper.toDomain(schema);
  }

  @override
  Future<List<MealEntry>> findByDate(DateTime date) async {
    // Served by the `dateIndex` index, not a collection scan.
    final results = await _isar.isarMealEntrys
        .where()
        .dateIndexEqualTo(MealEntryMapper.dateIndex(date))
        .findAll();
    return results.map(MealEntryMapper.toDomain).toList();
  }

  @override
  Future<List<MealEntry>> findAll() async {
    final results = await _isar.isarMealEntrys
        .where()
        .sortByTimestampDesc()
        .findAll();
    return results.map(MealEntryMapper.toDomain).toList();
  }

  /// Idempotent — Isar returns `false` for an unknown id rather than throwing,
  /// which is exactly the interface's "no-op if not found".
  @override
  Future<void> delete(int id) =>
      _isar.writeTxn(() => _isar.isarMealEntrys.delete(id));
}
