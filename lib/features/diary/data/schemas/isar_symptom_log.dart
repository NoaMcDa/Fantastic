import 'package:isar_community/isar.dart';

part 'isar_symptom_log.g.dart';

/// Isar persistence shape for `SymptomLog`, the diary's per-day subjective
/// record.
///
/// Mirrors every domain field — the domain model stays free of Isar
/// annotations, and `SymptomLogMapper` converts between the two. Field names
/// match the domain model exactly so a rename on either side fails to compile
/// rather than silently dropping data.
@collection
class IsarSymptomLog {
  Id id = Isar.autoIncrement;

  /// yyyyMMdd derived from [date]. Unique: exactly one symptom record exists
  /// per calendar day, enforced by the database rather than by convention, so
  /// a duplicating write fails loudly instead of leaving two rows for a day.
  @Index(unique: true)
  late int dateIndex;

  /// Kept alongside [dateIndex] so the domain date round-trips exactly —
  /// reconstructing it from the integer alone is lossy across time zones.
  late DateTime date;

  /// The five 1–5 scales. Stored as plain integers: Isar has no range
  /// constraint, and the domain constructor's asserts are compiled out in
  /// release, so nothing here relies on the range holding at rest. An
  /// out-of-range value that somehow reached disk surfaces on the way back
  /// out, when `SymptomLogMapper.toDomain` reconstructs through those asserts.
  late int energyScore;
  late int clarityScore;
  late int hungerScore;
  late int physicalScore;
  late int moodScore;

  /// Optional free-text note; null on most days.
  String? notes;
}
