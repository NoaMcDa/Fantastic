// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'electrolyte_advisor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The advisor as a `const` singleton — it holds no state.

@ProviderFor(electrolyteAdvisor)
const electrolyteAdvisorProvider = ElectrolyteAdvisorProvider._();

/// The advisor as a `const` singleton — it holds no state.

final class ElectrolyteAdvisorProvider
    extends
        $FunctionalProvider<
          ElectrolyteAdvisor,
          ElectrolyteAdvisor,
          ElectrolyteAdvisor
        >
    with $Provider<ElectrolyteAdvisor> {
  /// The advisor as a `const` singleton — it holds no state.
  const ElectrolyteAdvisorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'electrolyteAdvisorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$electrolyteAdvisorHash();

  @$internal
  @override
  $ProviderElement<ElectrolyteAdvisor> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ElectrolyteAdvisor create(Ref ref) {
    return electrolyteAdvisor(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ElectrolyteAdvisor value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ElectrolyteAdvisor>(value),
    );
  }
}

String _$electrolyteAdvisorHash() =>
    r'38718e9c90963a09004b7994f988e1af0a3abe9e';
