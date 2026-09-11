import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';

/// Converts between [SymptomLog] and its sembast record shape.
///
/// Called only by `SembastSymptomLogRepository` — never from `domain/` or
/// `presentation/`, which must not see a persistence shape at all.
///
/// One record per calendar date, keyed on [dateIndex] exactly like
/// `DailyLogMapper`, so [SymptomLog.id] carries the yyyyMMdd key.
abstract final class SymptomLogMapper {
  static Map<String, Object?> toRecord(SymptomLog log) => {
    'date': log.date.millisecondsSinceEpoch,
    'energyScore': log.energyScore,
    'clarityScore': log.clarityScore,
    'hungerScore': log.hungerScore,
    'moodScore': log.moodScore,
    // A List, not a Set: sembast stores JSON-shaped values only. Sorted by
    // enum index so two logs with the same symptoms produce byte-identical
    // records — otherwise the stored order depends on Set iteration order and
    // a no-op save looks like a change.
    'symptoms':
        (log.symptoms.toList()..sort((a, b) => a.index.compareTo(b.index)))
            .map((s) => s.name)
            .toList(),
    'notes': log.notes,
  };

  /// Rebuilds the domain model through its asserting constructor, so a stored
  /// value outside the 1–5 range fails loudly in debug rather than
  /// propagating into the UI.
  static SymptomLog fromRecord(int key, Map<String, Object?> record) =>
      SymptomLog(
        id: key,
        // Every number through `num`, never a direct `as int`: `CLAUDE.md`
        // §Local Persistence. IndexedDB hands JSON numbers back without the
        // int/double distinction Dart's VM keeps, and a direct cast is one
        // stored `3.0` away from throwing on read — where a codec mistake
        // surfaces, since sembast validates nothing on write.
        date: DateTime.fromMillisecondsSinceEpoch(
          (record['date']! as num).toInt(),
        ),
        energyScore: (record['energyScore']! as num).toInt(),
        clarityScore: (record['clarityScore']! as num).toInt(),
        hungerScore: (record['hungerScore']! as num).toInt(),
        moodScore: (record['moodScore']! as num).toInt(),
        symptoms: _symptomsFrom(record['symptoms']),
        notes: record['notes'] as String?,
      );

  /// Rebuilds the symptom set from its stored `List<String>` of enum names.
  ///
  /// Tolerant on two axes, both of which are real:
  ///
  /// - **Key absent.** Every record written before the symptom picker shipped
  ///   has a `physicalScore` and no `symptoms`. Those days load as "logged,
  ///   felt nothing", which is the closest true statement available — the
  ///   user was never asked the question.
  /// - **Name unrecognised.** A record written by a newer build, or one whose
  ///   enum value was renamed against `design/web_support.md` §4's warning.
  ///   Dropping the unknown entry loses one symptom; throwing loses the whole
  ///   day, including its scores and note.
  ///
  /// Note the element cast goes through `Object?` and `toString()`, not
  /// `as String`: IndexedDB hands back a `List<dynamic>`, and a direct cast of
  /// the list itself throws even when every element is in fact a string.
  static Set<PhysicalSymptom> _symptomsFrom(Object? stored) {
    if (stored is! List) {
      return const <PhysicalSymptom>{};
    }
    final byName = {for (final s in PhysicalSymptom.values) s.name: s};
    return {for (final entry in stored) ?byName[entry.toString()]};
  }

  /// yyyyMMdd key for [date] — the record key itself, and the value
  /// `findAll` sorts on to return newest first.
  static int dateIndex(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;
}
