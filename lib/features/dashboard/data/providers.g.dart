// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The dashboard feature's repository wiring.
///
/// `DailyLog` is a dashboard model, not a diary one: the diary owns individual
/// meals, the dashboard owns the per-day aggregate they roll up into.
///
/// Returns the domain interface so consumers depend on the abstraction.

@ProviderFor(dailyLogRepository)
const dailyLogRepositoryProvider = DailyLogRepositoryProvider._();

/// The dashboard feature's repository wiring.
///
/// `DailyLog` is a dashboard model, not a diary one: the diary owns individual
/// meals, the dashboard owns the per-day aggregate they roll up into.
///
/// Returns the domain interface so consumers depend on the abstraction.

final class DailyLogRepositoryProvider
    extends
        $FunctionalProvider<
          DailyLogRepository,
          DailyLogRepository,
          DailyLogRepository
        >
    with $Provider<DailyLogRepository> {
  /// The dashboard feature's repository wiring.
  ///
  /// `DailyLog` is a dashboard model, not a diary one: the diary owns individual
  /// meals, the dashboard owns the per-day aggregate they roll up into.
  ///
  /// Returns the domain interface so consumers depend on the abstraction.
  const DailyLogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyLogRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyLogRepositoryHash();

  @$internal
  @override
  $ProviderElement<DailyLogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DailyLogRepository create(Ref ref) {
    return dailyLogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailyLogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailyLogRepository>(value),
    );
  }
}

String _$dailyLogRepositoryHash() =>
    r'805591d6a98492f39624a724ad7e310138cde784';
