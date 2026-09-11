import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:fantastic/features/diary/presentation/symptom_scale.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fixtures/fixtures.dart';

void main() {
  group('the four scales', () {
    test('are the four the model stores', () {
      expect(SymptomScale.values, hasLength(4));
      expect(SymptomScale.values.map((s) => s.name), [
        'energy',
        'clarity',
        'hunger',
        'mood',
      ]);
    });

    // Physical symptoms are a set on the log, not a score. A `physical` value
    // here would need a `scoreIn` arm, and the model has no field to read.
    test('there is no physical scale', () {
      expect(
        SymptomScale.values.map((s) => s.name),
        isNot(contains('physical')),
      );
    });

    // The defect `design/m5_preflight.md` §1.1 found: every M5 issue called
    // the last scale "brain fog" and labelled it ערפל. It is mood.
    test('the last is mood, not brain fog', () {
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
      expect(SymptomScale.values.map((s) => s.label).toSet(), hasLength(4));
      expect(SymptomScale.values.map((s) => s.icon).toSet(), hasLength(4));
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
      expect(SymptomScale.mood.scoreIn(log), 4);
    });
  });

  group('buildSymptomLog', () {
    Map<SymptomScale, int> variedScores() => {
      SymptomScale.energy: 1,
      SymptomScale.clarity: 2,
      SymptomScale.hunger: 3,
      SymptomScale.mood: 4,
    };

    test('writes each score into its own field', () {
      final log = buildSymptomLog(
        date: DateTime(2026, 9, 9),
        scores: variedScores(),
      );

      expect(log.energyScore, 1);
      expect(log.clarityScore, 2);
      expect(log.hungerScore, 3);
      expect(log.moodScore, 4);
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

    test('carries the symptom set through', () {
      final log = buildSymptomLog(
        date: DateTime(2026, 9, 9),
        scores: variedScores(),
        symptoms: const {PhysicalSymptom.headache, PhysicalSymptom.nausea},
      );

      expect(log.symptoms, {PhysicalSymptom.headache, PhysicalSymptom.nausea});
    });

    // `save` upserts on the date, so a build that omits the stored symptoms
    // erases them — the same way omitting the stored note erases it
    // (`design/m5_preflight.md` §1.3). Defaulting to empty is correct only
    // because the sheet always passes what it loaded.
    test('defaults to no symptoms rather than null', () {
      final log = buildSymptomLog(
        date: DateTime(2026, 9, 9),
        scores: variedScores(),
      );

      expect(log.symptoms, isEmpty);
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
