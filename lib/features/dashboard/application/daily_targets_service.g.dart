// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_targets_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The per-day target calculator, wired to its repository interface.

@ProviderFor(dailyTargetsService)
const dailyTargetsServiceProvider = DailyTargetsServiceProvider._();

/// The per-day target calculator, wired to its repository interface.

final class DailyTargetsServiceProvider
    extends
        $FunctionalProvider<
          DailyTargetsService,
          DailyTargetsService,
          DailyTargetsService
        >
    with $Provider<DailyTargetsService> {
  /// The per-day target calculator, wired to its repository interface.
  const DailyTargetsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyTargetsServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyTargetsServiceHash();

  @$internal
  @override
  $ProviderElement<DailyTargetsService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DailyTargetsService create(Ref ref) {
    return dailyTargetsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailyTargetsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailyTargetsService>(value),
    );
  }
}

String _$dailyTargetsServiceHash() =>
    r'4963df5be27e9c11489eb47d497e8b9d4e4da44b';

/// The targets for [date], with the training-day bump already applied.
///
/// What `MacroSummaryCard` reads in place of `macroTargetsProvider`.
///
/// **Composed by pattern-matching two `AsyncValue`s, never by awaiting
/// `.future`.** riverpod 3 reports a provider that fails *before ever
/// producing a value* as `AsyncLoading` **with an error attached**, and its
/// `.future` never completes — the trap that cost M3 three issues and M4 its
/// router. Errors are checked before loading here for the same reason.
///
/// A missing profile yields [MacroTargets.defaults], the same fallback
/// `macroTargetsProvider` makes; a *failed read* yields an error, because a
/// profile that cannot be read is not a profile that says 150 g of fat.

@ProviderFor(dailyTargets)
const dailyTargetsProvider = DailyTargetsFamily._();

/// The targets for [date], with the training-day bump already applied.
///
/// What `MacroSummaryCard` reads in place of `macroTargetsProvider`.
///
/// **Composed by pattern-matching two `AsyncValue`s, never by awaiting
/// `.future`.** riverpod 3 reports a provider that fails *before ever
/// producing a value* as `AsyncLoading` **with an error attached**, and its
/// `.future` never completes — the trap that cost M3 three issues and M4 its
/// router. Errors are checked before loading here for the same reason.
///
/// A missing profile yields [MacroTargets.defaults], the same fallback
/// `macroTargetsProvider` makes; a *failed read* yields an error, because a
/// profile that cannot be read is not a profile that says 150 g of fat.

final class DailyTargetsProvider
    extends
        $FunctionalProvider<
          AsyncValue<MacroTargets>,
          AsyncValue<MacroTargets>,
          AsyncValue<MacroTargets>
        >
    with $Provider<AsyncValue<MacroTargets>> {
  /// The targets for [date], with the training-day bump already applied.
  ///
  /// What `MacroSummaryCard` reads in place of `macroTargetsProvider`.
  ///
  /// **Composed by pattern-matching two `AsyncValue`s, never by awaiting
  /// `.future`.** riverpod 3 reports a provider that fails *before ever
  /// producing a value* as `AsyncLoading` **with an error attached**, and its
  /// `.future` never completes — the trap that cost M3 three issues and M4 its
  /// router. Errors are checked before loading here for the same reason.
  ///
  /// A missing profile yields [MacroTargets.defaults], the same fallback
  /// `macroTargetsProvider` makes; a *failed read* yields an error, because a
  /// profile that cannot be read is not a profile that says 150 g of fat.
  const DailyTargetsProvider._({
    required DailyTargetsFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'dailyTargetsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dailyTargetsHash();

  @override
  String toString() {
    return r'dailyTargetsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<AsyncValue<MacroTargets>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<MacroTargets> create(Ref ref) {
    final argument = this.argument as DateTime;
    return dailyTargets(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<MacroTargets> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<MacroTargets>>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DailyTargetsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dailyTargetsHash() => r'e8d00c8bf68da4d5b04725a5939f05ae0286c486';

/// The targets for [date], with the training-day bump already applied.
///
/// What `MacroSummaryCard` reads in place of `macroTargetsProvider`.
///
/// **Composed by pattern-matching two `AsyncValue`s, never by awaiting
/// `.future`.** riverpod 3 reports a provider that fails *before ever
/// producing a value* as `AsyncLoading` **with an error attached**, and its
/// `.future` never completes — the trap that cost M3 three issues and M4 its
/// router. Errors are checked before loading here for the same reason.
///
/// A missing profile yields [MacroTargets.defaults], the same fallback
/// `macroTargetsProvider` makes; a *failed read* yields an error, because a
/// profile that cannot be read is not a profile that says 150 g of fat.

final class DailyTargetsFamily extends $Family
    with $FunctionalFamilyOverride<AsyncValue<MacroTargets>, DateTime> {
  const DailyTargetsFamily._()
    : super(
        retry: null,
        name: r'dailyTargetsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The targets for [date], with the training-day bump already applied.
  ///
  /// What `MacroSummaryCard` reads in place of `macroTargetsProvider`.
  ///
  /// **Composed by pattern-matching two `AsyncValue`s, never by awaiting
  /// `.future`.** riverpod 3 reports a provider that fails *before ever
  /// producing a value* as `AsyncLoading` **with an error attached**, and its
  /// `.future` never completes — the trap that cost M3 three issues and M4 its
  /// router. Errors are checked before loading here for the same reason.
  ///
  /// A missing profile yields [MacroTargets.defaults], the same fallback
  /// `macroTargetsProvider` makes; a *failed read* yields an error, because a
  /// profile that cannot be read is not a profile that says 150 g of fat.

  DailyTargetsProvider call(DateTime date) =>
      DailyTargetsProvider._(argument: date, from: this);

  @override
  String toString() => r'dailyTargetsProvider';
}
