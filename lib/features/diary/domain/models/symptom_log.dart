import 'package:collection/collection.dart';
import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:meta/meta.dart';

/// The user's daily subjective experience across four 1–5 scales and a set of
/// physical symptoms, plus an optional free-text note. One record per calendar
/// day.
///
/// Physical symptoms are a set rather than a fifth scale: a single number said
/// the user felt bad without saying what they felt, which is the one thing that
/// would have made the field actionable.
///
/// Validating the scores here rather than in the UI means no invalid record
/// can reach persistence regardless of which path created it. Note that
/// `assert` is compiled out in release builds — deliberate, since the scores
/// come from a fixed 1–5 picker — so the data layer does not rely on these
/// holding at runtime. [symptoms] needs no such check: [PhysicalSymptom] is a
/// closed enum, so an out-of-range value is not constructible.
///
/// Pure domain: no Flutter, no persistence package, no Riverpod.
@immutable
class SymptomLog {
  const SymptomLog({
    required this.date,
    required this.energyScore,
    required this.clarityScore,
    required this.hungerScore,
    required this.moodScore,
    this.symptoms = const <PhysicalSymptom>{},
    this.id,
    this.notes,
  }) : assert(energyScore >= 1 && energyScore <= 5, 'energyScore must be 1-5'),
       assert(
         clarityScore >= 1 && clarityScore <= 5,
         'clarityScore must be 1-5',
       ),
       assert(hungerScore >= 1 && hungerScore <= 5, 'hungerScore must be 1-5'),
       assert(moodScore >= 1 && moodScore <= 5, 'moodScore must be 1-5');

  /// Set equality, not identity.
  ///
  /// `Set` inherits `==` from `Object`, so two logs holding equal symptom sets
  /// would compare unequal. [hashCode] must use the matching [SetEquality.hash]
  /// or two equal logs land in different buckets.
  static const SetEquality<PhysicalSymptom> _symptomEquality =
      SetEquality<PhysicalSymptom>();

  /// Null until first persisted. Carries the record's yyyyMMdd key once it
  /// is — see `SymptomLogMapper`.
  final int? id;

  /// Calendar day this log covers — one record per day.
  final DateTime date;

  final int energyScore;
  final int clarityScore;
  final int hungerScore;
  final int moodScore;

  /// The somatic symptoms the user marked for this day.
  ///
  /// Empty means "logged, and felt none of them" — not "not logged". A day with
  /// nothing logged has no [SymptomLog] record at all, so the two states are
  /// already distinguishable without a null.
  final Set<PhysicalSymptom> symptoms;

  final String? notes;

  /// Copy with overrides. Re-runs the asserting constructor, so an
  /// out-of-range override fails just as a direct construction would.
  ///
  /// [clearNotes] exists because `notes ?? this.notes` cannot express "set
  /// this back to null" — the trap `StreakState.copyWith` and
  /// `UserProfile.copyWith` both carry an explicit flag for
  /// (`design/m3_preflight.md` §1.1). Nothing needs it yet: the sheet builds
  /// a fresh log through `buildSymptomLog`, so an emptied note already
  /// stores as null. It is here so the first caller that does need it is not
  /// the one that discovers the silent no-op.
  ///
  /// [symptoms] needs no matching flag, and one should not be added for
  /// symmetry: "no symptoms" is expressible directly as `symptoms: const {}`,
  /// so the null-versus-absent ambiguity that forced [clearNotes] does not
  /// arise here.
  SymptomLog copyWith({
    int? id,
    DateTime? date,
    int? energyScore,
    int? clarityScore,
    int? hungerScore,
    int? moodScore,
    Set<PhysicalSymptom>? symptoms,
    String? notes,
    bool clearNotes = false,
  }) => SymptomLog(
    id: id ?? this.id,
    date: date ?? this.date,
    energyScore: energyScore ?? this.energyScore,
    clarityScore: clarityScore ?? this.clarityScore,
    hungerScore: hungerScore ?? this.hungerScore,
    moodScore: moodScore ?? this.moodScore,
    symptoms: symptoms ?? this.symptoms,
    notes: clearNotes ? null : notes ?? this.notes,
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
          other.moodScore == moodScore &&
          _symptomEquality.equals(other.symptoms, symptoms) &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(
    id,
    date,
    energyScore,
    clarityScore,
    hungerScore,
    moodScore,
    _symptomEquality.hash(symptoms),
    notes,
  );
}
