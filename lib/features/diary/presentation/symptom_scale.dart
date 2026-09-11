import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:flutter/material.dart';

/// The four 1–5 scales a [SymptomLog] records, with the copy and iconography
/// the diary draws them with.
///
/// **One place knows the scales.** The M5 issue text described a scale as
/// "brain fog" in three widgets and named a `brainFogScore` field the model has
/// never had (`design/m5_preflight.md` §1.1). That mistake is only possible
/// where each widget keeps its own hand-written list, so the strip, the sheet
/// and the diary section all iterate this enum instead. Adding a scale is a
/// change here and nowhere else.
///
/// There is no `physical` value. Physical symptoms are recorded as a
/// [PhysicalSymptom] set on the log, not as a score — do not "restore" a fifth
/// value here.
///
/// Presentation, not `core/constants/`, because of [icon]: `PhaseCopy` is
/// pure copy and stays Flutter-free, and an `IconData` cannot follow it there.
///
/// Labels come from `design/ui_ux_design.md` §Symptoms Section.
enum SymptomScale {
  energy(label: 'אנרגיה', shortLabel: 'אנרגיה', icon: Icons.bolt_outlined),
  clarity(label: 'ריכוז', shortLabel: 'ריכוז', icon: Icons.psychology_outlined),
  hunger(label: 'רעב', shortLabel: 'רעב', icon: Icons.restaurant_outlined),
  mood(label: 'מצב רוח', shortLabel: 'מצב רוח', icon: Icons.mood_outlined);

  const SymptomScale({
    required this.label,
    required this.shortLabel,
    required this.icon,
  });

  /// Full label — the sheet's rows and the diary's chips.
  final String label;

  /// Label for the dashboard strip, where five cells share the screen width.
  ///
  /// Spelled out per value rather than defaulted, so shortening a label is a
  /// deliberate edit in one table instead of a silent fallback.
  final String shortLabel;

  final IconData icon;

  /// This scale's score in [log].
  ///
  /// The single read path. A widget that reached for `log.energyScore`
  /// directly while labelling the cell "mood" is the defect this enum exists
  /// to make unwriteable.
  int scoreIn(SymptomLog log) => switch (this) {
    SymptomScale.energy => log.energyScore,
    SymptomScale.clarity => log.clarityScore,
    SymptomScale.hunger => log.hungerScore,
    SymptomScale.mood => log.moodScore,
  };
}

/// Builds a [SymptomLog] for [date] out of a score per [SymptomScale].
///
/// The mirror of [SymptomScale.scoreIn], and the only write path — so the
/// two directions cannot disagree about which field is which.
///
/// [id], [notes] and [symptoms] are carried through from the record being
/// edited. Dropping them is not cosmetic: `SymptomLogRepository.save` upserts
/// on the date, so a save built without the stored note **erases it**
/// (`design/m5_preflight.md` §1.3) — and a save built without the stored
/// symptom set erases that the same way.
///
/// [date] is normalised to midnight: the record key ignores the time
/// component, so storing a wall-clock time would make two logically identical
/// days compare unequal.
SymptomLog buildSymptomLog({
  required DateTime date,
  required Map<SymptomScale, int> scores,
  Set<PhysicalSymptom> symptoms = const <PhysicalSymptom>{},
  int? id,
  String? notes,
}) => SymptomLog(
  id: id,
  date: DateTime(date.year, date.month, date.day),
  energyScore: scores[SymptomScale.energy]!,
  clarityScore: scores[SymptomScale.clarity]!,
  hungerScore: scores[SymptomScale.hunger]!,
  moodScore: scores[SymptomScale.mood]!,
  symptoms: symptoms,
  notes: notes,
);
