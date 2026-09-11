import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';

/// Test data for [SymptomLog].
///
/// Defaults sit mid-scale so a test can move any score in either direction
/// without leaving the valid 1–5 range. The date is fixed, not
/// `DateTime.now()`.
abstract final class SymptomLogFixture {
  /// The fixed date every fixture uses unless overridden.
  static final DateTime defaultDate = DateTime(2026, 9, 9);

  /// A neutral day — every scale at 3, no physical symptoms.
  static SymptomLog fixture({
    int? id,
    DateTime? date,
    int energyScore = 3,
    int clarityScore = 3,
    int hungerScore = 3,
    int moodScore = 3,
    Set<PhysicalSymptom> symptoms = const <PhysicalSymptom>{},
    String? notes,
  }) => SymptomLog(
    id: id,
    date: date ?? defaultDate,
    energyScore: energyScore,
    clarityScore: clarityScore,
    hungerScore: hungerScore,
    moodScore: moodScore,
    symptoms: symptoms,
    notes: notes,
  );

  /// Every scale at its lower bound, with a note — the keto-flu shape, and a
  /// boundary case for anything that persists these values.
  ///
  /// Carries the symptoms that actually constitute keto flu. The fixture is
  /// named for the condition, so it should contain it.
  static SymptomLog worstDay({int? id, DateTime? date}) => fixture(
    id: id,
    date: date,
    energyScore: 1,
    clarityScore: 1,
    hungerScore: 1,
    moodScore: 1,
    symptoms: const {
      PhysicalSymptom.headache,
      PhysicalSymptom.dizziness,
      PhysicalSymptom.muscleCramps,
      PhysicalSymptom.nausea,
    },
    notes: 'keto flu',
  );

  /// Four different scores, one per scale, ascending in declaration order —
  /// energy 1, clarity 2, hunger 3, mood 4 — plus a deliberately awkward
  /// symptom set.
  ///
  /// Use this — not [fixture] — in any test that asserts a value reaches the
  /// right place. Every scale defaults to 3, so a widget that reads
  /// `energyScore` where it means `moodScore`, or a mapper that crosses two
  /// columns, passes against the neutral fixture and fails against this one.
  /// `m1_handoff.md` records the cross-wiring this class of fixture hides;
  /// `m5_preflight.md` §1.1 is the bug it predicted, arriving.
  ///
  /// The same principle governs [symptoms] here: it holds exactly one value,
  /// and that value is neither the first nor the last of
  /// `PhysicalSymptom.values`. A widget that renders `PhysicalSymptom.values`
  /// instead of `log.symptoms` passes against an all-eight set and fails
  /// against this one; a chip row that always renders the first enum value
  /// passes against a set containing `halitosis` and fails against this one.
  static SymptomLog varied({int? id, DateTime? date, String? notes}) => fixture(
    id: id,
    date: date,
    energyScore: 1,
    clarityScore: 2,
    hungerScore: 3,
    moodScore: 4,
    symptoms: const {PhysicalSymptom.muscleCramps},
    notes: notes,
  );

  /// Every scale at its upper bound and no symptoms — the other boundary.
  static SymptomLog bestDay({int? id, DateTime? date}) => fixture(
    id: id,
    date: date,
    energyScore: 5,
    clarityScore: 5,
    hungerScore: 5,
    moodScore: 5,
  );
}
