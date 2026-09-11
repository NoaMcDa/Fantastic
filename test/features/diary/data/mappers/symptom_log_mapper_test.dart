import 'package:fantastic/features/diary/data/mappers/symptom_log_mapper.dart';
import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
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
    test('preserves all four scores, symptoms, and notes', () {
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
        worst.moodScore,
      ], everyElement(1));
      expect([
        best.energyScore,
        best.clarityScore,
        best.hungerScore,
        best.moodScore,
      ], everyElement(5));
    });

    test('each scale keeps its own value — no cross-wiring', () {
      // Four distinct values, so a codec that assigns the wrong field to the
      // wrong scale cannot pass by coincidence the way an all-3s fixture lets
      // it.
      final original = SymptomLogFixture.fixture(
        energyScore: 1,
        clarityScore: 2,
        hungerScore: 3,
        moodScore: 4,
      );

      final restored = _roundTrip(original);

      expect(restored.energyScore, 1);
      expect(restored.clarityScore, 2);
      expect(restored.hungerScore, 3);
      expect(restored.moodScore, 4);
    });

    test('the date round-trips exactly, time of day included', () {
      final date = DateTime(2026, 9, 10, 21, 30);

      expect(_roundTrip(SymptomLogFixture.fixture(date: date)).date, date);
    });

    test('a non-empty symptom set round-trips intact', () {
      final original = SymptomLogFixture.worstDay();

      expect(_roundTrip(original).symptoms, original.symptoms);
    });

    test('an empty symptom set round-trips as empty', () {
      expect(_roundTrip(SymptomLogFixture.bestDay()).symptoms, isEmpty);
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

    test('writes symptoms as a List<String> of enum names, not a Set', () {
      final record = SymptomLogMapper.toRecord(SymptomLogFixture.worstDay());

      expect(record['symptoms'], isA<List>());
      // Every element is a String, not an enum value.
      for (final entry in record['symptoms']! as List) {
        expect(entry, isA<String>());
      }
    });

    test('toRecord output is sorted by enum index regardless of Set insertion order', () {
      // Build two logs with the same symptoms added in opposite orders.
      final logA = SymptomLogFixture.fixture(
        symptoms: const {
          PhysicalSymptom.nausea,
          PhysicalSymptom.headache,
          PhysicalSymptom.dizziness,
        },
      );
      final logB = SymptomLogFixture.fixture(
        symptoms: const {
          PhysicalSymptom.dizziness,
          PhysicalSymptom.headache,
          PhysicalSymptom.nausea,
        },
      );

      expect(
        SymptomLogMapper.toRecord(logA)['symptoms'],
        SymptomLogMapper.toRecord(logB)['symptoms'],
      );
    });

    test('symptoms are written in ascending enum index order', () {
      final log = SymptomLogFixture.fixture(
        symptoms: const {
          PhysicalSymptom.nausea, // index 6
          PhysicalSymptom.headache, // index 3
          PhysicalSymptom.dizziness, // index 5
        },
      );

      final stored = SymptomLogMapper.toRecord(log)['symptoms']! as List;

      expect(stored, [
        PhysicalSymptom.headache.name, // index 3
        PhysicalSymptom.dizziness.name, // index 5
        PhysicalSymptom.nausea.name, // index 6
      ]);
    });

    test('an empty symptom set writes an empty list', () {
      final record = SymptomLogMapper.toRecord(SymptomLogFixture.bestDay());

      expect(record['symptoms'], isEmpty);
    });
  });

  // `CLAUDE.md` §Local Persistence: every number is decoded through `num`.
  // IndexedDB hands JSON numbers back without the int/double distinction the
  // VM keeps, and sembast validates nothing on write — so a codec mistake
  // surfaces on *read*, in a browser, on a record already stored.
  group('SymptomLogMapper.fromRecord number decoding', () {
    test('decodes scores that come back as doubles', () {
      final log = SymptomLogMapper.fromRecord(20260909, {
        'date': DateTime(2026, 9, 9).millisecondsSinceEpoch.toDouble(),
        'energyScore': 1.0,
        'clarityScore': 2.0,
        'hungerScore': 3.0,
        'moodScore': 5.0,
        'symptoms': <String>[],
        'notes': null,
      });

      expect(log.energyScore, 1);
      expect(log.moodScore, 5);
      expect(log.date, DateTime(2026, 9, 9));
    });
  });

  group('SymptomLogMapper.fromRecord symptom tolerance', () {
    test(
      'returns empty set when symptoms key is absent (pre-change record)',
      () {
        // Simulate a record written before the symptom picker shipped: it has
        // a `physicalScore` and no `symptoms` key at all.
        final log = SymptomLogMapper.fromRecord(20260909, {
          'date': DateTime(2026, 9, 9).millisecondsSinceEpoch,
          'energyScore': 3,
          'clarityScore': 3,
          'hungerScore': 3,
          'moodScore': 3,
          'physicalScore': 3,
          'notes': null,
        });

        expect(log.symptoms, isEmpty);
      },
    );

    test('skips unrecognised names and keeps the recognised ones', () {
      final log = SymptomLogMapper.fromRecord(20260909, {
        'date': DateTime(2026, 9, 9).millisecondsSinceEpoch,
        'energyScore': 3,
        'clarityScore': 3,
        'hungerScore': 3,
        'moodScore': 3,
        'symptoms': ['headache', 'unknownSymptomFromFutureBuild', 'nausea'],
        'notes': null,
      });

      expect(log.symptoms, {PhysicalSymptom.headache, PhysicalSymptom.nausea});
    });

    test('returns empty set when symptoms holds a non-list value', () {
      final log = SymptomLogMapper.fromRecord(20260909, {
        'date': DateTime(2026, 9, 9).millisecondsSinceEpoch,
        'energyScore': 3,
        'clarityScore': 3,
        'hungerScore': 3,
        'moodScore': 3,
        'symptoms': 'headache',
        'notes': null,
      });

      expect(log.symptoms, isEmpty);
    });
  });
}
