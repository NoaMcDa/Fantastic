import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed so every case is deterministic — never DateTime.now().
final _date = DateTime(2026, 9, 9);

void main() {
  group('DailyLog defaults', () {
    test('all nine numeric fields default to zero when only date is given', () {
      final log = DailyLog(date: _date);

      expect(log.totalFatG, 0);
      expect(log.totalNetCarbsG, 0);
      expect(log.totalProteinG, 0);
      expect(log.waterMl, 0);
      expect(log.sodiumMg, 0);
      expect(log.potassiumMg, 0);
      expect(log.magnesiumMg, 0);
      expect(log.ketoRatioAvg, 0);
    });

    test('id defaults to null before persistence', () {
      expect(DailyLog(date: _date).id, isNull);
    });

    test('an unlogged day is zero, not unknown', () {
      // There is deliberately no "null macro" state — a day with no meals
      // reads as zero so the dashboard never has to special-case null.
      expect(DailyLog(date: _date).totalFatG, isNotNull);
    });
  });

  group('DailyLog.copyWith', () {
    test('returns a new instance, not the same reference', () {
      final original = DailyLog(date: _date);
      final copy = original.copyWith(totalFatG: 120);

      expect(identical(original, copy), isFalse);
      expect(copy.totalFatG, 120);
    });

    test('leaves untouched fields unchanged', () {
      final copy = DailyLog(
        date: _date,
        waterMl: 2000,
        ketoRatioAvg: 1.8,
      ).copyWith(totalFatG: 120);

      expect(copy.waterMl, 2000);
      expect(copy.ketoRatioAvg, 1.8);
      expect(copy.date, _date);
    });

    test('with no arguments returns an equal instance', () {
      final original = DailyLog(date: _date, sodiumMg: 3500);

      expect(original.copyWith(), original);
    });

    test('overrides every field', () {
      final other = DateTime(2030);
      final copy = DailyLog(date: _date).copyWith(
        id: 3,
        date: other,
        totalFatG: 1,
        totalNetCarbsG: 2,
        totalProteinG: 3,
        waterMl: 4,
        sodiumMg: 5,
        potassiumMg: 6,
        magnesiumMg: 7,
        ketoRatioAvg: 8,
      );

      expect(copy.id, 3);
      expect(copy.date, other);
      expect(copy.totalFatG, 1);
      expect(copy.totalNetCarbsG, 2);
      expect(copy.totalProteinG, 3);
      expect(copy.waterMl, 4);
      expect(copy.sodiumMg, 5);
      expect(copy.potassiumMg, 6);
      expect(copy.magnesiumMg, 7);
      expect(copy.ketoRatioAvg, 8);
    });
  });

  group('DailyLog equality', () {
    test('two instances with identical field values are equal', () {
      expect(DailyLog(date: _date), DailyLog(date: _date));
      expect(DailyLog(date: _date).hashCode, DailyLog(date: _date).hashCode);
    });

    test('two instances differing only in ketoRatioAvg are not equal', () {
      expect(
        DailyLog(date: _date, ketoRatioAvg: 1.5),
        isNot(DailyLog(date: _date, ketoRatioAvg: 2.0)),
      );
    });

    test('two instances differing only in waterMl are not equal', () {
      expect(
        DailyLog(date: _date, waterMl: 1000),
        isNot(DailyLog(date: _date)),
      );
    });

    test('two instances differing only in date are not equal', () {
      expect(DailyLog(date: _date), isNot(DailyLog(date: DateTime(2030))));
    });
  });
}
