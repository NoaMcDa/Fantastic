import 'package:fantastic/features/diary/presentation/symptom_scale.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/fixtures.dart';

void main() {
  group('the five scales', () {
    test('are the five the model stores', () {
      expect(SymptomScale.values, hasLength(5));
      expect(SymptomScale.values.map((s) => s.name), [
        'energy',
        'clarity',
        'hunger',
        'physical',
        'mood',
      ]);
    });

    // The defect `design/m5_preflight.md` §1.1 found: every M5 issue called
    // the fifth scale "brain fog" and labelled it ערפל. It is mood.
    test('the fifth is mood, not brain fog', () {
      expect(SymptomScale.values.last, SymptomScale.mood);
      expect(SymptomScale.mood.label, 'מצב רוח');
      expect(
        SymptomScale.values.map((s) => s.label),
        isNot(contains(contains('ערפל'))),
      );
    });

    test('every scale has a label, a short label and an icon', () {
      for (final scale in SymptomScale.values) {
        expect(scale.label, isNotEmpty, reason: '${scale.name} label');
        expect(scale.shortLabel, isNotEmpty, reason: '${scale.name} short');
        expect(scale.shortLabel.length, lessThanOrEqualTo(scale.label.length));
      }
    });

    test('no two scales share a label or an icon', () {
      expect(SymptomScale.values.map((s) => s.label).toSet(), hasLength(5));
      expect(SymptomScale.values.map((s) => s.icon).toSet(), hasLength(5));
    });
  });

  group('scoreIn', () {
    // Against `varied()`, not the all-3s default: a reader wired to the wrong
    // field passes every assertion the neutral fixture can make.
    test('reads each scale from its own field', () {
      final log = SymptomLogFixture.varied();

      expect(SymptomScale.energy.scoreIn(log), 1);
      expect(SymptomScale.clarity.scoreIn(log), 2);
      expect(SymptomScale.hunger.scoreIn(log), 3);
      expect(SymptomScale.physical.scoreIn(log), 4);
      expect(SymptomScale.mood.scoreIn(log), 5);
    });
  });

  group('buildSymptomLog', () {
    Map<SymptomScale, int> variedScores() => {
      SymptomScale.energy: 1,
      SymptomScale.clarity: 2,
      SymptomScale.hunger: 3,
      SymptomScale.physical: 4,
      SymptomScale.mood: 5,
    };

    test('writes each score into its own field', () {
      final log = buildSymptomLog(
        date: DateTime(2026, 9, 9),
        scores: variedScores(),
      );

      expect(log.energyScore, 1);
      expect(log.clarityScore, 2);
      expect(log.hungerScore, 3);
      expect(log.physicalScore, 4);
      expect(log.moodScore, 5);
    });

    // The round trip is what keeps the two directions honest: a pair of
    // crossed fields in one of them alone would show up here.
    test('round-trips through scoreIn unchanged', () {
      final log = buildSymptomLog(
        date: DateTime(2026, 9, 9),
        scores: variedScores(),
      );

      for (final scale in SymptomScale.values) {
        expect(scale.scoreIn(log), variedScores()[scale]);
      }
    });

    test('carries the id and the note through an edit', () {
      final log = buildSymptomLog(
        date: DateTime(2026, 9, 9),
        scores: variedScores(),
        id: 20260909,
        notes: 'ישנתי רע',
      );

      expect(log.id, 20260909);
      expect(log.notes, 'ישנתי רע');
    });

    test('normalises the date to midnight', () {
      final log = buildSymptomLog(
        date: DateTime(2026, 9, 9, 23, 59, 59),
        scores: variedScores(),
      );

      expect(log.date, DateTime(2026, 9, 9));
    });
  });
}
