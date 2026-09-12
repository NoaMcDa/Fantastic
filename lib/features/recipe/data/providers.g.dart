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

/// The composition root for #396's model pass, and the only place a concrete
/// [SubstitutionSuggester] is named.
///
/// **The one cross-feature import in the recipe feature**, and it belongs
/// here rather than being avoided: `llmChatClientProvider` is the diary
/// feature's composition root for `LlmChatClient` (`OpenRouterClient` behind
/// `EstimationSettings.isEnabled`), and reusing it is exactly what M15's
/// promotion of the interface to `lib/core/llm/` was for — a second consumer
/// without a second gate, a second key, or a second settings screen. The same
/// pattern `add_meal_photo_sheet.dart` uses to reach `ScanOrchestrator`.
///
/// Returns the **domain interface**, not the adapter class, for the same
/// reason every provider here does: a future backend swap is a new
/// `LlmChatClient` implementation and a new branch at that one composition
/// root, never an edit above this line.

@ProviderFor(substitutionSuggester)
const substitutionSuggesterProvider = SubstitutionSuggesterProvider._();

/// The composition root for #396's model pass, and the only place a concrete
/// [SubstitutionSuggester] is named.
///
/// **The one cross-feature import in the recipe feature**, and it belongs
/// here rather than being avoided: `llmChatClientProvider` is the diary
/// feature's composition root for `LlmChatClient` (`OpenRouterClient` behind
/// `EstimationSettings.isEnabled`), and reusing it is exactly what M15's
/// promotion of the interface to `lib/core/llm/` was for — a second consumer
/// without a second gate, a second key, or a second settings screen. The same
/// pattern `add_meal_photo_sheet.dart` uses to reach `ScanOrchestrator`.
///
/// Returns the **domain interface**, not the adapter class, for the same
/// reason every provider here does: a future backend swap is a new
/// `LlmChatClient` implementation and a new branch at that one composition
/// root, never an edit above this line.

final class SubstitutionSuggesterProvider
    extends
        $FunctionalProvider<
          SubstitutionSuggester,
          SubstitutionSuggester,
          SubstitutionSuggester
        >
    with $Provider<SubstitutionSuggester> {
  /// The composition root for #396's model pass, and the only place a concrete
  /// [SubstitutionSuggester] is named.
  ///
  /// **The one cross-feature import in the recipe feature**, and it belongs
  /// here rather than being avoided: `llmChatClientProvider` is the diary
  /// feature's composition root for `LlmChatClient` (`OpenRouterClient` behind
  /// `EstimationSettings.isEnabled`), and reusing it is exactly what M15's
  /// promotion of the interface to `lib/core/llm/` was for — a second consumer
  /// without a second gate, a second key, or a second settings screen. The same
  /// pattern `add_meal_photo_sheet.dart` uses to reach `ScanOrchestrator`.
  ///
  /// Returns the **domain interface**, not the adapter class, for the same
  /// reason every provider here does: a future backend swap is a new
  /// `LlmChatClient` implementation and a new branch at that one composition
  /// root, never an edit above this line.
  const SubstitutionSuggesterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'substitutionSuggesterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$substitutionSuggesterHash();

  @$internal
  @override
  $ProviderElement<SubstitutionSuggester> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubstitutionSuggester create(Ref ref) {
    return substitutionSuggester(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubstitutionSuggester value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubstitutionSuggester>(value),
    );
  }
}

String _$substitutionSuggesterHash() =>
    r'969fdeed2a4d33ba2ee6b2e748e3b2f9bcda5649';
