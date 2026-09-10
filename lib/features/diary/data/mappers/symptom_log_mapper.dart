import 'package:fantastic/features/diary/data/schemas/isar_symptom_log.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:isar_community/isar.dart';

/// Converts between [SymptomLog] and its Isar persistence shape.
///
/// Called only by `IsarSymptomLogRepository` (#42) — never from `domain/` or
/// `presentation/`, which must not see Isar types at all.
abstract final class SymptomLogMapper {
  static IsarSymptomLog toIsar(SymptomLog log) => IsarSymptomLog()
    ..id = log.id ?? Isar.autoIncrement
    ..dateIndex = dateIndex(log.date)
    ..date = log.date
    ..energyScore = log.energyScore
    ..clarityScore = log.clarityScore
    ..hungerScore = log.hungerScore
    ..physicalScore = log.physicalScore
    ..moodScore = log.moodScore
    ..notes = log.notes;

  /// Rebuilds the domain model through its asserting constructor, so a stored
  /// value outside the 1–5 range fails loudly in debug rather than
  /// propagating into the UI.
  static SymptomLog toDomain(IsarSymptomLog schema) => SymptomLog(
    id: schema.id,
    date: schema.date,
    energyScore: schema.energyScore,
    clarityScore: schema.clarityScore,
    hungerScore: schema.hungerScore,
    physicalScore: schema.physicalScore,
    moodScore: schema.moodScore,
    notes: schema.notes,
  );

  /// yyyyMMdd key for [date].
  ///
  /// Public because `IsarSymptomLogRepository` (#42) calls it to build its
  /// `findByDate` and `deleteByDate` queries — the repository needs the same
  /// encoding the schema was written with.
  static int dateIndex(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;
}
