import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';

/// Test data for [DailyLog].
///
/// Defaults describe a compliant keto day and are deterministic — the date is
/// fixed, not `DateTime.now()`.
abstract final class DailyLogFixture {
  /// The fixed date every fixture uses unless overridden.
  static final DateTime defaultDate = DateTime(2026, 9, 9);

  /// A compliant day: 120g fat / 18g net carbs / 90g protein averages a keto
  /// ratio of about 1.1, with electrolytes inside the Phase 1 targets in
  /// `lib/core/constants/electrolyte_constants.dart`.
  static DailyLog fixture({
    int? id,
    DateTime? date,
    double totalFatG = 120,
    double totalNetCarbsG = 18,
    double totalProteinG = 90,
    double waterMl = 2000,
    double sodiumMg = 3500,
    double potassiumMg = 3000,
    double magnesiumMg = 350,
    double ketoRatioAvg = 1.1,
  }) => DailyLog(
    id: id,
    date: date ?? defaultDate,
    totalFatG: totalFatG,
    totalNetCarbsG: totalNetCarbsG,
    totalProteinG: totalProteinG,
    waterMl: waterMl,
    sodiumMg: sodiumMg,
    potassiumMg: potassiumMg,
    magnesiumMg: magnesiumMg,
    ketoRatioAvg: ketoRatioAvg,
  );

  /// A day with nothing logged — every total at zero.
  static DailyLog empty({int? id, DateTime? date}) =>
      DailyLog(id: id, date: date ?? defaultDate);
}
