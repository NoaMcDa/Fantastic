import 'package:fantastic/features/dashboard/data/schemas/isar_daily_log.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:isar_community/isar.dart';

/// Converts between [DailyLog] and its Isar persistence shape.
///
/// Called only by `IsarDailyLogRepository` (#40) — never from `domain/` or
/// `presentation/`, which must not see Isar types at all.
abstract final class DailyLogMapper {
  static IsarDailyLog toIsar(DailyLog log) => IsarDailyLog()
    ..id = log.id ?? Isar.autoIncrement
    ..dateIndex = dateIndex(log.date)
    ..date = log.date
    ..totalFatG = log.totalFatG
    ..totalNetCarbsG = log.totalNetCarbsG
    ..totalProteinG = log.totalProteinG
    ..waterMl = log.waterMl
    ..sodiumMg = log.sodiumMg
    ..potassiumMg = log.potassiumMg
    ..magnesiumMg = log.magnesiumMg
    ..ketoRatioAvg = log.ketoRatioAvg;

  static DailyLog toDomain(IsarDailyLog schema) => DailyLog(
    id: schema.id,
    date: schema.date,
    totalFatG: schema.totalFatG,
    totalNetCarbsG: schema.totalNetCarbsG,
    totalProteinG: schema.totalProteinG,
    waterMl: schema.waterMl,
    sodiumMg: schema.sodiumMg,
    potassiumMg: schema.potassiumMg,
    magnesiumMg: schema.magnesiumMg,
    ketoRatioAvg: schema.ketoRatioAvg,
  );

  /// yyyyMMdd key for [date].
  ///
  /// Public because `IsarDailyLogRepository` (#40) calls it to build its
  /// `findByDate` and `deleteByDate` queries — the repository needs the same
  /// encoding the schema was written with.
  static int dateIndex(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;
}
