import 'package:fantastic/features/diary/domain/models/symptom_log.dart';

/// Test data for [SymptomLog].
///
/// Defaults sit mid-scale so a test can move any score in either direction
/// without leaving the valid 1–5 range. The date is fixed, not
/// `DateTime.now()`.
abstract final class SymptomLogFixture {
  /// The fixed date every fixture uses unless overridden.
  static final DateTime defaultDate = DateTime(2026, 9, 9);

  /// A neutral day — every scale at 3.
  static SymptomLog fixture({
    int? id,
    DateTime? date,
    int energyScore = 3,
    int clarityScore = 3,
    int hungerScore = 3,
    int physicalScore = 3,
    int moodScore = 3,
    String? notes,
  }) => SymptomLog(
    id: id,
    date: date ?? defaultDate,
    energyScore: energyScore,
    clarityScore: clarityScore,
    hungerScore: hungerScore,
    physicalScore: physicalScore,
    moodScore: moodScore,
    notes: notes,
  );

  /// Every scale at its lower bound, with a note — the keto-flu shape, and a
  /// boundary case for anything that persists these values.
  static SymptomLog worstDay({int? id, DateTime? date}) => fixture(
    id: id,
    date: date,
    energyScore: 1,
    clarityScore: 1,
    hungerScore: 1,
    physicalScore: 1,
    moodScore: 1,
    notes: 'keto flu',
  );

  /// Five different scores, one per scale, ascending in declaration order:
  /// energy 1, clarity 2, hunger 3, physical 4, mood 5.
  ///
  /// Use this — not [fixture] — in any test that asserts a score reaches the
  /// right place. Every scale defaults to 3, so a widget that reads
  /// `energyScore` where it means `moodScore`, or a mapper that crosses two
  /// columns, passes against the neutral fixture and fails against this one.
  /// `m1_handoff.md` records the cross-wiring this class of fixture hides;
  /// `m5_preflight.md` §1.1 is the bug it predicted, arriving.
  static SymptomLog varied({int? id, DateTime? date, String? notes}) => fixture(
    id: id,
    date: date,
    energyScore: 1,
    clarityScore: 2,
    hungerScore: 3,
    physicalScore: 4,
    moodScore: 5,
    notes: notes,
  );

  /// Every scale at its upper bound — the other boundary.
  static SymptomLog bestDay({int? id, DateTime? date}) => fixture(
    id: id,
    date: date,
    energyScore: 5,
    clarityScore: 5,
    hungerScore: 5,
    physicalScore: 5,
    moodScore: 5,
  );
}
