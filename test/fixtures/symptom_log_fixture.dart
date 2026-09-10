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
