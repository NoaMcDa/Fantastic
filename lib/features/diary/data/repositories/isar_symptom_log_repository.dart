import 'package:fantastic/features/diary/data/mappers/symptom_log_mapper.dart';
import 'package:fantastic/features/diary/data/schemas/isar_symptom_log.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/domain/repositories/symptom_log_repository.dart';
import 'package:isar_community/isar.dart';

/// Isar-backed [SymptomLogRepository].
///
/// Keyed on the calendar date, mirroring `IsarDailyLogRepository`:
/// `IsarSymptomLog` carries a unique index on `dateIndex`, so every write goes
/// through the by-index accessors the generator produced for it. A plain `put`
/// would violate that index and throw instead of replacing.
class IsarSymptomLogRepository implements SymptomLogRepository {
  const IsarSymptomLogRepository(this._isar);

  final Isar _isar;

  @override
  Future<SymptomLog> save(SymptomLog log) async {
    final schema = SymptomLogMapper.toIsar(log);
    // Replaces whatever record already holds this date, and writes the
    // resulting id back into `schema` in place — so a log saved with a null id
    // comes back carrying the row it landed on.
    await _isar.writeTxn(() => _isar.isarSymptomLogs.putByDateIndex(schema));
    return SymptomLogMapper.toDomain(schema);
  }

  @override
  Future<SymptomLog?> findByDate(DateTime date) async {
    final schema = await _isar.isarSymptomLogs.getByDateIndex(
      SymptomLogMapper.dateIndex(date),
    );
    return schema == null ? null : SymptomLogMapper.toDomain(schema);
  }

  @override
  Future<List<SymptomLog>> findAll() async {
    final results = await _isar.isarSymptomLogs
        .where()
        .sortByDateIndexDesc()
        .findAll();
    return results.map(SymptomLogMapper.toDomain).toList();
  }

  /// Idempotent — the generated accessor returns `false` for a date with no
  /// record rather than throwing.
  @override
  Future<void> deleteByDate(DateTime date) => _isar.writeTxn(
    () => _isar.isarSymptomLogs.deleteByDateIndex(
      SymptomLogMapper.dateIndex(date),
    ),
  );
}
