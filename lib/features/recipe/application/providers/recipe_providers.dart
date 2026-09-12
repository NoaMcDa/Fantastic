import 'package:fantastic/features/recipe/data/providers.dart';
import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';
import 'package:fantastic/features/recipe/domain/substitution_engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recipe_providers.g.dart';

/// The shipped [SubstitutionEngine], as a provider so a widget test can
/// override it with a small table rather than asserting against the whole
/// seeded set.
@riverpod
SubstitutionEngine substitutionEngine(Ref ref) => const SubstitutionEngine();

/// Every saved recipe, newest first (#120).
///
/// Invalidated after every write: `RecipeConverterScreen._save` on a
/// successful save, `RecipeLibraryScreen._delete` on both a successful and a
/// failed delete — the failed-delete refetch is what self-heals a row a
/// `Dismissible` already removed from the tree.
@riverpod
Future<List<SavedRecipe>> savedRecipes(Ref ref) =>
    ref.watch(savedRecipeRepositoryProvider).findAll();

/// One saved recipe, or null when [id] is unknown.
///
/// `SavedRecipeLoader` is the one consumer: `/recipe/saved/:id` reopens a
/// recipe by this id rather than through the `extra` a `go_router` push would
/// drop on a browser reload.
@riverpod
Future<SavedRecipe?> savedRecipe(Ref ref, int id) =>
    ref.watch(savedRecipeRepositoryProvider).findById(id);
