import 'package:fantastic/features/diary/data/mappers/symptom_log_mapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../../../fixtures/fixtures.dart';

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
      final original = SymptomLogFixture.worstDay(id: 7);

      final restored = SymptomLogMapper.toDomain(
        SymptomLogMapper.toIsar(original),
      );

      expect(restored, original);
      expect(restored.notes, 'keto flu');
    });

    test('a null notes field round-trips as null', () {
      final restored = SymptomLogMapper.toDomain(
        SymptomLogMapper.toIsar(SymptomLogFixture.fixture(id: 1)),
      );

      expect(restored.notes, isNull);
    });

    test('boundary scores of 1 and 5 both round-trip', () {
      final worst = SymptomLogMapper.toDomain(
        SymptomLogMapper.toIsar(SymptomLogFixture.worstDay(id: 1)),
      );
      final best = SymptomLogMapper.toDomain(
        SymptomLogMapper.toIsar(SymptomLogFixture.bestDay(id: 2)),
      );

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
      // Five distinct values, so a mapper that assigns the wrong field to the
      // wrong scale cannot pass by coincidence the way an all-3s fixture lets
      // it.
      final original = SymptomLogFixture.fixture(
        id: 3,
        energyScore: 1,
        clarityScore: 2,
        hungerScore: 3,
        physicalScore: 4,
        moodScore: 5,
      );

      final restored = SymptomLogMapper.toDomain(
        SymptomLogMapper.toIsar(original),
      );

      expect(restored.energyScore, 1);
      expect(restored.clarityScore, 2);
      expect(restored.hungerScore, 3);
      expect(restored.physicalScore, 4);
      expect(restored.moodScore, 5);
    });

    test('the date round-trips exactly, time of day included', () {
      final date = DateTime(2026, 9, 10, 21, 30);
      final restored = SymptomLogMapper.toDomain(
        SymptomLogMapper.toIsar(SymptomLogFixture.fixture(id: 4, date: date)),
      );

      expect(restored.date, date);
    });
  });

  group('SymptomLogMapper.toIsar', () {
    test('a null domain id maps to autoIncrement', () {
      expect(
        SymptomLogMapper.toIsar(SymptomLogFixture.fixture()).id,
        Isar.autoIncrement,
      );
    });

    test('a persisted id is carried through unchanged', () {
      expect(SymptomLogMapper.toIsar(SymptomLogFixture.fixture(id: 42)).id, 42);
    });

    test('derives dateIndex from the log date', () {
      final schema = SymptomLogMapper.toIsar(
        SymptomLogFixture.fixture(date: DateTime(2026, 12, 31)),
      );

      expect(schema.dateIndex, 20261231);
    });
  });
}
