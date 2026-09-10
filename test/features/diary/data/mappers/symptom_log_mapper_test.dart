import 'package:fantastic/features/diary/data/mappers/symptom_log_mapper.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

/// Round-trips go through the record key, because the key *is* the date.
SymptomLog _roundTrip(SymptomLog original) => SymptomLogMapper.fromRecord(
  SymptomLogMapper.dateIndex(original.date),
  SymptomLogMapper.toRecord(original),
);

void main() {
  group('SymptomLogMapper.dateIndex', () {
    test('encodes yyyyMMdd', () {
      expect(SymptomLogMapper.dateIndex(DateTime(2026, 9, 10)), 20260910);
    });

    test('zero-pads single-digit months and days', () {
      expect(SymptomLogMapper.dateIndex(DateTime(2026, 1, 2)), 20260102);
    });

    test('ignores the time of day', () {
      expect(
        SymptomLogMapper.dateIndex(DateTime(2026, 9, 10, 23, 59, 59)),
        SymptomLogMapper.dateIndex(DateTime(2026, 9, 10)),
      );
    });

    test('two different days never collide', () {
      expect(
        SymptomLogMapper.dateIndex(DateTime(2026, 9, 10)),
        isNot(SymptomLogMapper.dateIndex(DateTime(2026, 9, 11))),
      );
    });
  });

  group('SymptomLogMapper round-trip', () {
    test('preserves all five scores and notes', () {
      final original = SymptomLogFixture.worstDay(date: DateTime(2026, 9, 10));

      final restored = _roundTrip(original);

      expect(restored, original.copyWith(id: 20260910));
      expect(restored.notes, 'keto flu');
    });

    test('the restored id is the yyyyMMdd key, whatever id went in', () {
      final original = SymptomLogFixture.fixture(
        id: 7,
        date: DateTime(2026, 9, 10),
      );

      expect(_roundTrip(original).id, 20260910);
    });

    test('a null notes field round-trips as null', () {
      expect(_roundTrip(SymptomLogFixture.fixture()).notes, isNull);
    });

    test('boundary scores of 1 and 5 both round-trip', () {
      final worst = _roundTrip(SymptomLogFixture.worstDay());
      final best = _roundTrip(SymptomLogFixture.bestDay());

      expect([
        worst.energyScore,
        worst.clarityScore,
        worst.hungerScore,
        worst.physicalScore,
        worst.moodScore,
      ], everyElement(1));
      expect([
        best.energyScore,
        best.clarityScore,
        best.hungerScore,
        best.physicalScore,
        best.moodScore,
      ], everyElement(5));
    });

    test('each scale keeps its own value — no cross-wiring', () {
      // Five distinct values, so a codec that assigns the wrong field to the
      // wrong scale cannot pass by coincidence the way an all-3s fixture lets
      // it.
      final original = SymptomLogFixture.fixture(
        energyScore: 1,
        clarityScore: 2,
        hungerScore: 3,
        physicalScore: 4,
        moodScore: 5,
      );

      final restored = _roundTrip(original);

      expect(restored.energyScore, 1);
      expect(restored.clarityScore, 2);
      expect(restored.hungerScore, 3);
      expect(restored.physicalScore, 4);
      expect(restored.moodScore, 5);
    });

    test('the date round-trips exactly, time of day included', () {
      final date = DateTime(2026, 9, 10, 21, 30);

      expect(_roundTrip(SymptomLogFixture.fixture(date: date)).date, date);
    });
  });

  group('SymptomLogMapper.toRecord', () {
    // sembast only validates value types at write time, so a codec that emits
    // a DateTime fails at runtime inside the repository rather than here.
    test('emits only sembast-legal values — no DateTime anywhere', () {
      final record = SymptomLogMapper.toRecord(SymptomLogFixture.worstDay());

      for (final value in record.values) {
        expect(
          value,
          anyOf(isNull, isA<num>(), isA<String>(), isA<bool>(), isA<List>()),
          reason: 'sembast stores JSON-compatible values only',
        );
      }
    });

    test('writes the date as epoch milliseconds', () {
      final date = DateTime(2026, 12, 31, 21, 30);
      final record = SymptomLogMapper.toRecord(
        SymptomLogFixture.fixture(date: date),
      );

      expect(record['date'], date.millisecondsSinceEpoch);
    });

    test('carries no id — sembast holds the key outside the value', () {
      expect(
        SymptomLogMapper.toRecord(SymptomLogFixture.fixture(id: 42)),
        isNot(contains('id')),
      );
    });
  });
}
