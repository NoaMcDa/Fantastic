import 'package:fantastic/features/dashboard/application/keto_ratio_calculator.dart';
import 'package:fantastic/features/dashboard/domain/models/daily_log.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:fantastic/features/diary/application/meal_logging_service.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/domain/repositories/meal_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixtures.dart';

class _MockMealRepository extends Mock implements MealRepository {}

class _MockDailyLogRepository extends Mock implements DailyLogRepository {}

void main() {
  late _MockMealRepository mealRepository;
  late _MockDailyLogRepository dailyLogRepository;
  late MealLoggingService service;

  final date = MealEntryFixture.defaultTimestamp;

  setUpAll(() {
    registerFallbackValue(MealEntryFixture.fixture());
    registerFallbackValue(DailyLogFixture.fixture());
  });

  setUp(() {
    mealRepository = _MockMealRepository();
    dailyLogRepository = _MockDailyLogRepository();
    service = MealLoggingService(
      mealRepository: mealRepository,
      dailyLogRepository: dailyLogRepository,
      ketoRatioCalculator: const KetoRatioCalculator(),
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
}
