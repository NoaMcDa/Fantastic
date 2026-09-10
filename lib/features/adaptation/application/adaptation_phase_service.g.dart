// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adaptation_phase_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The state machine, wired to the repository behind its domain interface.

@ProviderFor(adaptationPhaseService)
const adaptationPhaseServiceProvider = AdaptationPhaseServiceProvider._();

/// The state machine, wired to the repository behind its domain interface.

final class AdaptationPhaseServiceProvider
    extends
        $FunctionalProvider<
          AdaptationPhaseService,
          AdaptationPhaseService,
          AdaptationPhaseService
        >
    with $Provider<AdaptationPhaseService> {
  /// The state machine, wired to the repository behind its domain interface.
  const AdaptationPhaseServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adaptationPhaseServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adaptationPhaseServiceHash();

  @$internal
  @override
  $ProviderElement<AdaptationPhaseService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdaptationPhaseService create(Ref ref) {
    return adaptationPhaseService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdaptationPhaseService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdaptationPhaseService>(value),
    );
  }
}

String _$adaptationPhaseServiceHash() =>
    r'e795bbdc84265790c3048787b5b692abd4470ac5';
