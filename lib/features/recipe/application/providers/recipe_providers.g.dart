// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The shipped [SubstitutionEngine], as a provider so a widget test can
/// override it with a small table rather than asserting against the whole
/// seeded set.

@ProviderFor(substitutionEngine)
const substitutionEngineProvider = SubstitutionEngineProvider._();

/// The shipped [SubstitutionEngine], as a provider so a widget test can
/// override it with a small table rather than asserting against the whole
/// seeded set.

final class SubstitutionEngineProvider
    extends
        $FunctionalProvider<
          SubstitutionEngine,
          SubstitutionEngine,
          SubstitutionEngine
        >
    with $Provider<SubstitutionEngine> {
  /// The shipped [SubstitutionEngine], as a provider so a widget test can
  /// override it with a small table rather than asserting against the whole
  /// seeded set.
  const SubstitutionEngineProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'substitutionEngineProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$substitutionEngineHash();

  @$internal
  @override
  $ProviderElement<SubstitutionEngine> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubstitutionEngine create(Ref ref) {
    return substitutionEngine(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubstitutionEngine value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubstitutionEngine>(value),
    );
  }
}

String _$substitutionEngineHash() =>
    r'a458e197853398191970794d66b45c16f54b9112';
