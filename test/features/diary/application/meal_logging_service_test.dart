import 'package:fantastic/features/adaptation/application/adaptation_phase_service.dart';
import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:fantastic/features/dashboard/application/keto_ratio_calculator.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:fantastic/features/diary/application/meal_logging_service.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/repositories/meal_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixtures.dart';

class _MockMealRepository extends Mock implements MealRepository {}

class _MockDailyLogRepository extends Mock implements DailyLogRepository {}

class _MockAdaptationPhaseService extends Mock
    implements AdaptationPhaseService {}

class _MockStreakRepository extends Mock implements StreakRepository {}

void main() {
  late _MockMealRepository mealRepository;
  late _MockDailyLogRepository dailyLogRepository;
  late _MockAdaptationPhaseService adaptationPhaseService;
  late _MockStreakRepository streakRepository;
  late MealLoggingService service;

  final date = MealEntryFixture.defaultTimestamp;

  setUpAll(() {
    registerFallbackValue(MealEntryFixture.fixture());
    registerFallbackValue(DailyLogFixture.fixture());
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const StreakState());
  });

  setUp(() {
    mealRepository = _MockMealRepository();
    dailyLogRepository = _MockDailyLogRepository();
    adaptationPhaseService = _MockAdaptationPhaseService();
    streakRepository = _MockStreakRepository();
    when(streakRepository.load).thenAnswer((_) async => null);
    when(() => streakRepository.save(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as StreakState,
    );
    service = MealLoggingService(
      mealRepository: mealRepository,
      dailyLogRepository: dailyLogRepository,
      ketoRatioCalculator: const KetoRatioCalculator(),
      adaptationPhaseService: adaptationPhaseService,
    );

    // Default: the save echoes back what it was given, the day holds just that
    // meal, and no log exists yet. Individual tests override what they need.
    when(() => mealRepository.save(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as MealEntry,
    );
    when(() => mealRepository.delete(any())).thenAnswer((_) async {});
    when(() => mealRepository.findByDate(any())).thenAnswer((_) async => []);
    when(() => dailyLogRepository.findByDate(any())).thenAnswer((_) async {
      return null;
    });
    when(() => dailyLogRepository.save(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as DailyLog,
    );
    when(
      () => adaptationPhaseService.evaluateToday(
        any(),
        compliant: any(named: 'compliant'),
      ),
    ).thenAnswer((_) async => const StreakState());
  });

  /// The `DailyLog` handed to `dailyLogRepository.save`.
  DailyLog capturedLog() =>
      verify(() => dailyLogRepository.save(captureAny())).captured.single
          as DailyLog;

  group('logMeal', () {
    test('saves the meal', () async {
      final entry = MealEntryFixture.fixture();

      await service.logMeal(entry);

      verify(() => mealRepository.save(entry)).called(1);
    });

    test('returns the repository copy, carrying its assigned id', () async {
      final persisted = MealEntryFixture.fixture(id: 7);
      when(() => mealRepository.save(any())).thenAnswer((_) async => persisted);

      final result = await service.logMeal(MealEntryFixture.fixture());

      expect(result.id, 7);
      expect(result, persisted);
    });

    test('recalculates the day after saving, not before', () async {
      // Reading the day before the save would miss the meal just logged.
      await service.logMeal(MealEntryFixture.fixture());

      verifyInOrder([
        () => mealRepository.save(any()),
        () => mealRepository.findByDate(any()),
        () => dailyLogRepository.save(any()),
      ]);
    });

    test('recalculates the day the meal was logged on', () async {
      final entry = MealEntryFixture.fixture(
        timestamp: DateTime(2026, 9, 11, 19),
      );

      await service.logMeal(entry);

      verify(() => mealRepository.findByDate(entry.timestamp)).called(1);
    });

    test('sums the macros of every meal on the day', () async {
      when(() => mealRepository.findByDate(any())).thenAnswer(
        (_) async => [
          MealEntryFixture.fixture(fatG: 10, netCarbsG: 2, proteinG: 5),
          MealEntryFixture.fixture(fatG: 30, netCarbsG: 3, proteinG: 15),
        ],
      );

      await service.logMeal(MealEntryFixture.fixture());

      final saved = capturedLog();
      expect(saved.totalFatG, 40);
      expect(saved.totalNetCarbsG, 5);
      expect(saved.totalProteinG, 20);
    });

    test(
      'totals are recomputed from the day, not added incrementally',
      () async {
        // The stored log is deliberately wrong. A service that added the new
        // meal's macros to it would keep the error; recomputing discards it.
        when(() => dailyLogRepository.findByDate(any()))
            .thenAnswer((_) async => DailyLogFixture.fixture(totalFatG: 9999));
        when(() => mealRepository.findByDate(any()))
            .thenAnswer((_) async => [MealEntryFixture.fixture(fatG: 10)]);

        await service.logMeal(MealEntryFixture.fixture());

        expect(capturedLog().totalFatG, 10);
      },
    );

    test('stores the keto ratio of the day totals', () async {
      when(() => mealRepository.findByDate(any())).thenAnswer(
        (_) async => [
          MealEntryFixture.fixture(fatG: 100, netCarbsG: 5, proteinG: 20),
        ],
      );

      await service.logMeal(MealEntryFixture.fixture());

      expect(capturedLog().ketoRatioAvg, closeTo(4, 0.01));
    });

    // The ratio of totals, not the mean of each meal's ratio. Two meals at
    // 2.0 and 0.0 average 1.0, but their combined macros give 20/(5+5) = 2.0.
    test('the ratio is of the totals, not a mean of per-meal ratios', () async {
      when(() => mealRepository.findByDate(any())).thenAnswer(
        (_) async => [
          MealEntryFixture.fixture(fatG: 20, netCarbsG: 5, proteinG: 5),
          MealEntryFixture.fixture(fatG: 0, netCarbsG: 0, proteinG: 0),
        ],
      );

      await service.logMeal(MealEntryFixture.fixture());

      expect(capturedLog().ketoRatioAvg, closeTo(2, 0.01));
    });

    test('upserts the recalculated log', () async {
      await service.logMeal(MealEntryFixture.fixture());

      verify(() => dailyLogRepository.save(any())).called(1);
    });
  });

  group('_recalculateDailyLog when no log exists yet', () {
    test('creates one for that date with the computed totals', () async {
      when(() => mealRepository.findByDate(any()))
          .thenAnswer((_) async => [MealEntryFixture.fixture(fatG: 12)]);

      await service.logMeal(MealEntryFixture.fixture(timestamp: date));

      final saved = capturedLog();
      expect(saved.date, date);
      expect(saved.totalFatG, 12);
    });

    test('leaves water and electrolytes at their zero defaults', () async {
      await service.logMeal(MealEntryFixture.fixture());

      final saved = capturedLog();
      expect(saved.waterMl, 0);
      expect(saved.sodiumMg, 0);
      expect(saved.potassiumMg, 0);
      expect(saved.magnesiumMg, 0);
    });
  });

  group('_recalculateDailyLog when a log already exists', () {
    // Water and electrolytes come from a separate logging flow. Rebuilding the
    // log from scratch on every meal would silently wipe them.
    test('preserves water and the three electrolytes', () async {
      when(() => dailyLogRepository.findByDate(any())).thenAnswer(
        (_) async => DailyLogFixture.fixture(
          waterMl: 1500,
          sodiumMg: 3200,
          potassiumMg: 2800,
          magnesiumMg: 320,
        ),
      );

      await service.logMeal(MealEntryFixture.fixture());

      final saved = capturedLog();
      expect(saved.waterMl, 1500);
      expect(saved.sodiumMg, 3200);
      expect(saved.potassiumMg, 2800);
      expect(saved.magnesiumMg, 320);
    });

    test('keeps the existing row id so the upsert replaces it', () async {
      when(() => dailyLogRepository.findByDate(any()))
          .thenAnswer((_) async => DailyLogFixture.fixture(id: 42));

      await service.logMeal(MealEntryFixture.fixture());

      expect(capturedLog().id, 42);
    });
  });

  group('deleteMeal', () {
    test('deletes the meal', () async {
      await service.deleteMeal(7, date);

      verify(() => mealRepository.delete(7)).called(1);
    });

    test('recalculates after deleting, not before', () async {
      await service.deleteMeal(7, date);

      verifyInOrder([
        () => mealRepository.delete(any()),
        () => mealRepository.findByDate(any()),
        () => dailyLogRepository.save(any()),
      ]);
    });

    test('recalculates the date it was given', () async {
      await service.deleteMeal(7, date);

      verify(() => mealRepository.findByDate(date)).called(1);
    });

    test('zeroes the totals when the last meal of the day goes', () async {
      when(() => dailyLogRepository.findByDate(any()))
          .thenAnswer((_) async => DailyLogFixture.fixture(totalFatG: 120));
      when(() => mealRepository.findByDate(any())).thenAnswer((_) async => []);

      await service.deleteMeal(7, date);

      final saved = capturedLog();
      expect(saved.totalFatG, 0);
      expect(saved.totalNetCarbsG, 0);
      expect(saved.totalProteinG, 0);
      expect(saved.ketoRatioAvg, 0);
    });

    test('an emptied day keeps its water and electrolytes', () async {
      when(() => dailyLogRepository.findByDate(any())).thenAnswer(
        (_) async => DailyLogFixture.fixture(totalFatG: 120, waterMl: 2000),
      );
      when(() => mealRepository.findByDate(any())).thenAnswer((_) async => []);

      await service.deleteMeal(7, date);

      expect(capturedLog().waterMl, 2000);
    });
  });

  group('failure propagation', () {
    // The repositories throw typed exceptions; the service lets them
    // propagate rather than catching to convert, per base_design.md.
    test('a failed meal save propagates and skips the recalculation', () async {
      when(() => mealRepository.save(any())).thenThrow(Exception('boom'));

      await expectLater(
        service.logMeal(MealEntryFixture.fixture()),
        throwsException,
      );
      verifyNever(() => dailyLogRepository.save(any()));
    });

    test('a failed delete propagates and skips the recalculation', () async {
      when(() => mealRepository.delete(any())).thenThrow(Exception('boom'));

      await expectLater(service.deleteMeal(7, date), throwsException);
      verifyNever(() => dailyLogRepository.save(any()));
    });
  });

  // The provider declaration is public API of this file and part of Epic #6's
  // "100% public method coverage" line, but nothing exercised it: every test
  // above constructs the service directly. Its two sibling services
  // (KetoRatioCalculator, ElectrolyteAdvisor) each have this test; this one
  // was the odd one out.
  group('mealLoggingServiceProvider', () {
    ProviderContainer containerWithMocks() {
      final container = ProviderContainer(
        overrides: [
          mealRepositoryProvider.overrideWithValue(mealRepository),
          dailyLogRepositoryProvider.overrideWithValue(dailyLogRepository),
          // #58 added the state machine to the service's dependencies, and it
          // reaches databaseProvider through streakRepositoryProvider. Without
          // this override the container tries to open a real database.
          streakRepositoryProvider.overrideWithValue(streakRepository),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('resolves to a MealLoggingService', () {
      expect(
        containerWithMocks().read(mealLoggingServiceProvider),
        isA<MealLoggingService>(),
      );
    });

    test('injects the repositories the container provides', () {
      final resolved = containerWithMocks().read(mealLoggingServiceProvider);

      expect(resolved.mealRepository, same(mealRepository));
      expect(resolved.dailyLogRepository, same(dailyLogRepository));
    });

    // Proves the wiring end to end: a call through the resolved service reaches
    // the overridden repositories, not some instance of its own.
    test('the resolved service writes through those repositories', () async {
      await containerWithMocks()
          .read(mealLoggingServiceProvider)
          .logMeal(MealEntryFixture.fixture());

      verify(() => mealRepository.save(any())).called(1);
      verify(() => dailyLogRepository.save(any())).called(1);
    });
  });

  // #58: the streak is re-evaluated from the day's totals after every write.
  // Corrected against design/m3_preflight.md — the issue's own snippet
  // evaluated unconditionally, which opens a grace period on a fat-only
  // breakfast (§1.3), and rebuilt the DailyLog without ketoRatioAvg (§4.1).
  group('streak evaluation', () {
    /// Today, at a fixed time of day.
    ///
    /// The clock has to be read: "is this today" is the whole gate. Pinning
    /// the time of day keeps everything else deterministic, and the only way
    /// this is flaky is a run that straddles midnight.
    DateTime todayAt(int hour) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour);
    }

    /// Makes the day hold exactly [meals], whatever date is queried.
    void dayHolds(List<MealEntry> meals) =>
        when(() => mealRepository.findByDate(any())).thenAnswer((_) async {
          return meals;
        });

    /// Whether the day was judged compliant.
    bool judgedCompliant() =>
        verify(
              () => adaptationPhaseService.evaluateToday(
                any(),
                compliant: captureAny(named: 'compliant'),
              ),
            ).captured.single
            as bool;

    void verifyNotEvaluated() => verifyNever(
      () => adaptationPhaseService.evaluateToday(
        any(),
        compliant: any(named: 'compliant'),
      ),
    );

    test('a compliant day is recorded as compliant', () async {
      // 40 / (2 + 15) = 2.35 — above the 2.0 threshold.
      final meal = MealEntryFixture.fixture(
        timestamp: todayAt(12),
        fatG: 40,
        netCarbsG: 2,
        proteinG: 15,
      );
      dayHolds([meal]);

      await service.logMeal(meal);

      expect(judgedCompliant(), isTrue);
    });

    test('a day under the threshold is recorded as a breach', () async {
      // 10 / (30 + 20) = 0.2.
      final meal = MealEntryFixture.fixture(
        timestamp: todayAt(12),
        fatG: 10,
        netCarbsG: 30,
        proteinG: 20,
      );
      dayHolds([meal]);

      await service.logMeal(meal);

      expect(judgedCompliant(), isFalse);
    });

    // Exactly 2.0 is met, not missed — the same boundary convention
    // ElectrolyteAdvisor uses for its targets.
    test('exactly the threshold counts as compliant', () async {
      // 40 / (5 + 15) = 2.0.
      final meal = MealEntryFixture.fixture(
        timestamp: todayAt(12),
        fatG: 40,
        netCarbsG: 5,
        proteinG: 15,
      );
      dayHolds([meal]);

      await service.logMeal(meal);

      expect(judgedCompliant(), isTrue);
    });

    // The regression that design/m3_preflight.md §1.3 exists for. A first
    // meal of pure fat gives `fat / 0`, which KetoRatioCalculator reports as
    // 0 by design. Evaluating that would breach a perfectly compliant day —
    // butter coffee, the most ordinary keto morning there is.
    test('a day with no carbs and no protein is not evaluated', () async {
      final meal = MealEntryFixture.fixture(
        timestamp: todayAt(7),
        fatG: 22,
        netCarbsG: 0,
        proteinG: 0,
      );
      dayHolds([meal]);

      await service.logMeal(meal);

      verifyNotEvaluated();
    });

    test('an empty day is not evaluated', () async {
      dayHolds([]);

      await service.deleteMeal(1, todayAt(12));

      verifyNotEvaluated();
    });

    // Backdating a diary entry must not rewrite streak history — the state
    // machine holds one current streak, not a per-day ledger.
    test('a past day is not evaluated', () async {
      final meal = MealEntryFixture.fixture(
        timestamp: DateTime(2026, 1, 2, 12),
        fatG: 40,
        netCarbsG: 2,
        proteinG: 15,
      );
      dayHolds([meal]);

      await service.logMeal(meal);

      verifyNotEvaluated();
    });

    test('deleting a meal re-evaluates the day', () async {
      dayHolds([
        MealEntryFixture.fixture(
          timestamp: todayAt(12),
          fatG: 10,
          netCarbsG: 30,
          proteinG: 20,
        ),
      ]);

      await service.deleteMeal(1, todayAt(12));

      expect(judgedCompliant(), isFalse);
    });

    // The instant matters downstream: handleBreach compares it against the
    // grace-period expiry, so a midnight-normalised value would judge the
    // window by its start rather than by when the breach happened.
    test('the evaluated date keeps its time of day', () async {
      final at = todayAt(21);
      final meal = MealEntryFixture.fixture(
        timestamp: at,
        fatG: 40,
        netCarbsG: 2,
        proteinG: 15,
      );
      dayHolds([meal]);

      await service.logMeal(meal);

      final evaluated =
          verify(
                () => adaptationPhaseService.evaluateToday(
                  captureAny(),
                  compliant: any(named: 'compliant'),
                ),
              ).captured.single
              as DateTime;
      expect(evaluated, at);
    });

    // §4.1: the issue's snippet rebuilt DailyLog without ketoRatioAvg, which
    // MacroSummaryCard reads. Evaluation must not have cost the field.
    test('the saved log still carries its keto ratio', () async {
      final meal = MealEntryFixture.fixture(
        timestamp: todayAt(12),
        fatG: 40,
        netCarbsG: 2,
        proteinG: 15,
      );
      dayHolds([meal]);

      await service.logMeal(meal);

      expect(capturedLog().ketoRatioAvg, closeTo(40 / 17, 0.000001));
    });

    test('a failure in the state machine is not swallowed', () async {
      final meal = MealEntryFixture.fixture(
        timestamp: todayAt(12),
        fatG: 40,
        netCarbsG: 2,
        proteinG: 15,
      );
      dayHolds([meal]);
      when(
        () => adaptationPhaseService.evaluateToday(
          any(),
          compliant: any(named: 'compliant'),
        ),
      ).thenThrow(Exception('store gone'));

      await expectLater(service.logMeal(meal), throwsA(isA<Exception>()));
    });
  });
}
