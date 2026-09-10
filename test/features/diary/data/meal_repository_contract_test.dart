import 'package:fantastic/features/diary/data/repositories/isar_meal_repository.dart';
import 'package:fantastic/features/diary/data/schemas/isar_meal_entry.dart';
import 'package:fantastic/features/diary/domain/repositories/meal_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../../fixtures/fixtures.dart';
import '../../../helpers/test_isar.dart';

/// The contract every [MealRepository] implementation must satisfy.
///
/// A top-level function taking a factory rather than a fixed implementation:
/// any future backing store is run against these same cases, which is what
/// enforces Liskov substitution at the test level. [factory] is called fresh
/// in `setUp`, after the enclosing group has opened its own storage.
void runMealRepositoryContractTests(MealRepository Function() factory) {
  late MealRepository repo;

  setUp(() => repo = factory());

  group('save', () {
    test('returns an entity with a non-null id', () async {
      final saved = await repo.save(MealEntryFixture.fixture());

      expect(saved.id, isNotNull);
    });

    test('the saved entity is retrievable by the returned id', () async {
      final saved = await repo.save(MealEntryFixture.fixture());

      expect(await repo.findById(saved.id!), saved);
    });

    test('preserves every field apart from the assigned id', () async {
      final original = MealEntryFixture.complete();

      final saved = await repo.save(original);

      expect(saved, original.copyWith(id: saved.id));
    });

    test('with an existing id updates rather than duplicating', () async {
      final saved = await repo.save(MealEntryFixture.fixture());

      final updated = await repo.save(
        saved.copyWith(mealName: 'Renamed', fatG: 40),
      );

      expect(updated.id, saved.id);
      expect(await repo.findAll(), hasLength(1));
      expect((await repo.findById(saved.id!))!.mealName, 'Renamed');
    });

    test('two inserts get distinct ids', () async {
      final first = await repo.save(MealEntryFixture.fixture());
      final second = await repo.save(MealEntryFixture.fixture());

      expect(first.id, isNot(second.id));
    });
  });

  group('findById', () {
    test('returns null for an unknown id', () async {
      expect(await repo.findById(9999), isNull);
    });
  });

  group('findByDate', () {
    test('returns an empty list when nothing is stored', () async {
      expect(await repo.findByDate(MealEntryFixture.defaultTimestamp), isEmpty);
    });

    test('returns only entries for the given date', () async {
      final onDate = await repo.save(
        MealEntryFixture.fixture(timestamp: DateTime(2026, 9, 9, 8)),
      );
      await repo.save(
        MealEntryFixture.fixture(timestamp: DateTime(2026, 9, 10, 8)),
      );

      final found = await repo.findByDate(DateTime(2026, 9, 9));

      expect(found, [onDate]);
    });

    test('matches on the calendar day, ignoring the time of day', () async {
      final earlyMorning = await repo.save(
        MealEntryFixture.fixture(timestamp: DateTime(2026, 9, 9, 0, 1)),
      );
      final lateNight = await repo.save(
        MealEntryFixture.fixture(timestamp: DateTime(2026, 9, 9, 23, 59)),
      );

      final found = await repo.findByDate(DateTime(2026, 9, 9, 15, 30));

      expect(found, containsAll([earlyMorning, lateNight]));
      expect(found, hasLength(2));
    });

    test('returns every entry stored for the date', () async {
      await repo.save(MealEntryFixture.fixture(mealName: 'Breakfast'));
      await repo.save(MealEntryFixture.fixture(mealName: 'Lunch'));
      await repo.save(MealEntryFixture.fixture(mealName: 'Dinner'));

      expect(
        await repo.findByDate(MealEntryFixture.defaultTimestamp),
        hasLength(3),
      );
    });
  });

  group('findAll', () {
    test('returns an empty list when nothing is stored', () async {
      expect(await repo.findAll(), isEmpty);
    });

    test('returns entries newest first', () async {
      // Saved oldest-first so passing cannot be an artefact of insertion
      // order.
      final oldest = await repo.save(
        MealEntryFixture.fixture(timestamp: DateTime(2026, 9, 7, 12)),
      );
      final newest = await repo.save(
        MealEntryFixture.fixture(timestamp: DateTime(2026, 9, 9, 12)),
      );
      final middle = await repo.save(
        MealEntryFixture.fixture(timestamp: DateTime(2026, 9, 8, 12)),
      );

      expect(await repo.findAll(), [newest, middle, oldest]);
    });

    test('spans dates — it is not scoped to a single day', () async {
      await repo.save(
        MealEntryFixture.fixture(timestamp: DateTime(2026, 9, 9, 12)),
      );
      await repo.save(
        MealEntryFixture.fixture(timestamp: DateTime(2026, 1, 1, 12)),
      );

      expect(await repo.findAll(), hasLength(2));
    });
  });

  group('delete', () {
    test('removes the record permanently', () async {
      final saved = await repo.save(MealEntryFixture.fixture());

      await repo.delete(saved.id!);

      expect(await repo.findById(saved.id!), isNull);
      expect(await repo.findAll(), isEmpty);
    });

    test('is idempotent for an unknown id', () async {
      await expectLater(repo.delete(9999), completes);
    });

    test('deleting one entry leaves the others intact', () async {
      final kept = await repo.save(MealEntryFixture.fixture());
      final removed = await repo.save(MealEntryFixture.fixture());

      await repo.delete(removed.id!);

      expect(await repo.findAll(), [kept]);
    });

    test('drops the entry from findByDate too', () async {
      final saved = await repo.save(MealEntryFixture.fixture());

      await repo.delete(saved.id!);

      expect(await repo.findByDate(MealEntryFixture.defaultTimestamp), isEmpty);
    });
  });

  group('round-trip', () {
    // #35's first draft of the schema dropped `ingredients` and `imageRef`.
    // This case is what would have caught it.
    test('ingredients and imageRef survive a save/find round-trip', () async {
      final saved = await repo.save(MealEntryFixture.complete());

      final found = await repo.findById(saved.id!);

      expect(found!.ingredients, ['olive oil', 'butter']);
      expect(found.imageRef, 'labels/test.png');
    });

    test('an empty ingredient list round-trips as empty, not null', () async {
      final saved = await repo.save(
        MealEntryFixture.fixture(ingredients: const []),
      );

      expect((await repo.findById(saved.id!))!.ingredients, isEmpty);
    });

    test('a null imageRef round-trips as null', () async {
      final saved = await repo.save(MealEntryFixture.fixture());

      expect((await repo.findById(saved.id!))!.imageRef, isNull);
    });
  });
}

void main() {
  group('IsarMealRepository', () {
    late Isar isar;

    setUp(() async => isar = await openTestIsar([IsarMealEntrySchema]));
    tearDown(() async => closeTestIsar(isar));

    runMealRepositoryContractTests(() => IsarMealRepository(isar));
  });
}
