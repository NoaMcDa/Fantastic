import 'package:fantastic/features/diary/data/mappers/meal_entry_mapper.dart';
import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

/// Meals keep sembast's own auto-incrementing key, so a round-trip needs a key
/// supplied the way the repository supplies it — from the store, not from the
/// record.
MealEntry _roundTrip(MealEntry original, {int key = 7}) =>
    MealEntryMapper.fromRecord(key, MealEntryMapper.toRecord(original));

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
    test('preserves every field, with the key as the id', () {
      final original = MealEntryFixture.complete(id: 7);

      expect(_roundTrip(original), original);
    });

    test('ingredients and imageRef survive — the two fields the original '
        'schema draft dropped', () {
      final restored = _roundTrip(MealEntryFixture.complete(id: 3), key: 3);

      expect(restored.ingredients, ['olive oil', 'butter']);
      expect(restored.imageRef, 'labels/test.png');
    });

    test('mealName survives — the schema draft called it `name`', () {
      final original = MealEntryFixture.fixture(mealName: 'Shakshuka');

      expect(_roundTrip(original).mealName, 'Shakshuka');
    });

    test('an empty ingredient list round-trips as empty, not null', () {
      expect(_roundTrip(MealEntryFixture.fixture()).ingredients, isEmpty);
    });

    test('a null imageRef round-trips as null', () {
      expect(_roundTrip(MealEntryFixture.fixture()).imageRef, isNull);
    });

    test('the restored ingredient list is mutable', () {
      // sembast hands back an immutable list that throws on mutation, so the
      // codec copies rather than casts. Without the copy this line throws.
      final restored = _roundTrip(MealEntryFixture.complete());

      expect(() => restored.ingredients.add('ghee'), returnsNormally);
    });

    test('does not persist ketoRatio — it is computed on the domain model', () {
      // A stored copy could go stale against the macros it derives from.
      final entry = MealEntryFixture.fixture(fatG: 40);
      final restored = _roundTrip(entry);

      expect(restored.ketoRatio, entry.ketoRatio);
      expect(restored.ketoRatio, closeTo(2.0, 0.0001));
    });

    // The store round-trips through JSON, which does not keep Dart's
    // int/double distinction: a whole 40.0 comes back as an int. The codec
    // reads every number through `num`, so this must not throw.
    test('a whole double stored as an int still restores as a double', () {
      final record = Map<String, Object?>.from(
        MealEntryMapper.toRecord(MealEntryFixture.fixture(fatG: 40)),
      )..['fatG'] = 40;

      expect(MealEntryMapper.fromRecord(1, record).fatG, 40.0);
    });
  });

  group('MealEntryMapper.toRecord', () {
    // sembast only validates value types at write time, so a codec that emits
    // a DateTime fails at runtime inside the repository rather than here.
    test('emits only sembast-legal values — no DateTime anywhere', () {
      final record = MealEntryMapper.toRecord(MealEntryFixture.complete());

      for (final value in record.values) {
        expect(
          value,
          anyOf(isNull, isA<num>(), isA<String>(), isA<bool>(), isA<List>()),
          reason: 'sembast stores JSON-compatible values only',
        );
      }
    });

    test('writes the timestamp as epoch milliseconds', () {
      final timestamp = DateTime(2026, 12, 25, 18, 30);
      final record = MealEntryMapper.toRecord(
        MealEntryFixture.fixture(timestamp: timestamp),
      );

      expect(record['timestamp'], timestamp.millisecondsSinceEpoch);
    });

    test('denormalises dateIndex from the timestamp, for findByDate', () {
      final entry = MealEntryFixture.fixture(
        timestamp: DateTime(2026, 12, 25, 18, 30),
      );

      expect(MealEntryMapper.toRecord(entry)['dateIndex'], 20261225);
    });

    test('carries no id — sembast holds the key outside the value', () {
      expect(
        MealEntryMapper.toRecord(MealEntryFixture.fixture(id: 42)),
        isNot(contains('id')),
      );
    });
  });

  group('source', () {
    /// A minimal stored record, as `toRecord` writes one.
    Map<String, Object?> record({Object? source = 'manual'}) => {
      'mealName': 'Test Meal',
      'fatG': 20,
      'netCarbsG': 5,
      'proteinG': 15,
      'timestamp': DateTime(2026, 9, 9, 12).millisecondsSinceEpoch,
      'ingredients': <String>[],
      'imageRef': null,
      'dateIndex': 20260909,
      if (source != _absent) 'source': source,
    };

    test('is written by name, never as an enum or an ordinal', () {
      final emitted = MealEntryMapper.toRecord(
        MealEntryFixture.fixture(source: MacroSource.estimatedFromPhoto),
      );

      expect(emitted['source'], 'estimatedFromPhoto');
      expect(emitted['source'], isA<String>());
    });

    test('round-trips for every value', () {
      for (final value in MacroSource.values) {
        final emitted = MealEntryMapper.toRecord(
          MealEntryFixture.fixture(source: value),
        );

        expect(
          MealEntryMapper.fromRecord(1, emitted).source,
          value,
          reason: value.name,
        );
      }
    });

    // The record shape that exists in every install predating M15. sembast is
    // schemaless, so a throw here would surface on *read*, in a user's own
    // data, and never in CI.
    test('a record with no source key decodes as manual', () {
      final stored = record(source: _absent);

      expect(stored.containsKey('source'), isFalse);
      expect(MealEntryMapper.fromRecord(1, stored).source, MacroSource.manual);
    });

    test('a null source decodes as manual', () {
      expect(
        MealEntryMapper.fromRecord(1, record(source: null)).source,
        MacroSource.manual,
      );
    });

    // What a downgrade, or a backup restored from a newer build, looks like.
    // The macros are still valid; only the label is unrecognised.
    test('an unrecognised name decodes as manual and does not throw', () {
      expect(
        MealEntryMapper.fromRecord(1, record(source: 'fromTheFuture')).source,
        MacroSource.manual,
      );
    });

    test('a non-String source decodes as manual and does not throw', () {
      expect(
        MealEntryMapper.fromRecord(1, record(source: 7)).source,
        MacroSource.manual,
      );
    });
  });
}

/// Sentinel meaning "omit the key entirely", which `null` cannot express here
/// because a stored `null` is its own case.
const Object _absent = Object();
