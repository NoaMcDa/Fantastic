import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/recipe/data/mappers/saved_recipe_mapper.dart';
import 'package:fantastic/features/recipe/data/repositories/sembast_saved_recipe_repository.dart';
import 'package:fantastic/features/recipe/domain/repositories/saved_recipe_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../../../fixtures/fixtures.dart';
import '../../../helpers/test_database.dart';

/// The contract every [SavedRecipeRepository] implementation must satisfy.
///
/// A top-level function taking a factory rather than a fixed implementation:
/// any future backing store is run against these same cases, which is what
/// enforces Liskov substitution at the test level. [factory] is called fresh
/// in `setUp`, after the enclosing group has opened its own storage.
void runSavedRecipeRepositoryContractTests(
  SavedRecipeRepository Function() factory, {
  required Future<void> Function() breakStore,
}) {
  late SavedRecipeRepository repo;

  setUp(() => repo = factory());

  group('save', () {
    test('save assigns an id and the recipe is retrievable by it', () async {
      final saved = await repo.save(SavedRecipeFixture.fixture());

      expect(saved.id, isNotNull);
      expect(await repo.findById(saved.id!), saved);
    });

    test('preserves every field apart from the assigned id', () async {
      final original = SavedRecipeFixture.withPerServing();

      final saved = await repo.save(original);

      expect(saved, original.copyWith(id: saved.id));
    });

    test('save with a non-null id updates rather than inserting', () async {
      final saved = await repo.save(SavedRecipeFixture.fixture());

      final updated = await repo.save(saved.copyWith(title: 'שם חדש'));

      expect(updated.id, saved.id);
      expect(await repo.findAll(), hasLength(1));
      expect((await repo.findById(saved.id!))!.title, 'שם חדש');
    });

    test('two inserts get distinct ids', () async {
      final first = await repo.save(SavedRecipeFixture.fixture());
      final second = await repo.save(SavedRecipeFixture.fixture());

      expect(first.id, isNot(second.id));
    });

    // The heart of the issue: auto-increment keying, not `dateIndex`. A
    // daily-store pattern would silently overwrite the second recipe.
    test('two recipes saved on the same day both persist', () async {
      final sameDay = DateTime(2026, 9, 9, 8);

      final first = await repo.save(
        SavedRecipeFixture.fixture(title: 'מתכון ראשון', savedAt: sameDay),
      );
      final second = await repo.save(
        SavedRecipeFixture.fixture(
          title: 'מתכון שני',
          savedAt: sameDay.add(const Duration(hours: 3)),
        ),
      );

      expect(first.id, isNot(second.id));
      final all = await repo.findAll();
      expect(all, hasLength(2));
      expect(
        all.map((r) => r.title),
        containsAll(['מתכון ראשון', 'מתכון שני']),
      );
    });
  });

  group('findById', () {
    test('returns null for an unknown id', () async {
      expect(await repo.findById(9999), isNull);
    });
  });

  group('findAll', () {
    test('returns an empty list when nothing is stored', () async {
      expect(await repo.findAll(), isEmpty);
    });

    test('findAll returns newest first', () async {
      // Saved oldest-first so passing cannot be an artefact of insertion
      // order.
      final oldest = await repo.save(
        SavedRecipeFixture.fixture(savedAt: DateTime(2026, 9, 7, 12)),
      );
      final newest = await repo.save(
        SavedRecipeFixture.fixture(savedAt: DateTime(2026, 9, 9, 12)),
      );
      final middle = await repo.save(
        SavedRecipeFixture.fixture(savedAt: DateTime(2026, 9, 8, 12)),
      );

      expect(await repo.findAll(), [newest, middle, oldest]);
    });
  });

  group('deleteById', () {
    test('deleteById removes it', () async {
      final saved = await repo.save(SavedRecipeFixture.fixture());

      await repo.deleteById(saved.id!);

      expect(await repo.findById(saved.id!), isNull);
      expect(await repo.findAll(), isEmpty);
    });

    test('deleteById for a missing id is a no-op', () async {
      await expectLater(repo.deleteById(9999), completes);
    });

    test('deleting one recipe leaves the others intact', () async {
      final kept = await repo.save(SavedRecipeFixture.fixture());
      final removed = await repo.save(SavedRecipeFixture.fixture());

      await repo.deleteById(removed.id!);

      expect(await repo.findAll(), [kept]);
    });
  });

  // Every method must surface a storage failure as a typed
  // PersistenceException rather than letting the backing store's own error
  // escape — otherwise `application/` and `presentation/` can only handle a
  // failed write by catching a sembast type, which is the leak the repository
  // abstraction exists to prevent.
  group(
    'after breakStore each of the four methods throws PersistenceException',
    () {
      setUp(() async => breakStore());

      test('save', () async {
        await expectLater(
          repo.save(SavedRecipeFixture.fixture()),
          throwsA(isA<PersistenceException>()),
        );
      });

      test('findAll', () async {
        await expectLater(repo.findAll(), throwsA(isA<PersistenceException>()));
      });

      test('findById', () async {
        await expectLater(
          repo.findById(1),
          throwsA(isA<PersistenceException>()),
        );
      });

      test('deleteById', () async {
        await expectLater(
          repo.deleteById(1),
          throwsA(isA<PersistenceException>()),
        );
      });
    },
  );
}

void main() {
  group('SembastSavedRecipeRepository', () {
    late Database db;

    setUp(() async => db = await openTestDatabase());
    tearDown(() async => closeTestDatabase(db));

    runSavedRecipeRepositoryContractTests(
      () => SembastSavedRecipeRepository(db),
      // Closing the database makes every store access throw
      // `DatabaseException.closed()`, which is a real storage failure from
      // inside the repository rather than a stubbed one.
      breakStore: () => db.close(),
    );
  });

  group('a record with an unknown outcome type', () {
    late Database db;
    late SembastSavedRecipeRepository repo;

    setUp(() async {
      db = await openTestDatabase();
      repo = SembastSavedRecipeRepository(db);
    });
    tearDown(() async => closeTestDatabase(db));

    test('surfaces as PersistenceException, not the raw codec error', () async {
      final record = SavedRecipeMapper.toRecord(
        SavedRecipeFixture.fixture(
          outcomes: [SavedRecipeFixture.alreadyKeto()],
        ),
      );
      final outcomeRecord = Map<String, Object?>.from(
        (record['outcomes']! as List).first as Map,
      );
      outcomeRecord['type'] = 'someFutureType';
      record['outcomes'] = [outcomeRecord];
      final key = await savedRecipesStore.add(db, record);

      await expectLater(
        repo.findById(key),
        throwsA(isA<PersistenceException>()),
      );
      await expectLater(repo.findAll(), throwsA(isA<PersistenceException>()));
    });
  });
}
