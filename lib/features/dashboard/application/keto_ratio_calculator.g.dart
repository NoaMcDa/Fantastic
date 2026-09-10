// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'keto_ratio_calculator.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The calculator as a `const` singleton — it holds no state, so every consumer
/// shares one instance.

@ProviderFor(ketoRatioCalculator)
const ketoRatioCalculatorProvider = KetoRatioCalculatorProvider._();

/// The calculator as a `const` singleton — it holds no state, so every consumer
/// shares one instance.

final class KetoRatioCalculatorProvider
    extends
        $FunctionalProvider<
          KetoRatioCalculator,
          KetoRatioCalculator,
          KetoRatioCalculator
        >
    with $Provider<KetoRatioCalculator> {
  /// The calculator as a `const` singleton — it holds no state, so every consumer
  /// shares one instance.
  const KetoRatioCalculatorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ketoRatioCalculatorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ketoRatioCalculatorHash();

  @$internal
  @override
  $ProviderElement<KetoRatioCalculator> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  KetoRatioCalculator create(Ref ref) {
    return ketoRatioCalculator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(KetoRatioCalculator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<KetoRatioCalculator>(value),
    );
  }
}

String _$ketoRatioCalculatorHash() =>
    r'383d5c13aba59d4aed86763633fcd68c6b0271d1';
