import 'package:fantastic/features/dashboard/data/mappers/daily_log_mapper.dart';
import 'package:fantastic/features/dashboard/data/schemas/isar_daily_log.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:isar_community/isar.dart';

/// Isar-backed [DailyLogRepository].
///
/// Keyed on the calendar date rather than the id: `IsarDailyLog` carries a
/// unique index on `dateIndex`, so every write goes through the by-index
/// accessors the generator produced for it. A plain `put` would violate that
/// index and throw instead of replacing.
class IsarDailyLogRepository implements DailyLogRepository {
  const IsarDailyLogRepository(this._isar);

  final Isar _isar;

  @override
  Future<DailyLog> save(DailyLog log) async {
    final schema = DailyLogMapper.toIsar(log);
    // Replaces whatever record already holds this date — the
    // one-record-per-day guarantee, without a read-modify-write cycle. Like
    // `put`, it writes the resulting id back into `schema` in place, so a log
    // saved with a null id comes back carrying the row it landed on.
    await _isar.writeTxn(() => _isar.isarDailyLogs.putByDateIndex(schema));
    return DailyLogMapper.toDomain(schema);
  }

  @override
  Future<DailyLog?> findByDate(DateTime date) async {
    final schema = await _isar.isarDailyLogs.getByDateIndex(
      DailyLogMapper.dateIndex(date),
    );
    return schema == null ? null : DailyLogMapper.toDomain(schema);
  }

  @override
  Future<List<DailyLog>> findAll() async {
    final results = await _isar.isarDailyLogs
        .where()
        .sortByDateIndexDesc()
        .findAll();
    return results.map(DailyLogMapper.toDomain).toList();
  }

  /// Idempotent — the generated accessor returns `false` for a date with no
  /// record rather than throwing.
  @override
  Future<void> deleteByDate(DateTime date) => _isar.writeTxn(
    () => _isar.isarDailyLogs.deleteByDateIndex(DailyLogMapper.dateIndex(date)),
  );
}
