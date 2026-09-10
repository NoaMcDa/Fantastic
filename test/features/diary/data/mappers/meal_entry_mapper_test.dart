import 'package:fantastic/features/diary/data/mappers/meal_entry_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  group('MealEntryMapper.dateIndex', () {
    test('encodes yyyyMMdd', () {
      expect(MealEntryMapper.dateIndex(DateTime(2026, 9, 10)), 20260910);
    });

    test('zero-pads single-digit months and days', () {
      expect(MealEntryMapper.dateIndex(DateTime(2026, 1, 5)), 20260105);
    });

    test('ignores the time component', () {
      expect(
        MealEntryMapper.dateIndex(DateTime(2026, 9, 10, 23, 59)),
        MealEntryMapper.dateIndex(DateTime(2026, 9, 10)),
      );
    });
  });

  group('MealEntryMapper round-trip', () {
    test('preserves every field', () {
      final original = MealEntryFixture.complete(id: 7);

      final restored = MealEntryMapper.toDomain(
        MealEntryMapper.toIsar(original),
      );

      expect(restored, original);
    });

    test('ingredients and imageRef survive — the two fields the original '
        'schema draft dropped', () {
      final original = MealEntryFixture.complete(id: 3);

      final restored = MealEntryMapper.toDomain(
        MealEntryMapper.toIsar(original),
      );

      expect(restored.ingredients, ['olive oil', 'butter']);
      expect(restored.imageRef, 'labels/test.png');
    });

    test('mealName survives — the schema draft called it `name`', () {
      final original = MealEntryFixture.fixture(id: 1, mealName: 'Shakshuka');

      final restored = MealEntryMapper.toDomain(
        MealEntryMapper.toIsar(original),
      );

      expect(restored.mealName, 'Shakshuka');
    });

    test('an empty ingredient list round-trips as empty, not null', () {
      final restored = MealEntryMapper.toDomain(
        MealEntryMapper.toIsar(MealEntryFixture.fixture(id: 1)),
      );

      expect(restored.ingredients, isEmpty);
    });

    test('a null imageRef round-trips as null', () {
      final restored = MealEntryMapper.toDomain(
        MealEntryMapper.toIsar(MealEntryFixture.fixture(id: 1)),
      );

      expect(restored.imageRef, isNull);
    });
  });

  group('MealEntryMapper.toIsar', () {
    test('preserves a non-null id so an update overwrites', () {
      expect(MealEntryMapper.toIsar(MealEntryFixture.fixture(id: 42)).id, 42);
    });

    test('assigns autoIncrement when the domain id is null', () {
      expect(
        MealEntryMapper.toIsar(MealEntryFixture.fixture()).id,
        Isar.autoIncrement,
      );
    });

    test('derives dateIndex from the timestamp', () {
      final entry = MealEntryFixture.fixture(
        timestamp: DateTime(2026, 12, 25, 18, 30),
      );

      expect(MealEntryMapper.toIsar(entry).dateIndex, 20261225);
    });

    test('does not persist ketoRatio — it is computed on the domain model', () {
      // A stored copy could go stale against the macros it derives from.
      final entry = MealEntryFixture.fixture(id: 1, fatG: 40);
      final restored = MealEntryMapper.toDomain(MealEntryMapper.toIsar(entry));

      expect(restored.ketoRatio, entry.ketoRatio);
      expect(restored.ketoRatio, closeTo(2.0, 0.0001));
    });
  });
}
