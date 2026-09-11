import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/features/adaptation/application/adaptation_phase_service.dart';
import 'package:fantastic/features/dashboard/application/keto_ratio_calculator.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/domain/repositories/meal_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'meal_logging_service.g.dart';

/// Orchestrates the app's main write path: persisting a meal and rolling the
/// day's totals up into its [DailyLog].
///
/// Talks only to the repository interfaces — never to the store. `DailyLog`
/// belongs
/// to the dashboard feature even though meals belong to the diary, so this
/// service deliberately spans both: the diary owns the individual meals, the
/// dashboard owns the aggregate they roll into.
class MealLoggingService {
  const MealLoggingService({
    required this.mealRepository,
    required this.dailyLogRepository,
    required this.ketoRatioCalculator,
    required this.adaptationPhaseService,
  });

  // Public rather than private: Dart forbids a named parameter whose name
  // starts with an underscore, so the issue's `required MealRepository
  // mealRepository` + `_mealRepository` field pairing cannot use an
  // initializing formal and trips `prefer_initializing_formals`. Injected
  // collaborators being visible on the service is harmless — they are
  // interfaces, and the tests already hold them.
  final MealRepository mealRepository;
  final DailyLogRepository dailyLogRepository;
  final KetoRatioCalculator ketoRatioCalculator;
  final AdaptationPhaseService adaptationPhaseService;

  /// Persists [entry] and updates its day's totals. Returns the saved copy,
  /// which carries the assigned id.
  ///
  /// The recalculation reads the day back from the repository rather than
  /// adding [entry]'s macros to the stored totals. Slower, but it cannot drift:
  /// an incremental update that ran twice, or missed an edit, would leave the
  /// totals permanently wrong with nothing to detect it.
  Future<MealEntry> logMeal(MealEntry entry) async {
    final saved = await mealRepository.save(entry);
    await _recalculateDailyLog(entry.timestamp, evaluatedAt: entry.timestamp);
    return saved;
  }

  /// Deletes the meal with [id] and updates [date]'s totals.
  ///
  /// [date] is passed in because the entry is gone by the time the totals are
  /// recomputed — there is nothing left to read a timestamp from.
  ///
  /// **The streak is evaluated at the wall clock, not at [date].** Callers
  /// pass a date-only value here — the diary holds its selected date stripped
  /// to midnight — and handing that to the state machine dated the breach to
  /// 00:00, so a deletion at 22:00 opened a grace period expiring at midnight
  /// tomorrow: two hours to recover instead of twenty-four. `logMeal` has a
  /// real instant of its own and keeps using it.
  Future<void> deleteMeal(int id, DateTime date) async {
    await mealRepository.delete(id);
    await _recalculateDailyLog(date, evaluatedAt: DateTime.now());
  }

  Future<void> _recalculateDailyLog(
    DateTime date, {
    required DateTime evaluatedAt,
  }) async {
    final meals = await mealRepository.findByDate(date);
    final existing = await dailyLogRepository.findByDate(date);

    final totalFatG = meals.fold<double>(0, (sum, m) => sum + m.fatG);
    final totalNetCarbsG = meals.fold<double>(0, (sum, m) => sum + m.netCarbsG);
    final totalProteinG = meals.fold<double>(0, (sum, m) => sum + m.proteinG);

    // `copyWith` on the existing log rather than a fresh one: water and the
    // three electrolytes are logged by a separate flow, and rebuilding from
    // scratch would silently reset them every time a meal is saved.
    final updated = (existing ?? DailyLog(date: date)).copyWith(
      totalFatG: totalFatG,
      totalNetCarbsG: totalNetCarbsG,
      totalProteinG: totalProteinG,
      // The ratio of the day's totals, not the mean of each meal's ratio.
      // Those differ, and the mean is the wrong one: it weights a 20g snack
      // the same as a 600g dinner, and our zero-denominator convention would
      // drag it toward zero for every carb-free, protein-free item.
      ketoRatioAvg: ketoRatioCalculator.calculate(
        fat: totalFatG,
        netCarbs: totalNetCarbsG,
        protein: totalProteinG,
      ),
    );

    await dailyLogRepository.save(updated);
    await _evaluateStreak(date, updated, evaluatedAt);
  }

  /// Feeds the day's ratio to the adaptation state machine.
  ///
  /// A proxy for end-of-day compliance, as #58 describes: there is no
  /// background job yet, so the streak is re-evaluated every time the day's
  /// totals move. [AdaptationPhaseService.recordCompliantDay] is idempotent
  /// per day, which is what makes a per-meal trigger safe.
  ///
  /// Two days are deliberately left alone:
  ///
  /// - **Any day but today.** Backdating a diary entry must not rewrite
  ///   streak history, and it cannot: the state machine holds one current
  ///   streak, not a per-day ledger.
  /// - **A day with no carbs and no protein logged.** The ratio is
  ///   `fat / (netCarbs + protein)`, and [KetoRatioCalculator] returns `0`
  ///   for a zero denominator — "nothing to divide by", not "a bad day".
  ///   Treating that 0 as a breach would open a grace period on the most
  ///   ordinary keto morning there is, a coffee with butter and nothing
  ///   else. See `design/m3_preflight.md` §1.3.
  ///
  /// [evaluatedAt] is the instant the state machine reasons from: it decides
  /// the grace-period window, which [date] alone cannot once [date] has been
  /// stripped to midnight.
  Future<void> _evaluateStreak(
    DateTime date,
    DailyLog log,
    DateTime evaluatedAt,
  ) async {
    if (!_isToday(date)) {
      return;
    }
    if (log.totalNetCarbsG + log.totalProteinG == 0) {
      return;
    }

    // The ratio the log already carries, not a second calculation — the two
    // could otherwise drift and the streak would disagree with the dashboard.
    await adaptationPhaseService.evaluateToday(
      evaluatedAt,
      compliant: log.ketoRatioAvg >= KetoConstants.targetKetoRatioIdeal,
    );
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

@riverpod
MealLoggingService mealLoggingService(Ref ref) => MealLoggingService(
  mealRepository: ref.watch(mealRepositoryProvider),
  dailyLogRepository: ref.watch(dailyLogRepositoryProvider),
  ketoRatioCalculator: ref.watch(ketoRatioCalculatorProvider),
  adaptationPhaseService: ref.watch(adaptationPhaseServiceProvider),
);
