import 'package:fantastic/core/error/repository_exception.dart';
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
    await _recalculateDailyLog(entry.timestamp, evaluatedAt: DateTime.now());
    return saved;
  }

  /// Overwrites the stored meal with [entry] and updates every day the change
  /// touched. Returns the saved copy.
  ///
  /// A meal could be added and deleted but not changed, which was survivable
  /// while every macro in the diary was typed by hand and is conspicuous now
  /// that some are estimated: an estimate could be corrected before it was
  /// saved and not after. The only move left was to delete the entry and
  /// retype it, which loses the timestamp.
  ///
  /// **Two days, not one.** An edit may move a meal to a different calendar
  /// day, and the day it left has to lose the macros as surely as the day it
  /// joined has to gain them. The old date is read from the store *before*
  /// the overwrite, because afterwards there is nothing left to read it
  /// from — the same problem [deleteMeal] solves by taking the date as an
  /// argument, solved here by reading rather than by trusting the caller,
  /// since the caller holds an entry it has already modified.
  ///
  /// **Unlike [logMeal], the streak is evaluated at the wall clock.**
  /// `logMeal` passes the entry's own timestamp because a meal being logged
  /// *is* an event happening now; an edit is not, and its timestamp is
  /// whatever day the user is correcting. [deleteMeal] records what handing a
  /// date-only midnight to the state machine cost.
  ///
  /// Since #303 the streak is *derived* rather than accumulated, so editing a
  /// past meal is expected to change it: pushing a past day over the limit
  /// breaks the streak across that day, and correcting a day back under it
  /// repairs the streak across the gap. Nothing here suppresses that, and
  /// nothing should.
  ///
  /// Throws [ArgumentError] if `entry.id` is null.
  /// Throws [EntityNotFoundException] if no meal has that id.
  Future<MealEntry> updateMeal(MealEntry entry) async {
    final id = entry.id;
    if (id == null) {
      // Not a formality. `save` is an upsert keyed on the id, so a null one
      // would **append a second meal** rather than overwrite the first, and
      // the day's macros would silently double.
      throw ArgumentError.notNull('entry.id');
    }

    final existing = await mealRepository.findById(id);
    if (existing == null) {
      throw EntityNotFoundException('No meal with id $id');
    }

    final saved = await mealRepository.save(entry);

    // One wall-clock instant for both recalculations, not two `DateTime.now()`
    // calls: the second would be a few milliseconds later, and a write that
    // straddled midnight would evaluate the two days against different days.
    final evaluatedAt = DateTime.now();
    await _recalculateDailyLog(entry.timestamp, evaluatedAt: evaluatedAt);
    if (!_isSameDay(existing.timestamp, entry.timestamp)) {
      await _recalculateDailyLog(existing.timestamp, evaluatedAt: evaluatedAt);
    }

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
  /// tomorrow: two hours to recover instead of twenty-four.
  Future<void> deleteMeal(int id, DateTime date) async {
    await mealRepository.delete(id);
    await _recalculateDailyLog(date, evaluatedAt: DateTime.now());
  }

  /// Whether two instants fall on the same calendar day.
  ///
  /// By year/month/day, never `==` on `DateTime`: two meals on the same day
  /// at different times are not equal instants, and comparing instants would
  /// recalculate the old day on every single edit — harmless in effect and
  /// wrong in intent, which is the kind of thing that stops being harmless
  /// the moment someone optimises it.
  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

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

    // Re-derive the streak from the day history, which [date]'s totals have
    // just changed. Every write path reaches this, including one that edits or
    // empties a day long past — which is the whole point (#303).
    //
    // [date] says which day moved; [evaluatedAt] says when the evaluation is
    // happening, and it is always the wall clock. `logMeal` used to pass the
    // meal's own timestamp, which is the same instant for a meal logged now
    // and badly wrong for a back-dated one: the derivation walks back from
    // the instant it is given, so a meal dated two days ago started the walk
    // two days ago and today stopped counting toward the streak. The e2e
    // back-fill flow caught it.
    await adaptationPhaseService.recomputeFor(date, at: evaluatedAt);
  }
}

@riverpod
MealLoggingService mealLoggingService(Ref ref) => MealLoggingService(
  mealRepository: ref.watch(mealRepositoryProvider),
  dailyLogRepository: ref.watch(dailyLogRepositoryProvider),
  ketoRatioCalculator: ref.watch(ketoRatioCalculatorProvider),
  adaptationPhaseService: ref.watch(adaptationPhaseServiceProvider),
);
