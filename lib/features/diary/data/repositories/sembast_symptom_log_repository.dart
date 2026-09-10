import 'package:fantastic/core/error/persistence_guard.dart';
import 'package:fantastic/features/diary/data/mappers/symptom_log_mapper.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/domain/repositories/symptom_log_repository.dart';
import 'package:sembast/sembast.dart';

/// The store symptom logs live in, keyed on `SymptomLogMapper.dateIndex`.
///
/// Public for the same reason as `mealsStore`.
final symptomLogsStore = intMapStoreFactory.store('symptom_logs');

/// sembast-backed [SymptomLogRepository].
///
/// Keyed on the calendar date exactly like `SembastDailyLogRepository`: the
/// record key *is* `SymptomLogMapper.dateIndex(log.date)`, so `save` upserts
/// and a second record for a date is structurally impossible.
///
/// Every method is wrapped in [guardPersistence] so a storage failure surfaces
/// as a `PersistenceException` rather than a `DatabaseException`.
class SembastSymptomLogRepository implements SymptomLogRepository {
  const SembastSymptomLogRepository(this._db);

  final Database _db;

  @override
  Future<SymptomLog> save(SymptomLog log) =>
      guardPersistence('SembastSymptomLogRepository.save', () async {
        final key = SymptomLogMapper.dateIndex(log.date);
        final record = SymptomLogMapper.toRecord(log);
        await symptomLogsStore.record(key).put(_db, record);
        return SymptomLogMapper.fromRecord(key, record);
      });

  @override
  Future<SymptomLog?> findByDate(DateTime date) =>
      guardPersistence('SembastSymptomLogRepository.findByDate', () async {
        final key = SymptomLogMapper.dateIndex(date);
        final record = await symptomLogsStore.record(key).get(_db);
        return record == null ? null : SymptomLogMapper.fromRecord(key, record);
      });

  @override
  Future<List<SymptomLog>> findAll() =>
      guardPersistence('SembastSymptomLogRepository.findAll', () async {
        final snapshots = await symptomLogsStore.find(
          _db,
          // Sorted on the stored `date`, which orders identically to the
          // yyyyMMdd key. `false` is descending — newest first.
          finder: Finder(sortOrders: [SortOrder('date', false)]),
        );
        return snapshots
            .map((s) => SymptomLogMapper.fromRecord(s.key, s.value))
            .toList();
      });

  /// Idempotent — sembast returns null for a date with no record rather than
  /// throwing.
  @override
  Future<void> deleteByDate(DateTime date) =>
      guardPersistence('SembastSymptomLogRepository.deleteByDate', () async {
        await symptomLogsStore
            .record(SymptomLogMapper.dateIndex(date))
            .delete(_db);
      });
}
