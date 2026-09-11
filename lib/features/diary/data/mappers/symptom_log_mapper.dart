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
    'physicalScore': log.physicalScore,
    'moodScore': log.moodScore,
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
        physicalScore: (record['physicalScore']! as num).toInt(),
        moodScore: (record['moodScore']! as num).toInt(),
        notes: record['notes'] as String?,
      );

  /// yyyyMMdd key for [date] — the record key itself, and the value
  /// `findAll` sorts on to return newest first.
  static int dateIndex(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;
}
