import 'package:fantastic/features/diary/domain/models/symptom_log.dart';

/// Persistence contract for [SymptomLog].
///
/// One record per calendar date, mirroring [DailyLogRepository]. `findAll`
/// rather than a range query: MVP data is one small record per day and the
/// diary's date strip filters in memory.
///
/// Score-range validation belongs to the domain model's constructor (#28),
/// not to this interface.
///
/// Methods return plain futures and throw on failure — see
/// `design/base_design.md` §Error Handling Contract.
abstract interface class SymptomLogRepository {
  /// Upserts [log] keyed on its date. Returns the persisted copy.
  ///
  /// Never creates a second record for a date that already has one.
  Future<SymptomLog> save(SymptomLog log);

  /// Returns the log for [date], or null if the day has none.
  /// Compared in local time with the time component stripped.
  Future<SymptomLog?> findByDate(DateTime date);

  /// Returns every stored log, newest first.
  Future<List<SymptomLog>> findAll();

  /// Permanently deletes the log for [date]. No-op if not found.
  Future<void> deleteByDate(DateTime date);
}
