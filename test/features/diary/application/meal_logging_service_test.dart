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
    // #303 gave the state machine a second dependency: it derives the streak
    // from the whole day history on every write.
    when(dailyLogRepository.findAll).thenAnswer((_) async => []);
    when(streakRepository.load).thenAnswer((_) async => null);
    when(() => streakRepository.save(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as StreakState,
    );
    when(() => adaptationPhaseService.recomputeFor(any(), at: any(named: 'at')))
        .thenAnswer((_) async => const StreakState());
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
  group('streak re-derivation', () {
    /// Today, at a fixed time of day.
    ///
    /// The clock has to be read: whether a date is today decides whether a
    /// grace window may open. Pinning the time of day keeps everything else
    /// deterministic, and the only way this is flaky is a run that straddles
    /// midnight.
    DateTime todayAt(int hour) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, hour);
    }

    /// Makes the day hold exactly [meals], whatever date is queried.
    void dayHolds(List<MealEntry> meals) =>
        when(() => mealRepository.findByDate(any())).thenAnswer((_) async {
          return meals;
        });

    /// The date handed to the state machine.
    DateTime recomputedDate() =>
        verify(
              () => adaptationPhaseService.recomputeFor(
                captureAny(),
                at: any(named: 'at'),
              ),
            ).captured.single
            as DateTime;

    /// The instant the state machine was told to reason from.
    DateTime evaluatedAt() =>
        verify(
              () => adaptationPhaseService.recomputeFor(
                any(),
                at: captureAny(named: 'at'),
              ),
            ).captured.single
            as DateTime;

    test('every logged meal re-derives the streak', () async {
      // The service no longer decides compliance — it says which day moved and
      // when, and the state machine derives the rest. That is what stopped two
      // copies of the rule existing (#303).
      final meal = MealEntryFixture.fixture(timestamp: todayAt(9));
      dayHolds([meal]);

      await service.logMeal(meal);

      verify(
        () => adaptationPhaseService.recomputeFor(any(), at: any(named: 'at')),
      ).called(1);
    });

    test('a past day is re-derived', () async {
      // The inversion of the old `a past day is not evaluated`. That test
      // asserted the defect as intended behaviour: the `_isToday` guard threw
      // the evaluation away, so back-filling a forgotten day repainted the
      // calendar and left the streak exactly as broken as it was.
      final lastWeek = todayAt(9).subtract(const Duration(days: 7));
      final meal = MealEntryFixture.fixture(timestamp: lastWeek);
      dayHolds([meal]);

      await service.logMeal(meal);

      expect(recomputedDate(), lastWeek);
    });

    test('a fat-only day is re-derived, not skipped', () async {
      // The zero-denominator exemption is gone. Under a carb rule a day with
      // no net carbs and no protein is the best possible day, not one to leave
      // unevaluated.
      final meal = MealEntryFixture.fixture(
        timestamp: todayAt(7),
        fatG: 40,
        netCarbsG: 0,
        proteinG: 0,
      );
      dayHolds([meal]);

      await service.logMeal(meal);

      verify(
        () => adaptationPhaseService.recomputeFor(any(), at: any(named: 'at')),
      ).called(1);
    });

    test('emptying a day still re-derives it', () async {
      // Deleting the last meal of a day can shorten a streak, so the write has
      // to reach the state machine like any other.
      dayHolds([]);

      await service.deleteMeal(1, todayAt(12));

      verify(
        () => adaptationPhaseService.recomputeFor(any(), at: any(named: 'at')),
      ).called(1);
    });

    test('the date handed over is the day the meal was logged on', () async {
      final at = todayAt(21);
      final meal = MealEntryFixture.fixture(timestamp: at);
      dayHolds([meal]);

      await service.logMeal(meal);

      expect(recomputedDate(), at);
    });

    test(
      'logging reasons from the wall clock, not the meal timestamp',
      () async {
        // The derivation walks back from the instant it is given. A back-dated
        // meal carries a timestamp days in the past, and using it would start
        // the walk there — so today would stop counting toward the streak.
        final before = DateTime.now();
        final meal = MealEntryFixture.fixture(
          timestamp: todayAt(9).subtract(const Duration(days: 3)),
        );
        dayHolds([meal]);

        await service.logMeal(meal);

        expect(evaluatedAt().isBefore(before), isFalse);
      },
    );

    test('a deletion reasons from the wall clock', () async {
      // Callers pass a date-only value to `deleteMeal` — the diary holds its
      // selected date stripped to midnight — and handing that to the state
      // machine dated the breach to 00:00, buying two hours of grace instead
      // of twenty-four.
      final before = DateTime.now();
      dayHolds([]);

      await service.deleteMeal(
        1,
        DateTime(before.year, before.month, before.day),
      );

      expect(evaluatedAt().isBefore(before), isFalse);
    });

    test('the saved log still carries its keto ratio', () async {
      // The ratio keeps every other job it has — the ring arc, the macro card,
      // `DailyLog.ketoRatioAvg`. It simply stopped deciding the streak.
      final meal = MealEntryFixture.fixture(
        timestamp: todayAt(13),
        fatG: 40,
        netCarbsG: 2,
        proteinG: 18,
      );
      dayHolds([meal]);

      await service.logMeal(meal);

      expect(capturedLog().ketoRatioAvg, closeTo(2.0, 0.0001));
    });

    test('a failure in the state machine is not swallowed', () async {
      final meal = MealEntryFixture.fixture(timestamp: todayAt(10));
      dayHolds([meal]);
      when(
        () => adaptationPhaseService.recomputeFor(any(), at: any(named: 'at')),
      ).thenThrow(Exception('store gone'));

      await expectLater(service.logMeal(meal), throwsA(isA<Exception>()));
    });
  });
}
