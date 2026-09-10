import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';

class _MockDailyLogRepository extends Mock implements DailyLogRepository {}

void main() {
  late _MockDailyLogRepository repository;

  setUpAll(() => registerFallbackValue(DailyLogFixture.fixture()));

  setUp(() {
    repository = _MockDailyLogRepository();
    when(() => repository.findByDate(any())).thenAnswer((_) async => null);
  });

  ProviderContainer containerWith(_MockDailyLogRepository repo) {
    final container = ProviderContainer(
      overrides: [dailyLogRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// The date the repository was actually queried with.
  DateTime queriedDate() =>
      verify(() => repository.findByDate(captureAny())).captured.single
          as DateTime;

  test('resolves to the log the repository returns', () async {
    final log = DailyLogFixture.fixture();
    when(() => repository.findByDate(any())).thenAnswer((_) async => log);

    final result = await containerWith(repository)
        .read(todaysDailyLogProvider(DailyLogFixture.defaultDate).future);

    expect(result, log);
  });

  // Null is "nothing logged that day", not a failure — the UI shows an empty
  // state rather than an error.
  test('resolves to null when the day has no log', () async {
    final result = await containerWith(repository)
        .read(todaysDailyLogProvider(DailyLogFixture.defaultDate).future);

    expect(result, isNull);
  });

  group('date normalisation', () {
    test('strips the time before querying', () async {
      await containerWith(repository)
          .read(todaysDailyLogProvider(DateTime(2026, 9, 9, 20, 30)).future);

      expect(queriedDate(), DateTime(2026, 9, 9));
    });

    test('a morning and an evening time query the same day', () async {
      final container = containerWith(repository);

      await container.read(
        todaysDailyLogProvider(DateTime(2026, 9, 9, 8)).future,
      );
      await container.read(
        todaysDailyLogProvider(DateTime(2026, 9, 9, 20)).future,
      );

      final dates = verify(() => repository.findByDate(captureAny())).captured
          .cast<DateTime>();
      expect(dates, [DateTime(2026, 9, 9), DateTime(2026, 9, 9)]);
    });

    test('a date already at midnight is passed through unchanged', () async {
      await containerWith(repository)
          .read(todaysDailyLogProvider(DateTime(2026, 9, 9)).future);

      expect(queriedDate(), DateTime(2026, 9, 9));
    });

    test('does not roll over into the next day at 23:59', () async {
      await containerWith(
        repository,
      ).read(todaysDailyLogProvider(DateTime(2026, 9, 9, 23, 59, 59)).future);

      expect(queriedDate(), DateTime(2026, 9, 9));
    });
  });

  test('different dates are cached separately', () async {
    final container = containerWith(repository);
    when(() => repository.findByDate(DateTime(2026, 9, 9)))
        .thenAnswer((_) async => DailyLogFixture.fixture(totalFatG: 10));
    when(() => repository.findByDate(DateTime(2026, 9, 10)))
        .thenAnswer((_) async => DailyLogFixture.fixture(totalFatG: 20));

    final first = await container.read(
      todaysDailyLogProvider(DateTime(2026, 9, 9)).future,
    );
    final second = await container.read(
      todaysDailyLogProvider(DateTime(2026, 9, 10)).future,
    );

    expect(first!.totalFatG, 10);
    expect(second!.totalFatG, 20);
  });

  test('one date is fetched once and then served from cache', () async {
    final container = containerWith(repository);
    final date = DateTime(2026, 9, 9);

    await container.read(todaysDailyLogProvider(date).future);
    await container.read(todaysDailyLogProvider(date).future);

    verify(() => repository.findByDate(any())).called(1);
  });

  // Not covered here: the error branch. A repository failure does reach the
  // UI as `AsyncValue.error` — that is riverpod's own behaviour — but pinning
  // it in a unit test fights the auto-dispose lifecycle: `.future` on an
  // errored auto-disposing provider never settles, and re-reading its state
  // restarts the load. The throw itself is covered where it originates, by the
  // `failure` group in each repository contract suite (#177), and the UI's
  // error branch is covered by the widget tests that render it.

  test('refetches after invalidation', () async {
    final container = containerWith(repository);
    final date = DateTime(2026, 9, 9);

    await container.read(todaysDailyLogProvider(date).future);
    container.invalidate(todaysDailyLogProvider(date));
    await container.read(todaysDailyLogProvider(date).future);

    verify(() => repository.findByDate(any())).called(2);
  });
}
