import 'package:fantastic/features/diary/application/symptom_logging_service.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'symptom_providers.g.dart';

/// The [SymptomLog] for [date], or null when the day has none.
///
/// Goes through [SymptomLoggingService] rather than straight to the
/// repository, per `CLAUDE.md` §State Management — *"No new provider calls
/// the database directly — always through a service"* — and Epic #9, which
/// scopes the service as *(log, fetch)*. `todaysMealsProvider` and
/// `todaysDailyLogProvider` (M2) read their repositories directly; this is
/// the layer rule applied as written rather than that precedent extended.
///
/// A storage failure arrives as `AsyncValue.error` carrying the
/// `PersistenceException` the repository threw. **Read `hasError` before
/// `isLoading`** in any widget that watches this: riverpod 3 reports a
/// provider that failed before ever producing a value as `AsyncLoading` with
/// an error attached, so a loading-first check — including a plain
/// `AsyncValue.when`, which is written loading-first — renders its loading
/// branch forever. See `design/m5_preflight.md` §1.2.
///
/// Refreshed by invalidation after a write, not by a stream:
/// `SymptomLogRepository` exposes no watcher, and the only writer is
/// `SymptomLogSheet`, which knows when it has saved.
///
/// **Pass a date-only value.** Normalising inside the service fixes the
/// *query* but not the *cache key*: the family is keyed on the argument as
/// given, so `symptomLogProvider(DateTime.now())` called from a `build`
/// method would allocate a fresh provider every rebuild and refetch forever.
@riverpod
Future<SymptomLog?> symptomLog(Ref ref, DateTime date) =>
    ref.watch(symptomLoggingServiceProvider).symptomsForDate(date);
