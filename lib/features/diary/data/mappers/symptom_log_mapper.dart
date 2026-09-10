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
        date: DateTime.fromMillisecondsSinceEpoch(record['date']! as int),
        energyScore: record['energyScore']! as int,
        clarityScore: record['clarityScore']! as int,
        hungerScore: record['hungerScore']! as int,
        physicalScore: record['physicalScore']! as int,
        moodScore: record['moodScore']! as int,
        notes: record['notes'] as String?,
      );

  /// yyyyMMdd key for [date] — the record key itself, and the value
  /// `findAll` sorts on to return newest first.
  static int dateIndex(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;
}
