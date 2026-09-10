import 'package:fantastic/core/error/persistence_guard.dart';
import 'package:fantastic/features/dashboard/data/mappers/daily_log_mapper.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:sembast/sembast.dart';

/// The store daily logs live in, keyed on `DailyLogMapper.dateIndex`.
///
/// Public for the same reason as `mealsStore` — tests assert against it, and
/// the store-name collision test enumerates it.
final dailyLogsStore = intMapStoreFactory.store('daily_logs');

/// sembast-backed [DailyLogRepository].
///
/// Keyed on the calendar date rather than on a generated id: the record key
/// *is* `DailyLogMapper.dateIndex(log.date)`, so writing the same date twice
/// addresses the same record and the one-record-per-day guarantee needs no
/// unique index and no read-modify-write cycle.
///
/// Every method is wrapped in [guardPersistence] so a storage failure surfaces
/// as a `PersistenceException` rather than a `DatabaseException`.
class SembastDailyLogRepository implements DailyLogRepository {
  const SembastDailyLogRepository(this._db);

  final Database _db;

  @override
  Future<DailyLog> save(DailyLog log) =>
      guardPersistence('SembastDailyLogRepository.save', () async {
        final key = DailyLogMapper.dateIndex(log.date);
        final record = DailyLogMapper.toRecord(log);
        await dailyLogsStore.record(key).put(_db, record);
        return DailyLogMapper.fromRecord(key, record);
      });

  @override
  Future<DailyLog?> findByDate(DateTime date) =>
      guardPersistence('SembastDailyLogRepository.findByDate', () async {
        final key = DailyLogMapper.dateIndex(date);
        final record = await dailyLogsStore.record(key).get(_db);
        return record == null ? null : DailyLogMapper.fromRecord(key, record);
      });

  @override
  Future<List<DailyLog>> findAll() =>
      guardPersistence('SembastDailyLogRepository.findAll', () async {
        final snapshots = await dailyLogsStore.find(
          _db,
          // Sorted on the stored `date`, which orders identically to the
          // yyyyMMdd key. `false` is descending — newest first.
          finder: Finder(sortOrders: [SortOrder('date', false)]),
        );
        return snapshots
            .map((s) => DailyLogMapper.fromRecord(s.key, s.value))
            .toList();
      });

  /// Idempotent — sembast returns null for a date with no record rather than
  /// throwing.
  @override
  Future<void> deleteByDate(DateTime date) =>
      guardPersistence('SembastDailyLogRepository.deleteByDate', () async {
        await dailyLogsStore.record(DailyLogMapper.dateIndex(date)).delete(_db);
      });
}
