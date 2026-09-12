import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/features/recipe/data/repositories/sembast_saved_recipe_repository.dart';
import 'package:fantastic/features/recipe/domain/repositories/saved_recipe_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The recipe feature's repository wiring.
///
/// Returns the **domain interface**, not the sembast class, so a consumer
/// cannot reach past the abstraction to a store-specific method — the layer
/// rule enforced by the type system rather than by review.
///
/// `ref.watch(databaseProvider)` yields a `Database` directly: the provider is
/// synchronous, and throws a descriptive `UnimplementedError` if the app root
/// never overrode it.
@riverpod
SavedRecipeRepository savedRecipeRepository(Ref ref) =>
    SembastSavedRecipeRepository(ref.watch(databaseProvider));
