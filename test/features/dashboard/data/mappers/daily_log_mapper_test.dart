import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/data/mappers/daily_log_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

/// Round-trips go through the record key, because the key *is* the date:
/// `fromRecord` takes it as an argument, so a round-trip that invented its own
/// key would not be testing what the repository does.
DailyLog _roundTrip(DailyLog original) => DailyLogMapper.fromRecord(
  DailyLogMapper.dateIndex(original.date),
  DailyLogMapper.toRecord(original),
);

void main() {
  group('DailyLogMapper.dateIndex', () {
    test('encodes yyyyMMdd', () {
      expect(DailyLogMapper.dateIndex(DateTime(2026, 9, 10)), 20260910);
    });

    test('zero-pads single-digit months and days', () {
      expect(DailyLogMapper.dateIndex(DateTime(2026, 1, 5)), 20260105);
    });

    test('ignores the time component, so any moment in a day maps to one '
        'record', () {
      expect(
        DailyLogMapper.dateIndex(DateTime(2026, 9, 10, 23, 59)),
        DailyLogMapper.dateIndex(DateTime(2026, 9, 10)),
      );
    });
  });

  group('DailyLogMapper round-trip', () {
    test('preserves all nine value fields', () {
      final original = DailyLogFixture.fixture(date: DateTime(2026, 9, 10));

      // The id is the date key, so it is asserted separately below rather
      // than carried through the fixture.
      expect(_roundTrip(original), original.copyWith(id: 20260910));
    });

    test('the restored id is the yyyyMMdd key, whatever id went in', () {
      final original = DailyLogFixture.fixture(
        id: 7,
        date: DateTime(2026, 9, 10),
      );

      expect(_roundTrip(original).id, 20260910);
    });

    test('ketoRatioAvg survives — the field the original schema draft '
        'dropped', () {
      expect(
        _roundTrip(DailyLogFixture.fixture(ketoRatioAvg: 2.4)).ketoRatioAvg,
        2.4,
      );
    });

    test('waterMl survives — the schema draft called it `totalWaterMl`', () {
      expect(_roundTrip(DailyLogFixture.fixture(waterMl: 2750)).waterMl, 2750);
    });

    test('a day with nothing logged round-trips as zeros, not nulls', () {
      final restored = _roundTrip(DailyLogFixture.empty());

      expect(restored.totalFatG, 0);
      expect(restored.totalNetCarbsG, 0);
      expect(restored.totalProteinG, 0);
      expect(restored.waterMl, 0);
      expect(restored.sodiumMg, 0);
      expect(restored.potassiumMg, 0);
      expect(restored.magnesiumMg, 0);
      expect(restored.ketoRatioAvg, 0);
    });

    test('the date round-trips exactly, not just its yyyyMMdd key', () {
      final original = DailyLogFixture.fixture(
        date: DateTime(2026, 3, 1, 14, 30),
      );

      expect(_roundTrip(original).date, DateTime(2026, 3, 1, 14, 30));
    });

    // The store round-trips through JSON, which does not keep Dart's
    // int/double distinction: a whole 40.0 comes back as an int. The codec
    // reads every number through `num`, so this must not throw.
    test('a whole double stored as an int still restores as a double', () {
      final record = Map<String, Object?>.from(
        DailyLogMapper.toRecord(DailyLogFixture.fixture(waterMl: 2000)),
      )..['waterMl'] = 2000;

      expect(DailyLogMapper.fromRecord(20260910, record).waterMl, 2000.0);
    });
  });

  group('DailyLogMapper.toRecord', () {
    // sembast only validates value types at write time, so a codec that emits
    // a DateTime fails at runtime inside the repository rather than here.
    test('emits only sembast-legal values — no DateTime anywhere', () {
      final record = DailyLogMapper.toRecord(DailyLogFixture.fixture());

      for (final value in record.values) {
        expect(
          value,
          anyOf(isNull, isA<num>(), isA<String>(), isA<bool>(), isA<List>()),
          reason: 'sembast stores JSON-compatible values only',
        );
      }
    });

    test('writes the date as epoch milliseconds', () {
      final date = DateTime(2026, 12, 25, 18, 30);

      expect(
        DailyLogMapper.toRecord(DailyLogFixture.fixture(date: date))['date'],
        date.millisecondsSinceEpoch,
      );
    });

    test('carries no id — sembast holds the key outside the value', () {
      expect(
        DailyLogMapper.toRecord(DailyLogFixture.fixture(id: 42)),
        isNot(contains('id')),
      );
    });
  });

  group('trainingDay', () {
    test('round-trips as true', () {
      final record = DailyLogMapper.toRecord(
        DailyLogFixture.fixture().copyWith(trainingDay: true),
      );

      expect(record['trainingDay'], isTrue);
      expect(DailyLogMapper.fromRecord(1, record).trainingDay, isTrue);
    });

    test('round-trips as false', () {
      final record = DailyLogMapper.toRecord(DailyLogFixture.fixture());

      expect(record['trainingDay'], isFalse);
      expect(DailyLogMapper.fromRecord(1, record).trainingDay, isFalse);
    });

    // There is no migration step in this app, so the codec is where an added
    // field is made backward-readable. Every day logged before the chip
    // shipped meant "not a training day".
    test('a record written before the field existed reads as false', () {
      final record = Map<String, Object?>.from(
        DailyLogMapper.toRecord(DailyLogFixture.fixture()),
      )..remove('trainingDay');

      expect(DailyLogMapper.fromRecord(1, record).trainingDay, isFalse);
    });
  });
}
