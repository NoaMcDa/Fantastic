import 'package:fantastic/core/error/persistence_guard.dart';
import 'package:fantastic/features/diary/data/mappers/meal_entry_mapper.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/domain/repositories/meal_repository.dart';
import 'package:sembast/sembast.dart';

/// The store meals live in.
///
/// Created on first write — sembast has no schema to register, so this
/// declaration is the whole registration. Public so a test can assert against
/// the same store the repository writes to, and so
/// `test/core/database/store_names_test.dart` can prove no two features chose
/// the same name.
final mealsStore = intMapStoreFactory.store('meals');

/// sembast-backed [MealRepository].
///
/// The only class in the diary feature that touches sembast for meals —
/// everything above it depends on the interface, which is what keeps the
/// backing store out of `application/`, `domain/` and `presentation/`. Every
/// method is wrapped in [guardPersistence] so a storage failure reaches those
/// layers as a `PersistenceException` rather than a `DatabaseException`, which
/// would leak the backing store through the very abstraction this class
/// provides.
///
/// Keys are sembast's own auto-incrementing record keys, which is what
/// [MealEntry.id] carries.
class SembastMealRepository implements MealRepository {
  const SembastMealRepository(this._db);

  final Database _db;

  /// Upsert: a null id appends at a fresh key, a non-null id overwrites that
  /// key. The key is only known after the write for an insert, so the record
  /// is mapped back with whichever key it landed on.
  @override
  Future<MealEntry> save(MealEntry entry) =>
      guardPersistence('SembastMealRepository.save', () async {
        final record = MealEntryMapper.toRecord(entry);
        final id = entry.id;
        if (id == null) {
          return MealEntryMapper.fromRecord(
            await mealsStore.add(_db, record),
            record,
          );
        }
        await mealsStore.record(id).put(_db, record);
        return MealEntryMapper.fromRecord(id, record);
      });

  @override
  Future<MealEntry?> findById(int id) =>
      guardPersistence('SembastMealRepository.findById', () async {
        final record = await mealsStore.record(id).get(_db);
        return record == null ? null : MealEntryMapper.fromRecord(id, record);
      });

  /// An equality on the denormalised `dateIndex` rather than a range over
  /// `timestamp`: the codec writes the field with the same encoding this
  /// filter reads it with, so the two cannot drift apart.
  @override
  Future<List<MealEntry>> findByDate(DateTime date) =>
      guardPersistence('SembastMealRepository.findByDate', () async {
        final snapshots = await mealsStore.find(
          _db,
          finder: Finder(
            filter: Filter.equals('dateIndex', MealEntryMapper.dateIndex(date)),
          ),
        );
        return snapshots.map(_toDomain).toList();
      });

  @override
  Future<List<MealEntry>> findAll() =>
      guardPersistence('SembastMealRepository.findAll', () async {
        final snapshots = await mealsStore.find(
          _db,
          // `false` is descending — newest first, as the interface promises.
          finder: Finder(sortOrders: [SortOrder('timestamp', false)]),
        );
        return snapshots.map(_toDomain).toList();
      });

  /// Idempotent — sembast returns null for an unknown key rather than
  /// throwing, which is exactly the interface's "no-op if not found".
  @override
  Future<void> delete(int id) =>
      guardPersistence('SembastMealRepository.delete', () async {
        await mealsStore.record(id).delete(_db);
      });

  static MealEntry _toDomain(RecordSnapshot<int, Map<String, Object?>> s) =>
      MealEntryMapper.fromRecord(s.key, s.value);
}
