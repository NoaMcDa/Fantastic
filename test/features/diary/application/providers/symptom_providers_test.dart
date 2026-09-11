import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/application/providers/symptom_providers.dart';
import 'package:fantastic/features/diary/application/symptom_logging_service.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/physical_symptom.dart';
import 'package:fantastic/features/diary/domain/repositories/symptom_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';

class _MockSymptomLogRepository extends Mock implements SymptomLogRepository {}

void main() {
  late _MockSymptomLogRepository repository;

  setUp(() {
    repository = _MockSymptomLogRepository();
    when(() => repository.findByDate(any())).thenAnswer((_) async => null);
  });

  ProviderContainer containerWith(_MockSymptomLogRepository repo) {
    final container = ProviderContainer(
      overrides: [symptomLogRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  DateTime queriedDate() =>
      verify(() => repository.findByDate(captureAny())).captured.single
          as DateTime;

  test('resolves to the log the repository holds', () async {
    final stored = SymptomLogFixture.varied();
    when(() => repository.findByDate(any())).thenAnswer((_) async => stored);

    final log = await containerWith(repository)
        .read(symptomLogProvider(stored.date).future);

    expect(log, stored);
    expect(log!.moodScore, 4, reason: 'every scale arrives as itself');
    expect(log.symptoms, {
      PhysicalSymptom.muscleCramps,
    }, reason: 'the symptom set arrives with it');
  });

  // Null is a valid day, not a failure: the diary shows an empty state.
  test('resolves to null for a day with nothing logged', () async {
    final log = await containerWith(repository)
        .read(symptomLogProvider(DateTime(2026, 9, 9)).future);

    expect(log, isNull);
  });

  // The layer rule from CLAUDE.md §State Management, asserted rather than
  // assumed: the provider must not reach the repository on its own.
  test('reads through the service, not around it', () async {
    final container = ProviderContainer(
      overrides: [
        symptomLogRepositoryProvider.overrideWithValue(repository),
        symptomLoggingServiceProvider.overrideWithValue(
          SymptomLoggingService(repository),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(symptomLogProvider(DateTime(2026, 9, 9)).future);

    verify(() => repository.findByDate(any())).called(1);
  });

  group('date normalisation', () {
    test('strips the time before querying', () async {
      await containerWith(repository)
          .read(symptomLogProvider(DateTime(2026, 9, 9, 20, 30)).future);

      expect(queriedDate(), DateTime(2026, 9, 9));
    });

    test('does not roll over into the next day at 23:59', () async {
      await containerWith(repository)
          .read(symptomLogProvider(DateTime(2026, 9, 9, 23, 59, 59)).future);

      expect(queriedDate(), DateTime(2026, 9, 9));
    });
  });

  test('different dates are cached separately', () async {
    final container = containerWith(repository);
    when(() => repository.findByDate(DateTime(2026, 9, 9)))
        .thenAnswer((_) async => SymptomLogFixture.bestDay());
    when(() => repository.findByDate(DateTime(2026, 9, 10)))
        .thenAnswer((_) async => null);

    final first = await container.read(
      symptomLogProvider(DateTime(2026, 9, 9)).future,
    );
    final second = await container.read(
      symptomLogProvider(DateTime(2026, 9, 10)).future,
    );

    expect(first?.energyScore, 5);
    expect(second, isNull);
  });

  test('one date is fetched once and then served from cache', () async {
    final container = containerWith(repository);
    final date = DateTime(2026, 9, 9);

    await container.read(symptomLogProvider(date).future);
    await container.read(symptomLogProvider(date).future);

    verify(() => repository.findByDate(any())).called(1);
  });

  // The refresh mechanism the sheet relies on after a save.
  test('refetches after invalidation', () async {
    final container = containerWith(repository);
    final date = DateTime(2026, 9, 9);

    await container.read(symptomLogProvider(date).future);

    when(() => repository.findByDate(any()))
        .thenAnswer((_) async => SymptomLogFixture.bestDay(date: date));
    container.invalidate(symptomLogProvider(date));

    final refreshed = await container.read(symptomLogProvider(date).future);

    expect(refreshed?.energyScore, 5);
  });

  // riverpod 3 reports a provider that failed before ever producing a value
  // as `AsyncLoading` **with** an error attached, so `await …future` never
  // completes and the state must be read directly. `container.listen` is what
  // holds the auto-disposing provider mounted while it loads — a bare `read`
  // tears it down mid-load (`m3_handoff.md`).
  test('surfaces a storage failure as an error state', () async {
    final failure = PersistenceException(
      'SembastSymptomLogRepository.findByDate',
      Exception('closed'),
    );
    when(() => repository.findByDate(any())).thenThrow(failure);

    final container = containerWith(repository);
    final date = DateTime(2026, 9, 9);
    container.listen(symptomLogProvider(date), (_, _) {});

    await pumpEventQueue();

    final state = container.read(symptomLogProvider(date));

    expect(state.hasError, isTrue);
    expect(state.error, same(failure));
  });
}
