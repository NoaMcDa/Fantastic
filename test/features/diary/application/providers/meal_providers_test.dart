import 'package:fantastic/features/diary/application/providers/meal_providers.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/repositories/meal_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';

class _MockMealRepository extends Mock implements MealRepository {}

void main() {
  late _MockMealRepository repository;

  setUpAll(() => registerFallbackValue(MealEntryFixture.fixture()));

  setUp(() {
    repository = _MockMealRepository();
    when(() => repository.findByDate(any())).thenAnswer((_) async => []);
  });

  ProviderContainer containerWith(_MockMealRepository repo) {
    final container = ProviderContainer(
      overrides: [mealRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// The date the repository was actually queried with.
  DateTime queriedDate() =>
      verify(() => repository.findByDate(captureAny())).captured.single
          as DateTime;

  test('resolves to the meals the repository returns', () async {
    when(() => repository.findByDate(any())).thenAnswer(
      (_) async => [
        MealEntryFixture.fixture(mealName: 'Breakfast'),
        MealEntryFixture.fixture(mealName: 'Lunch'),
      ],
    );

    final meals = await containerWith(repository)
        .read(todaysMealsProvider(MealEntryFixture.defaultTimestamp).future);

    expect(meals, hasLength(2));
    expect(meals.map((m) => m.mealName), ['Breakfast', 'Lunch']);
  });

  // An empty day and a missing day look identical to the user, so there is
  // nothing a null would express that an empty list does not.
  test(
    'resolves to an empty list, never null, when nothing is logged',
    () async {
      final meals = await containerWith(repository)
          .read(todaysMealsProvider(MealEntryFixture.defaultTimestamp).future);

      expect(meals, isEmpty);
    },
  );

  test('preserves the order the repository returned', () async {
    // The repository contract is newest-first; the provider must not re-sort.
    when(() => repository.findByDate(any())).thenAnswer(
      (_) async => [
        MealEntryFixture.fixture(timestamp: DateTime(2026, 9, 9, 20)),
        MealEntryFixture.fixture(timestamp: DateTime(2026, 9, 9, 8)),
      ],
    );

    final meals = await containerWith(repository)
        .read(todaysMealsProvider(DateTime(2026, 9, 9)).future);

    expect(meals.first.timestamp.hour, 20);
    expect(meals.last.timestamp.hour, 8);
  });

  group('date normalisation', () {
    test('strips the time before querying', () async {
      await containerWith(repository)
          .read(todaysMealsProvider(DateTime(2026, 9, 9, 20, 30)).future);

      expect(queriedDate(), DateTime(2026, 9, 9));
    });

    test('a morning and an evening time query the same day', () async {
      final container = containerWith(repository);

      await container.read(todaysMealsProvider(DateTime(2026, 9, 9, 8)).future);
      await container.read(
        todaysMealsProvider(DateTime(2026, 9, 9, 20)).future,
      );

      final dates = verify(() => repository.findByDate(captureAny())).captured
          .cast<DateTime>();
      expect(dates, [DateTime(2026, 9, 9), DateTime(2026, 9, 9)]);
    });

    test('does not roll over into the next day at 23:59', () async {
      await containerWith(repository)
          .read(todaysMealsProvider(DateTime(2026, 9, 9, 23, 59, 59)).future);

      expect(queriedDate(), DateTime(2026, 9, 9));
    });
  });

  test('different dates are cached separately', () async {
    final container = containerWith(repository);
    when(() => repository.findByDate(DateTime(2026, 9, 9))).thenAnswer(
      (_) async => [MealEntryFixture.fixture(mealName: 'Yesterday')],
    );
    when(() => repository.findByDate(DateTime(2026, 9, 10)))
        .thenAnswer((_) async => []);

    final first = await container.read(
      todaysMealsProvider(DateTime(2026, 9, 9)).future,
    );
    final second = await container.read(
      todaysMealsProvider(DateTime(2026, 9, 10)).future,
    );

    expect(first.single.mealName, 'Yesterday');
    expect(second, isEmpty);
  });

  test('one date is fetched once and then served from cache', () async {
    final container = containerWith(repository);
    final date = DateTime(2026, 9, 9);

    await container.read(todaysMealsProvider(date).future);
    await container.read(todaysMealsProvider(date).future);

    verify(() => repository.findByDate(any())).called(1);
  });

  // The refresh mechanism the diary relies on after a log or a delete.
  test('refetches after invalidation', () async {
    final container = containerWith(repository);
    final date = DateTime(2026, 9, 9);

    await container.read(todaysMealsProvider(date).future);
    container.invalidate(todaysMealsProvider(date));
    await container.read(todaysMealsProvider(date).future);

    verify(() => repository.findByDate(any())).called(2);
  });
}
