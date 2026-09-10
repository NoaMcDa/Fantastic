import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'daily_log_providers.g.dart';

/// The [DailyLog] for [date], or null when nothing has been logged that day.
///
/// Null means "no log yet", not an error — callers render an empty state.
/// A storage failure arrives as `AsyncValue.error` carrying the
/// `PersistenceException` the repository threw (#177).
///
/// The date is normalised to midnight before the query, so a caller that
/// passes a wall-clock time still reads the right day.
///
/// **Pass a date-only value.** Normalising inside the provider fixes the
/// *query* but not the *cache key*: the family is keyed on the argument as
/// given, so `todaysDailyLogProvider(DateTime.now())` called from a `build`
/// method would allocate a fresh provider on every rebuild and refetch
/// forever. Screens hold the selected date in state instead of recomputing it.
///
/// Refreshed by invalidation after a write rather than by a stream —
/// `DailyLogRepository` exposes no watcher, and the dashboard's only writer is
/// `MealLoggingService`, which the UI already knows when it has called.
@riverpod
Future<DailyLog?> todaysDailyLog(Ref ref, DateTime date) {
  final repository = ref.watch(dailyLogRepositoryProvider);
  return repository.findByDate(DateTime(date.year, date.month, date.day));
}
