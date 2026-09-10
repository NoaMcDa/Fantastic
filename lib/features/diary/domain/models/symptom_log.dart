import 'package:meta/meta.dart';

/// The user's daily subjective experience across five 1–5 scales, plus an
/// optional free-text note. One record per calendar day.
///
/// Validating the scores here rather than in the UI means no invalid record
/// can reach persistence regardless of which path created it. Note that
/// `assert` is compiled out in release builds — deliberate, since the scores
/// come from a fixed 1–5 picker — so the data layer does not rely on these
/// holding at runtime.
///
/// Pure domain: no Flutter, no persistence package, no Riverpod.
@immutable
class SymptomLog {
  const SymptomLog({
    required this.date,
    required this.energyScore,
    required this.clarityScore,
    required this.hungerScore,
    required this.physicalScore,
    required this.moodScore,
    this.id,
    this.notes,
  }) : assert(energyScore >= 1 && energyScore <= 5, 'energyScore must be 1-5'),
       assert(
         clarityScore >= 1 && clarityScore <= 5,
         'clarityScore must be 1-5',
       ),
       assert(hungerScore >= 1 && hungerScore <= 5, 'hungerScore must be 1-5'),
       assert(
         physicalScore >= 1 && physicalScore <= 5,
         'physicalScore must be 1-5',
       ),
       assert(moodScore >= 1 && moodScore <= 5, 'moodScore must be 1-5');

  /// Null until first persisted. Carries the record's yyyyMMdd key once it
  /// is — see `SymptomLogMapper`.
  final int? id;

  /// Calendar day this log covers — one record per day.
  final DateTime date;

  final int energyScore;
  final int clarityScore;
  final int hungerScore;
  final int physicalScore;
  final int moodScore;

  final String? notes;

  /// Copy with overrides. Re-runs the asserting constructor, so an
  /// out-of-range override fails just as a direct construction would.
  SymptomLog copyWith({
    int? id,
    DateTime? date,
    int? energyScore,
    int? clarityScore,
    int? hungerScore,
    int? physicalScore,
    int? moodScore,
    String? notes,
  }) => SymptomLog(
    id: id ?? this.id,
    date: date ?? this.date,
    energyScore: energyScore ?? this.energyScore,
    clarityScore: clarityScore ?? this.clarityScore,
    hungerScore: hungerScore ?? this.hungerScore,
    physicalScore: physicalScore ?? this.physicalScore,
    moodScore: moodScore ?? this.moodScore,
    notes: notes ?? this.notes,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SymptomLog &&
          other.id == id &&
          other.date == date &&
          other.energyScore == energyScore &&
          other.clarityScore == clarityScore &&
          other.hungerScore == hungerScore &&
          other.physicalScore == physicalScore &&
          other.moodScore == moodScore &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(
    id,
    date,
    energyScore,
    clarityScore,
    hungerScore,
    physicalScore,
    moodScore,
    notes,
  );
}
