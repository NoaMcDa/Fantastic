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

/// Every saved recipe, newest first (#120).
///
/// Invalidated after every write: `RecipeConverterScreen._save` on a
/// successful save, `RecipeLibraryScreen._delete` on both a successful and a
/// failed delete — the failed-delete refetch is what self-heals a row a
/// `Dismissible` already removed from the tree.

@ProviderFor(savedRecipes)
const savedRecipesProvider = SavedRecipesProvider._();

/// Every saved recipe, newest first (#120).
///
/// Invalidated after every write: `RecipeConverterScreen._save` on a
/// successful save, `RecipeLibraryScreen._delete` on both a successful and a
/// failed delete — the failed-delete refetch is what self-heals a row a
/// `Dismissible` already removed from the tree.

final class SavedRecipesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SavedRecipe>>,
          List<SavedRecipe>,
          FutureOr<List<SavedRecipe>>
        >
    with
        $FutureModifier<List<SavedRecipe>>,
        $FutureProvider<List<SavedRecipe>> {
  /// Every saved recipe, newest first (#120).
  ///
  /// Invalidated after every write: `RecipeConverterScreen._save` on a
  /// successful save, `RecipeLibraryScreen._delete` on both a successful and a
  /// failed delete — the failed-delete refetch is what self-heals a row a
  /// `Dismissible` already removed from the tree.
  const SavedRecipesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedRecipesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedRecipesHash();

  @$internal
  @override
  $FutureProviderElement<List<SavedRecipe>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SavedRecipe>> create(Ref ref) {
    return savedRecipes(ref);
  }
}

String _$savedRecipesHash() => r'06ab79c0bafddb5c9af94304d1f8cecbe1664f1f';

/// One saved recipe, or null when [id] is unknown.
///
/// `SavedRecipeLoader` is the one consumer: `/recipe/saved/:id` reopens a
/// recipe by this id rather than through the `extra` a `go_router` push would
/// drop on a browser reload.

@ProviderFor(savedRecipe)
const savedRecipeProvider = SavedRecipeFamily._();

/// One saved recipe, or null when [id] is unknown.
///
/// `SavedRecipeLoader` is the one consumer: `/recipe/saved/:id` reopens a
/// recipe by this id rather than through the `extra` a `go_router` push would
/// drop on a browser reload.

final class SavedRecipeProvider
    extends
        $FunctionalProvider<
          AsyncValue<SavedRecipe?>,
          SavedRecipe?,
          FutureOr<SavedRecipe?>
        >
    with $FutureModifier<SavedRecipe?>, $FutureProvider<SavedRecipe?> {
  /// One saved recipe, or null when [id] is unknown.
  ///
  /// `SavedRecipeLoader` is the one consumer: `/recipe/saved/:id` reopens a
  /// recipe by this id rather than through the `extra` a `go_router` push would
  /// drop on a browser reload.
  const SavedRecipeProvider._({
    required SavedRecipeFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'savedRecipeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$savedRecipeHash();

  @override
  String toString() {
    return r'savedRecipeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SavedRecipe?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SavedRecipe?> create(Ref ref) {
    final argument = this.argument as int;
    return savedRecipe(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SavedRecipeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$savedRecipeHash() => r'7d4b7a4879579e95e464504523a1af698f884d7e';

/// One saved recipe, or null when [id] is unknown.
///
/// `SavedRecipeLoader` is the one consumer: `/recipe/saved/:id` reopens a
/// recipe by this id rather than through the `extra` a `go_router` push would
/// drop on a browser reload.

final class SavedRecipeFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SavedRecipe?>, int> {
  const SavedRecipeFamily._()
    : super(
        retry: null,
        name: r'savedRecipeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One saved recipe, or null when [id] is unknown.
  ///
  /// `SavedRecipeLoader` is the one consumer: `/recipe/saved/:id` reopens a
  /// recipe by this id rather than through the `extra` a `go_router` push would
  /// drop on a browser reload.

  SavedRecipeProvider call(int id) =>
      SavedRecipeProvider._(argument: id, from: this);

  @override
  String toString() => r'savedRecipeProvider';
}
