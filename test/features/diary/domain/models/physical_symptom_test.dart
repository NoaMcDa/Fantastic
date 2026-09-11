import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhysicalSymptom', () {
    // `SymptomLogMapper` persists each value by `.name`, so these strings are
    // a storage format, not an implementation detail. Renaming one orphans
    // every record that stored it — `design/web_support.md` §4. Spelled out
    // literally rather than derived, so a rename fails here first.
    test('the persisted names are exactly these eight', () {
      expect(PhysicalSymptom.values.map((s) => s.name), [
        'halitosis',
        'constipation',
        'muscleCramps',
        'headache',
        'diarrhea',
        'dizziness',
        'nausea',
        'insomnia',
      ]);
    });

    // Order is occurrence rate descending, so the chip grid puts the symptoms
    // a user is most likely to have felt where they look first. It is
    // deliberately not alphabetical, and reordering changes what renders
    // where — the mapper also sorts stored names by index.
    test('is ordered by occurrence rate, not alphabetically', () {
      final names = PhysicalSymptom.values.map((s) => s.name).toList();

      expect(names, isNot(orderedEquals([...names]..sort())));
      expect(PhysicalSymptom.values.first, PhysicalSymptom.halitosis);
    });

    // The four `SymptomScale` values already ask about energy, clarity,
    // hunger and mood. A symptom naming any of them would let the same day be
    // reported two ways, and the two answers could disagree.
    test('names no state one of the four scales already covers', () {
      const scaleTerritory = [
        'fatigue',
        'energy',
        'brainFog',
        'clarity',
        'focus',
        'mood',
        'irritability',
        'hunger',
        'appetite',
        'craving',
      ];

      for (final symptom in PhysicalSymptom.values) {
        expect(
          scaleTerritory,
          isNot(contains(symptom.name)),
          reason: '${symptom.name} overlaps a 1–5 scale',
        );
      }
    });

    test('every value is distinct', () {
      expect(
        PhysicalSymptom.values.map((s) => s.name).toSet(),
        hasLength(PhysicalSymptom.values.length),
      );
    });
  });
}
