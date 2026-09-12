import 'package:fantastic/core/error/persistence_guard.dart';
import 'package:fantastic/features/recipe/data/mappers/saved_recipe_mapper.dart';
import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';
import 'package:fantastic/features/recipe/domain/repositories/saved_recipe_repository.dart';
import 'package:sembast/sembast.dart';

/// The store saved recipes live in.
///
/// Auto-increment, like `mealsStore` — **not** `dateIndex` like the daily
/// stores. A recipe has no natural date key and a user may save three in one
/// afternoon; the daily-store pattern would silently overwrite two of them.
///
/// Created on first write — sembast has no schema to register, so this
/// declaration is the whole registration. Public so a test can assert against
/// the same store the repository writes to, and so
/// `test/core/database/store_names_test.dart` can prove no two features chose
/// the same name.
final savedRecipesStore = intMapStoreFactory.store('saved_recipes');

/// sembast-backed [SavedRecipeRepository].
///
/// The only class in the recipe feature that touches sembast for saved
/// recipes — everything above it depends on the interface, which is what
/// keeps the backing store out of `application/`, `domain/` and
/// `presentation/`. Every method is wrapped in [guardPersistence] so a
/// storage failure reaches those layers as a `PersistenceException` rather
/// than a `DatabaseException`, which would leak the backing store through the
/// very abstraction this class provides.
///
/// Keys are sembast's own auto-incrementing record keys, which is what
/// [SavedRecipe.id] carries.
class SembastSavedRecipeRepository implements SavedRecipeRepository {
  const SembastSavedRecipeRepository(this._db);

  final Database _db;

  /// Upsert: a null id appends at a fresh key, a non-null id overwrites that
  /// key. The key is only known after the write for an insert, so the record
  /// is mapped back with whichever key it landed on.
  @override
  Future<SavedRecipe> save(SavedRecipe recipe) =>
      guardPersistence('SembastSavedRecipeRepository.save', () async {
        final record = SavedRecipeMapper.toRecord(recipe);
        final id = recipe.id;
        if (id == null) {
          return SavedRecipeMapper.fromRecord(
            await savedRecipesStore.add(_db, record),
            record,
          );
        }
        await savedRecipesStore.record(id).put(_db, record);
        return SavedRecipeMapper.fromRecord(id, record);
      });

  @override
  Future<List<SavedRecipe>> findAll() =>
      guardPersistence('SembastSavedRecipeRepository.findAll', () async {
        final snapshots = await savedRecipesStore.find(
          _db,
          // `false` is descending — newest first, as the interface promises.
          finder: Finder(sortOrders: [SortOrder('savedAt', false)]),
        );
        return snapshots.map(_toDomain).toList();
      });

  @override
  Future<SavedRecipe?> findById(int id) =>
      guardPersistence('SembastSavedRecipeRepository.findById', () async {
        final record = await savedRecipesStore.record(id).get(_db);
        return record == null ? null : SavedRecipeMapper.fromRecord(id, record);
      });

  /// Idempotent — sembast returns null for an unknown key rather than
  /// throwing, which is exactly the interface's "no-op if not found".
  @override
  Future<void> deleteById(int id) =>
      guardPersistence('SembastSavedRecipeRepository.deleteById', () async {
        await savedRecipesStore.record(id).delete(_db);
      });

  static SavedRecipe _toDomain(
    RecordSnapshot<int, Map<String, Object?>> snapshot,
  ) => SavedRecipeMapper.fromRecord(snapshot.key, snapshot.value);
}
