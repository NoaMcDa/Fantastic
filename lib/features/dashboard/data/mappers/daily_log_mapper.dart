import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';

/// Converts between [DailyLog] and its sembast record shape.
///
/// Called only by `SembastDailyLogRepository` — never from `domain/` or
/// `presentation/`, which must not see a persistence shape at all.
///
/// One record per calendar date, and the record's **key is [dateIndex]**, not
/// an autoincrementing id. That is what makes `save` a natural upsert: writing
/// the same date twice addresses the same key. [DailyLog.id] therefore carries
/// the yyyyMMdd key, which is stable across writes.
abstract final class DailyLogMapper {
  static Map<String, Object?> toRecord(DailyLog log) => {
    'date': log.date.millisecondsSinceEpoch,
    'totalFatG': log.totalFatG,
    'totalNetCarbsG': log.totalNetCarbsG,
    'totalProteinG': log.totalProteinG,
    'waterMl': log.waterMl,
    'sodiumMg': log.sodiumMg,
    'potassiumMg': log.potassiumMg,
    'magnesiumMg': log.magnesiumMg,
    'ketoRatioAvg': log.ketoRatioAvg,
  };

  static DailyLog fromRecord(int key, Map<String, Object?> record) => DailyLog(
    id: key,
    date: DateTime.fromMillisecondsSinceEpoch(record['date']! as int),
    // `as num` then `.toDouble()`, never `as double`: a whole number written
    // as 40.0 comes back from IndexedDB's JSON as an int.
    totalFatG: (record['totalFatG']! as num).toDouble(),
    totalNetCarbsG: (record['totalNetCarbsG']! as num).toDouble(),
    totalProteinG: (record['totalProteinG']! as num).toDouble(),
    waterMl: (record['waterMl']! as num).toDouble(),
    sodiumMg: (record['sodiumMg']! as num).toDouble(),
    potassiumMg: (record['potassiumMg']! as num).toDouble(),
    magnesiumMg: (record['magnesiumMg']! as num).toDouble(),
    ketoRatioAvg: (record['ketoRatioAvg']! as num).toDouble(),
  );

  /// yyyyMMdd key for [date] — the record key itself, and the value
  /// `findAll` sorts on to return newest first.
  static int dateIndex(DateTime date) =>
      date.year * 10000 + date.month * 100 + date.day;
}
