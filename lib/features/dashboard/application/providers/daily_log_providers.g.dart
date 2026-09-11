// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_log_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(todaysDailyLog)
const todaysDailyLogProvider = TodaysDailyLogFamily._();

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

final class TodaysDailyLogProvider
    extends
        $FunctionalProvider<
          AsyncValue<DailyLog?>,
          DailyLog?,
          FutureOr<DailyLog?>
        >
    with $FutureModifier<DailyLog?>, $FutureProvider<DailyLog?> {
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
  const TodaysDailyLogProvider._({
    required TodaysDailyLogFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'todaysDailyLogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$todaysDailyLogHash();

  @override
  String toString() {
    return r'todaysDailyLogProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DailyLog?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DailyLog?> create(Ref ref) {
    final argument = this.argument as DateTime;
    return todaysDailyLog(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TodaysDailyLogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$todaysDailyLogHash() => r'18242f13109abc51f6c6a3f7300a078da16c9b6e';

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

final class TodaysDailyLogFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DailyLog?>, DateTime> {
  const TodaysDailyLogFamily._()
    : super(
        retry: null,
        name: r'todaysDailyLogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

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

  TodaysDailyLogProvider call(DateTime date) =>
      TodaysDailyLogProvider._(argument: date, from: this);

  @override
  String toString() => r'todaysDailyLogProvider';
}

/// Every [DailyLog] in [month]'s calendar month, keyed by day of month.
///
/// One read and one loading state for the whole month, rather than the
/// thirty-one family instances a per-day provider would allocate — the grid
/// #67 draws would otherwise flicker in cell by cell and hit the store
/// thirty-one times to draw one screen.
///
/// A day with no entry is simply absent from the map; callers render it as
/// unlogged. Filters [DailyLogRepository.findAll] rather than adding a range
/// query, because the collection is one record per day and a year of use is
/// three hundred and sixty-five rows.
///
/// **Pass a date-only value**, for the same cache-key reason
/// [todaysDailyLog] documents. Only the year and month are read.

@ProviderFor(monthlyDailyLogs)
const monthlyDailyLogsProvider = MonthlyDailyLogsFamily._();

/// Every [DailyLog] in [month]'s calendar month, keyed by day of month.
///
/// One read and one loading state for the whole month, rather than the
/// thirty-one family instances a per-day provider would allocate — the grid
/// #67 draws would otherwise flicker in cell by cell and hit the store
/// thirty-one times to draw one screen.
///
/// A day with no entry is simply absent from the map; callers render it as
/// unlogged. Filters [DailyLogRepository.findAll] rather than adding a range
/// query, because the collection is one record per day and a year of use is
/// three hundred and sixty-five rows.
///
/// **Pass a date-only value**, for the same cache-key reason
/// [todaysDailyLog] documents. Only the year and month are read.

final class MonthlyDailyLogsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<int, DailyLog>>,
          Map<int, DailyLog>,
          FutureOr<Map<int, DailyLog>>
        >
    with
        $FutureModifier<Map<int, DailyLog>>,
        $FutureProvider<Map<int, DailyLog>> {
  /// Every [DailyLog] in [month]'s calendar month, keyed by day of month.
  ///
  /// One read and one loading state for the whole month, rather than the
  /// thirty-one family instances a per-day provider would allocate — the grid
  /// #67 draws would otherwise flicker in cell by cell and hit the store
  /// thirty-one times to draw one screen.
  ///
  /// A day with no entry is simply absent from the map; callers render it as
  /// unlogged. Filters [DailyLogRepository.findAll] rather than adding a range
  /// query, because the collection is one record per day and a year of use is
  /// three hundred and sixty-five rows.
  ///
  /// **Pass a date-only value**, for the same cache-key reason
  /// [todaysDailyLog] documents. Only the year and month are read.
  const MonthlyDailyLogsProvider._({
    required MonthlyDailyLogsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'monthlyDailyLogsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$monthlyDailyLogsHash();

  @override
  String toString() {
    return r'monthlyDailyLogsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<int, DailyLog>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<int, DailyLog>> create(Ref ref) {
    final argument = this.argument as DateTime;
    return monthlyDailyLogs(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MonthlyDailyLogsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$monthlyDailyLogsHash() => r'815a7fb101f66dfcae39e746c8415426f8af87b2';

/// Every [DailyLog] in [month]'s calendar month, keyed by day of month.
///
/// One read and one loading state for the whole month, rather than the
/// thirty-one family instances a per-day provider would allocate — the grid
/// #67 draws would otherwise flicker in cell by cell and hit the store
/// thirty-one times to draw one screen.
///
/// A day with no entry is simply absent from the map; callers render it as
/// unlogged. Filters [DailyLogRepository.findAll] rather than adding a range
/// query, because the collection is one record per day and a year of use is
/// three hundred and sixty-five rows.
///
/// **Pass a date-only value**, for the same cache-key reason
/// [todaysDailyLog] documents. Only the year and month are read.

final class MonthlyDailyLogsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<int, DailyLog>>, DateTime> {
  const MonthlyDailyLogsFamily._()
    : super(
        retry: null,
        name: r'monthlyDailyLogsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Every [DailyLog] in [month]'s calendar month, keyed by day of month.
  ///
  /// One read and one loading state for the whole month, rather than the
  /// thirty-one family instances a per-day provider would allocate — the grid
  /// #67 draws would otherwise flicker in cell by cell and hit the store
  /// thirty-one times to draw one screen.
  ///
  /// A day with no entry is simply absent from the map; callers render it as
  /// unlogged. Filters [DailyLogRepository.findAll] rather than adding a range
  /// query, because the collection is one record per day and a year of use is
  /// three hundred and sixty-five rows.
  ///
  /// **Pass a date-only value**, for the same cache-key reason
  /// [todaysDailyLog] documents. Only the year and month are read.

  MonthlyDailyLogsProvider call(DateTime month) =>
      MonthlyDailyLogsProvider._(argument: month, from: this);

  @override
  String toString() => r'monthlyDailyLogsProvider';
}
