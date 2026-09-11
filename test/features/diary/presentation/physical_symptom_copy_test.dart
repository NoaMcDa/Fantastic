import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:fantastic/features/diary/presentation/physical_symptom_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhysicalSymptomCopy', () {
    // Spelled out, not derived: three widgets render these chips, and the
    // defect this table exists to prevent is labelling the wrong symptom.
    // A test that rebuilt the mapping from the extension would agree with any
    // mistake the extension made.
    const expectedLabels = {
      PhysicalSymptom.halitosis: 'ריח פה',
      PhysicalSymptom.constipation: 'עצירות',
      PhysicalSymptom.muscleCramps: 'התכווצויות שרירים',
      PhysicalSymptom.headache: 'כאב ראש',
      PhysicalSymptom.diarrhea: 'שלשול',
      PhysicalSymptom.dizziness: 'סחרחורת',
      PhysicalSymptom.nausea: 'בחילה',
      PhysicalSymptom.insomnia: 'נדודי שינה',
    };

    test('every symptom carries its Hebrew label', () {
      for (final entry in expectedLabels.entries) {
        expect(entry.key.label, entry.value, reason: entry.key.name);
      }
    });

    test('the table covers every value — none left to a default', () {
      expect(expectedLabels.keys, containsAll(PhysicalSymptom.values));
    });

    test('every symptom has an icon', () {
      for (final symptom in PhysicalSymptom.values) {
        expect(symptom.icon, isNotNull, reason: symptom.name);
      }
    });

    // Two chips sharing a label or an icon are indistinguishable on screen,
    // which is the failure mode a per-symptom picker exists to avoid.
    test('no two symptoms share a label or an icon', () {
      final count = PhysicalSymptom.values.length;

      expect(
        PhysicalSymptom.values.map((s) => s.label).toSet(),
        hasLength(count),
      );
      expect(
        PhysicalSymptom.values.map((s) => s.icon).toSet(),
        hasLength(count),
      );
    });

    test('no label is empty or untranslated', () {
      for (final symptom in PhysicalSymptom.values) {
        expect(symptom.label.trim(), isNotEmpty, reason: symptom.name);
        expect(
          symptom.label,
          isNot(contains(symptom.name)),
          reason: '${symptom.name} still shows its enum name',
        );
      }
    });
  });
}
