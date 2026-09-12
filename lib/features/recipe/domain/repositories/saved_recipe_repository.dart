import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';

/// Persistence contract for [SavedRecipe].
///
/// The application layer and its tests depend on this abstraction, never on
/// the store. Methods return plain futures and **throw** typed exceptions on
/// failure — see `design/base_design.md` §Error Handling Contract for why
/// `Result<T>` was dropped. A null result means "absent", never "failed".
abstract interface class SavedRecipeRepository {
  /// Inserts [recipe], or updates it when [SavedRecipe.id] is non-null.
  Future<SavedRecipe> save(SavedRecipe recipe);

  /// Every saved recipe, newest first by [SavedRecipe.savedAt].
  Future<List<SavedRecipe>> findAll();

  /// Returns the recipe with [id], or null if not found.
  Future<SavedRecipe?> findById(int id);

  /// Permanently deletes [id]. No-op if not found.
  Future<void> deleteById(int id);
}
