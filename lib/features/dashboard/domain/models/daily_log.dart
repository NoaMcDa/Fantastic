import 'package:meta/meta.dart';

/// The per-day aggregate the dashboard reads: total macros, water, the three
/// electrolytes, and the day's average keto ratio.
///
/// Upserted after every meal log, so exactly one record exists per calendar
/// date. Belongs to the dashboard rather than the diary — the diary owns
/// individual meals, the dashboard owns the roll-up.
///
/// Pure domain: no Flutter, no persistence package, no Riverpod.
@immutable
class DailyLog {
  const DailyLog({
    required this.date,
    this.id,
    this.totalFatG = 0,
    this.totalNetCarbsG = 0,
    this.totalProteinG = 0,
    this.waterMl = 0,
    this.sodiumMg = 0,
    this.potassiumMg = 0,
    this.magnesiumMg = 0,
    this.ketoRatioAvg = 0,
    this.trainingDay = false,
  });

  /// Null until first persisted. Carries the record's yyyyMMdd key once it
  /// is — see `DailyLogMapper`.
  final int? id;

  /// Calendar day this log aggregates. The time component is not meaningful —
  /// `DailyLogMapper.dateIndex` derives the yyyyMMdd record key from it.
  final DateTime date;

  final double totalFatG;
  final double totalNetCarbsG;
  final double totalProteinG;
  final double waterMl;
  final double sodiumMg;
  final double potassiumMg;
  final double magnesiumMg;

  /// Mean keto ratio across the day's meals.
  ///
  /// Stored rather than computed, unlike [MealEntry.ketoRatio]: the meals it
  /// averages are not loaded when the dashboard reads the day.
  final double ketoRatioAvg;

  /// Whether the user marked this day as one they trained on.
  ///
  /// Set from the dashboard's own chip, never inferred: the app has no
  /// activity sensor and guessing would be a claim it cannot support.
  /// `DailyTargetsService.forDay` reads it to raise the day's **fat** target
  /// by the energy one tier of activity is worth; net carbs and protein are
  /// untouched, because on keto the extra energy is fat.
  ///
  /// **Flagging a day does not log it.** Every macro total stays whatever it
  /// was, so a flagged day with no meals is still all-zero — which
  /// `AdaptationPhaseService` reads as *unlogged*, exactly as it did before.
  /// A day cannot be banked toward a streak by saying you went to the gym.
  ///
  /// False for every record written before this field existed.
  final bool trainingDay;

  DailyLog copyWith({
    int? id,
    DateTime? date,
    double? totalFatG,
    double? totalNetCarbsG,
    double? totalProteinG,
    double? waterMl,
    double? sodiumMg,
    double? potassiumMg,
    double? magnesiumMg,
    double? ketoRatioAvg,
    bool? trainingDay,
  }) => DailyLog(
    id: id ?? this.id,
    date: date ?? this.date,
    totalFatG: totalFatG ?? this.totalFatG,
    totalNetCarbsG: totalNetCarbsG ?? this.totalNetCarbsG,
    totalProteinG: totalProteinG ?? this.totalProteinG,
    waterMl: waterMl ?? this.waterMl,
    sodiumMg: sodiumMg ?? this.sodiumMg,
    potassiumMg: potassiumMg ?? this.potassiumMg,
    magnesiumMg: magnesiumMg ?? this.magnesiumMg,
    ketoRatioAvg: ketoRatioAvg ?? this.ketoRatioAvg,
    trainingDay: trainingDay ?? this.trainingDay,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyLog &&
          other.id == id &&
          other.date == date &&
          other.totalFatG == totalFatG &&
          other.totalNetCarbsG == totalNetCarbsG &&
          other.totalProteinG == totalProteinG &&
          other.waterMl == waterMl &&
          other.sodiumMg == sodiumMg &&
          other.potassiumMg == potassiumMg &&
          other.magnesiumMg == magnesiumMg &&
          other.ketoRatioAvg == ketoRatioAvg &&
          other.trainingDay == trainingDay;

  @override
  int get hashCode => Object.hash(
    id,
    date,
    totalFatG,
    totalNetCarbsG,
    totalProteinG,
    waterMl,
    sodiumMg,
    potassiumMg,
    magnesiumMg,
    ketoRatioAvg,
    trainingDay,
  );
}
