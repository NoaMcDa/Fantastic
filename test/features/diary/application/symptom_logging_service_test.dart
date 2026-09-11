import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/application/symptom_logging_service.dart';
import 'package:fantastic/features/diary/domain/models/symptom_log.dart';
import 'package:fantastic/features/diary/domain/repositories/symptom_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../fixtures/fixtures.dart';

class _MockSymptomLogRepository extends Mock implements SymptomLogRepository {}

/// A [SymptomLog] reporting an out-of-range score for exactly one scale.
///
/// Not a fixture: this is an object the constructor forbids. `SymptomLog`
/// asserts every score is 1–5, and tests run in debug, so
/// `SymptomLog(energyScore: 0, …)` throws `AssertionError` before the service
/// is ever called — which is why #75's two failure-path tests cannot be
/// written the way #75 specifies them (`design/m5_preflight.md` §1.4).
///
/// Overriding a field with a getter is the only way to produce what a
/// *release* build can produce, where the asserts are compiled out and
/// `SymptomLoggingService`'s range check is the sole enforcement.
class _UncheckedSymptomLog extends SymptomLog {
  _UncheckedSymptomLog(this.scale, this.score)
    : super(
        date: SymptomLogFixture.defaultDate,
        energyScore: 3,
        clarityScore: 3,
        hungerScore: 3,
        physicalScore: 3,
        moodScore: 3,
      );

  final String scale;
  final int score;

  int _score(String name, int valid) => scale == name ? score : valid;

  @override
  int get energyScore => _score('energyScore', super.energyScore);
  @override
  int get clarityScore => _score('clarityScore', super.clarityScore);
  @override
  int get hungerScore => _score('hungerScore', super.hungerScore);
  @override
  int get physicalScore => _score('physicalScore', super.physicalScore);
  @override
  int get moodScore => _score('moodScore', super.moodScore);
}

void main() {
  late _MockSymptomLogRepository repository;
  late SymptomLoggingService service;

  setUpAll(() => registerFallbackValue(SymptomLogFixture.fixture()));

  setUp(() {
    repository = _MockSymptomLogRepository();
    service = SymptomLoggingService(repository);
    when(() => repository.save(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.single as SymptomLog,
    );
    when(() => repository.findByDate(any())).thenAnswer((_) async => null);
  });

  group('logSymptoms', () {
    test('saves the log and returns the persisted copy', () async {
      final stored = SymptomLogFixture.varied(id: 20260909);
      when(() => repository.save(any())).thenAnswer((_) async => stored);

      final result = await service.logSymptoms(SymptomLogFixture.varied());

      expect(result, stored);
      expect(result.id, 20260909, reason: 'the persisted copy carries the id');
    });

    // Each scale must reach the store as itself. An all-3s fixture cannot
    // tell a service that saved the log it was handed from one that rebuilt
    // it with two fields crossed.
    test('passes every scale through untouched', () async {
      await service.logSymptoms(SymptomLogFixture.varied(notes: 'שבוע קשה'));

      final saved =
          verify(() => repository.save(captureAny())).captured.single
              as SymptomLog;

      expect(saved.energyScore, 1);
      expect(saved.clarityScore, 2);
      expect(saved.hungerScore, 3);
      expect(saved.physicalScore, 4);
      expect(saved.moodScore, 5);
      expect(saved.notes, 'שבוע קשה');
    });

    test('accepts the lower bound — every scale at 1', () async {
      await service.logSymptoms(SymptomLogFixture.worstDay());

      verify(() => repository.save(any())).called(1);
    });

    test('accepts the upper bound — every scale at 5', () async {
      await service.logSymptoms(SymptomLogFixture.bestDay());

      verify(() => repository.save(any())).called(1);
    });

    // Every scale, not just the first: a validator that checked `energyScore`
    // five times would pass a single-field test and let a bad mood score
    // through. See `design/m5_preflight.md` §1.1 for what crossing scales
    // costs here.
    for (final scale in const [
      'energyScore',
      'clarityScore',
      'hungerScore',
      'physicalScore',
      'moodScore',
    ]) {
      // Thrown synchronously, before the future is created: the validation
      // runs ahead of the repository call, which is the whole point — a
      // rejected log must never reach the store.
      test('rejects $scale below the range, and saves nothing', () {
        expect(
          () => service.logSymptoms(_UncheckedSymptomLog(scale, 0)),
          throwsArgumentError,
        );

        verifyNever(() => repository.save(any()));
      });

      test('rejects $scale above the range, and saves nothing', () {
        expect(
          () => service.logSymptoms(_UncheckedSymptomLog(scale, 6)),
          throwsArgumentError,
        );

        verifyNever(() => repository.save(any()));
      });
    }

    test('names the offending scale in the error', () {
      expect(
        () => service.logSymptoms(_UncheckedSymptomLog('moodScore', 9)),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'moodScore')
              .having((e) => e.invalidValue, 'invalidValue', 9),
        ),
      );
    });

    // The service converts nothing — presentation reads the repository's
    // typed failure as `AsyncValue.error`. See base_design.md §Error Handling.
    test('lets a storage failure propagate unchanged', () {
      final failure = PersistenceException(
        'SembastSymptomLogRepository.save',
        Exception('disk full'),
      );
      when(() => repository.save(any())).thenThrow(failure);

      expect(
        () => service.logSymptoms(SymptomLogFixture.fixture()),
        throwsA(same(failure)),
      );
    });
  });

  group('symptomsForDate', () {
    test('returns the log the repository holds for the day', () async {
      final stored = SymptomLogFixture.varied();
      when(() => repository.findByDate(any())).thenAnswer((_) async => stored);

      expect(await service.symptomsForDate(stored.date), stored);
    });

    // Null is "not logged yet", not a failure — the diary renders an empty
    // state rather than an error.
    test('returns null for a day with no log', () async {
      expect(await service.symptomsForDate(DateTime(2026, 9, 9)), isNull);
    });

    test('strips the time before querying', () async {
      await service.symptomsForDate(DateTime(2026, 9, 9, 23, 59, 59));

      final queried =
          verify(() => repository.findByDate(captureAny())).captured.single
              as DateTime;

      expect(queried, DateTime(2026, 9, 9));
    });

    test('lets a storage failure propagate unchanged', () {
      final failure = PersistenceException(
        'SembastSymptomLogRepository.findByDate',
        Exception('closed'),
      );
      when(() => repository.findByDate(any())).thenThrow(failure);

      expect(
        () => service.symptomsForDate(DateTime(2026, 9, 9)),
        throwsA(same(failure)),
      );
    });
  });

  group('score bounds', () {
    // The sheet's segmented selector renders `maxScore` options. If these
    // ever diverged from the domain model's asserts, a tap would throw.
    test('match the range the domain model asserts', () {
      expect(SymptomLoggingService.minScore, 1);
      expect(SymptomLoggingService.maxScore, 5);
    });
  });
}
