import 'package:isar_community/isar.dart';

part 'isar_daily_log.g.dart';

/// Isar persistence shape for `DailyLog`, the dashboard's per-day aggregate.
///
/// Mirrors every domain field — the domain model stays free of Isar
/// annotations, and `DailyLogMapper` converts between the two. Field names
/// match the domain model exactly so a rename on either side fails to compile
/// rather than silently dropping data.
@collection
class IsarDailyLog {
  Id id = Isar.autoIncrement;

  /// yyyyMMdd derived from [date]. Unique: exactly one aggregate row exists
  /// per calendar day, enforced by the database rather than by convention, so
  /// a duplicating write fails loudly instead of leaving two rows for a day.
  @Index(unique: true)
  late int dateIndex;

  /// Kept alongside [dateIndex] so the domain date round-trips exactly —
  /// reconstructing it from the integer alone is lossy across time zones.
  late DateTime date;

  late double totalFatG;
  late double totalNetCarbsG;
  late double totalProteinG;
  late double waterMl;
  late double sodiumMg;
  late double potassiumMg;
  late double magnesiumMg;

  /// Mean keto ratio across the day's meals. Persisted, not derived: the meals
  /// it averages are not loaded when the dashboard reads the day.
  late double ketoRatioAvg;
}
