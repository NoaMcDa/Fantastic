// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'symptom_logging_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(symptomLoggingService)
const symptomLoggingServiceProvider = SymptomLoggingServiceProvider._();

final class SymptomLoggingServiceProvider
    extends
        $FunctionalProvider<
          SymptomLoggingService,
          SymptomLoggingService,
          SymptomLoggingService
        >
    with $Provider<SymptomLoggingService> {
  const SymptomLoggingServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'symptomLoggingServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$symptomLoggingServiceHash();

  @$internal
  @override
  $ProviderElement<SymptomLoggingService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SymptomLoggingService create(Ref ref) {
    return symptomLoggingService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SymptomLoggingService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SymptomLoggingService>(value),
    );
  }
}

String _$symptomLoggingServiceHash() =>
    r'339a18277205068181d353b67bfe08d06b6fa2e6';
