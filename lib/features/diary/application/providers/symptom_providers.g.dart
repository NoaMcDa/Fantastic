// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'symptom_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(symptomLog)
const symptomLogProvider = SymptomLogFamily._();

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

final class SymptomLogProvider
    extends
        $FunctionalProvider<
          AsyncValue<SymptomLog?>,
          SymptomLog?,
          FutureOr<SymptomLog?>
        >
    with $FutureModifier<SymptomLog?>, $FutureProvider<SymptomLog?> {
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
  const SymptomLogProvider._({
    required SymptomLogFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'symptomLogProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$symptomLogHash();

  @override
  String toString() {
    return r'symptomLogProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SymptomLog?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SymptomLog?> create(Ref ref) {
    final argument = this.argument as DateTime;
    return symptomLog(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SymptomLogProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$symptomLogHash() => r'f71b4fbc205563fec274a390bf3f81fc871b2314';

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

final class SymptomLogFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SymptomLog?>, DateTime> {
  const SymptomLogFamily._()
    : super(
        retry: null,
        name: r'symptomLogProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

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

  SymptomLogProvider call(DateTime date) =>
      SymptomLogProvider._(argument: date, from: this);

  @override
  String toString() => r'symptomLogProvider';
}
