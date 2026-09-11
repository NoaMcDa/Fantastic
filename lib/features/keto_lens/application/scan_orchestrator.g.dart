// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_orchestrator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(scanOrchestrator)
const scanOrchestratorProvider = ScanOrchestratorProvider._();

final class ScanOrchestratorProvider
    extends
        $FunctionalProvider<
          ScanOrchestrator,
          ScanOrchestrator,
          ScanOrchestrator
        >
    with $Provider<ScanOrchestrator> {
  const ScanOrchestratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanOrchestratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanOrchestratorHash();

  @$internal
  @override
  $ProviderElement<ScanOrchestrator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ScanOrchestrator create(Ref ref) {
    return scanOrchestrator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScanOrchestrator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScanOrchestrator>(value),
    );
  }
}

String _$scanOrchestratorHash() => r'2c7a61b372368e8bc3be81cccfa2e5df98a472c8';
