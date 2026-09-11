import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:flutter/material.dart';

/// The Hebrew label and icon for each [PhysicalSymptom].
///
/// One table, for the reason `SymptomScale` is one table: three widgets render
/// these chips, and three hand-written lists is three chances to label the
/// wrong symptom. Iterate `PhysicalSymptom.values` and look up here — never
/// hardcode a Hebrew symptom string in a widget.
///
/// Lives in `presentation/` because of [icon]; the enum itself is domain,
/// because it is persisted. `PhaseCopy` is pure copy and stays Flutter-free in
/// `lib/core/constants/`, and an `IconData` cannot follow it there.
///
/// Both getters switch exhaustively rather than reading a map: a map with a
/// missing key compiles and fails at run time, a non-exhaustive switch over an
/// enum does not compile.
extension PhysicalSymptomCopy on PhysicalSymptom {
  String get label => switch (this) {
    PhysicalSymptom.halitosis => 'ריח פה',
    PhysicalSymptom.constipation => 'עצירות',
    PhysicalSymptom.muscleCramps => 'התכווצויות שרירים',
    PhysicalSymptom.headache => 'כאב ראש',
    PhysicalSymptom.diarrhea => 'שלשול',
    PhysicalSymptom.dizziness => 'סחרחורת',
    PhysicalSymptom.nausea => 'בחילה',
    PhysicalSymptom.insomnia => 'נדודי שינה',
  };

  IconData get icon => switch (this) {
    PhysicalSymptom.halitosis => Icons.air,
    PhysicalSymptom.constipation => Icons.hourglass_empty,
    PhysicalSymptom.muscleCramps => Icons.fitness_center,
    PhysicalSymptom.headache => Icons.sick_outlined,
    PhysicalSymptom.diarrhea => Icons.water_drop_outlined,
    PhysicalSymptom.dizziness => Icons.blur_on,
    PhysicalSymptom.nausea => Icons.sentiment_dissatisfied_outlined,
    PhysicalSymptom.insomnia => Icons.bedtime_off_outlined,
  };
}
