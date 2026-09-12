// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The recipe feature's repository wiring.
///
/// Returns the **domain interface**, not the sembast class, so a consumer
/// cannot reach past the abstraction to a store-specific method — the layer
/// rule enforced by the type system rather than by review.
///
/// `ref.watch(databaseProvider)` yields a `Database` directly: the provider is
/// synchronous, and throws a descriptive `UnimplementedError` if the app root
/// never overrode it.

@ProviderFor(savedRecipeRepository)
const savedRecipeRepositoryProvider = SavedRecipeRepositoryProvider._();

/// The recipe feature's repository wiring.
///
/// Returns the **domain interface**, not the sembast class, so a consumer
/// cannot reach past the abstraction to a store-specific method — the layer
/// rule enforced by the type system rather than by review.
///
/// `ref.watch(databaseProvider)` yields a `Database` directly: the provider is
/// synchronous, and throws a descriptive `UnimplementedError` if the app root
/// never overrode it.

final class SavedRecipeRepositoryProvider
    extends
        $FunctionalProvider<
          SavedRecipeRepository,
          SavedRecipeRepository,
          SavedRecipeRepository
        >
    with $Provider<SavedRecipeRepository> {
  /// The recipe feature's repository wiring.
  ///
  /// Returns the **domain interface**, not the sembast class, so a consumer
  /// cannot reach past the abstraction to a store-specific method — the layer
  /// rule enforced by the type system rather than by review.
  ///
  /// `ref.watch(databaseProvider)` yields a `Database` directly: the provider is
  /// synchronous, and throws a descriptive `UnimplementedError` if the app root
  /// never overrode it.
  const SavedRecipeRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedRecipeRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedRecipeRepositoryHash();

  @$internal
  @override
  $ProviderElement<SavedRecipeRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SavedRecipeRepository create(Ref ref) {
    return savedRecipeRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SavedRecipeRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SavedRecipeRepository>(value),
    );
  }
}

String _$savedRecipeRepositoryHash() =>
    r'982b8a95aab580d08d47c358ad3cce50ef8347d2';
