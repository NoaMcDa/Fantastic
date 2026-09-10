import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';

/// Persistence contract for [DailyLog], the dashboard's per-day aggregate.
///
/// One record per calendar date, so [save] upserts rather than appending.
/// There is no stream method: the dashboard refreshes by provider invalidation
/// after a meal is logged, which needs no watch.
///
/// Methods return plain futures and throw on failure — see
/// `design/base_design.md` §Error Handling Contract.
abstract interface class DailyLogRepository {
  /// Upserts [log] keyed on its date. Returns the persisted copy.
  ///
  /// Never creates a second record for a date that already has one.
  Future<DailyLog> save(DailyLog log);

  /// Returns the log for [date], or null if the day has none.
  /// Compared in local time with the time component stripped.
  Future<DailyLog?> findByDate(DateTime date);

  /// Returns every stored log, newest first.
  Future<List<DailyLog>> findAll();

  /// Permanently deletes the log for [date]. No-op if not found.
  Future<void> deleteByDate(DateTime date);
}
