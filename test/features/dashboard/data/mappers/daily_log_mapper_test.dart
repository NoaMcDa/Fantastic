import 'package:fantastic/features/dashboard/data/mappers/daily_log_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  group('DailyLogMapper.dateIndex', () {
    test('encodes yyyyMMdd', () {
      expect(DailyLogMapper.dateIndex(DateTime(2026, 9, 10)), 20260910);
    });

    test('zero-pads single-digit months and days', () {
      expect(DailyLogMapper.dateIndex(DateTime(2026, 1, 5)), 20260105);
    });

    test('ignores the time component, so any moment in a day maps to one '
        'row', () {
      expect(
        DailyLogMapper.dateIndex(DateTime(2026, 9, 10, 23, 59)),
        DailyLogMapper.dateIndex(DateTime(2026, 9, 10)),
      );
    });
  });

  group('DailyLogMapper round-trip', () {
    test('preserves all ten fields', () {
      final original = DailyLogFixture.fixture(id: 7);

      final restored = DailyLogMapper.toDomain(DailyLogMapper.toIsar(original));

      expect(restored, original);
    });

    test('ketoRatioAvg survives — the field the original schema draft '
        'dropped', () {
      final original = DailyLogFixture.fixture(id: 3, ketoRatioAvg: 2.4);

      final restored = DailyLogMapper.toDomain(DailyLogMapper.toIsar(original));

      expect(restored.ketoRatioAvg, 2.4);
    });

    test('waterMl survives — the schema draft called it `totalWaterMl`', () {
      final original = DailyLogFixture.fixture(id: 4, waterMl: 2750);

      final restored = DailyLogMapper.toDomain(DailyLogMapper.toIsar(original));

      expect(restored.waterMl, 2750);
    });

    test('a day with nothing logged round-trips as zeros, not nulls', () {
      final restored = DailyLogMapper.toDomain(
        DailyLogMapper.toIsar(DailyLogFixture.empty(id: 1)),
      );

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
        id: 1,
        date: DateTime(2026, 3, 1, 14, 30),
      );

      final restored = DailyLogMapper.toDomain(DailyLogMapper.toIsar(original));

      expect(restored.date, DateTime(2026, 3, 1, 14, 30));
    });
  });

  group('DailyLogMapper.toIsar', () {
    test('preserves a non-null id so an update overwrites', () {
      expect(DailyLogMapper.toIsar(DailyLogFixture.fixture(id: 42)).id, 42);
    });

    test('assigns autoIncrement when the domain id is null', () {
      expect(
        DailyLogMapper.toIsar(DailyLogFixture.fixture()).id,
        Isar.autoIncrement,
      );
    });

    test('derives dateIndex from the date', () {
      final log = DailyLogFixture.fixture(date: DateTime(2026, 12, 25, 18, 30));

      expect(DailyLogMapper.toIsar(log).dateIndex, 20261225);
    });
  });
}
