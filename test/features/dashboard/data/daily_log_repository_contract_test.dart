import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/dashboard/data/repositories/sembast_daily_log_repository.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../../../fixtures/fixtures.dart';
import '../../../helpers/test_database.dart';

/// The contract every [DailyLogRepository] implementation must satisfy.
///
/// A top-level function taking a factory rather than a fixed implementation,
/// so any future backing store runs against these same cases — Liskov
/// substitution enforced at the test level.
void runDailyLogRepositoryContractTests(
  DailyLogRepository Function() factory, {
  required Future<void> Function() breakStore,
}) {
  late DailyLogRepository repo;

  setUp(() => repo = factory());

  group('save', () {
    test('returns a log with a non-null id', () async {
      final saved = await repo.save(DailyLogFixture.fixture());

      expect(saved.id, isNotNull);
    });

    test('the saved log is retrievable by its date', () async {
      final saved = await repo.save(DailyLogFixture.fixture());

      expect(await repo.findByDate(DailyLogFixture.defaultDate), saved);
    });

    test('preserves every field apart from the assigned id', () async {
      final original = DailyLogFixture.fixture();

      final saved = await repo.save(original);

      expect(saved, original.copyWith(id: saved.id));
    });

    // The single-record-per-day guarantee. A plain `put` here would either
    // violate the unique index and throw, or leave two rows for one day.
    test('twice for the same date updates rather than duplicating', () async {
      await repo.save(DailyLogFixture.fixture(totalFatG: 100));

      await repo.save(DailyLogFixture.fixture(totalFatG: 150));

      expect(await repo.findAll(), hasLength(1));
      expect(
        (await repo.findByDate(DailyLogFixture.defaultDate))!.totalFatG,
        150,
      );
    });

    test('the second save for a date reuses the first row id', () async {
      final first = await repo.save(DailyLogFixture.fixture(totalFatG: 100));

      final second = await repo.save(DailyLogFixture.fixture(totalFatG: 150));

      expect(second.id, first.id);
    });

    test('two different dates each get their own record', () async {
      await repo.save(DailyLogFixture.fixture(date: DateTime(2026, 9, 9)));
      await repo.save(DailyLogFixture.fixture(date: DateTime(2026, 9, 10)));

      expect(await repo.findAll(), hasLength(2));
    });

    test('an all-zero day is stored, not treated as absent', () async {
      final saved = await repo.save(DailyLogFixture.empty());

      expect(saved.id, isNotNull);
      expect(await repo.findByDate(DailyLogFixture.defaultDate), isNotNull);
    });
  });

  group('findByDate', () {
    test('returns null when no record exists', () async {
      expect(await repo.findByDate(DailyLogFixture.defaultDate), isNull);
    });

    test('returns null for a date other than the one stored', () async {
      await repo.save(DailyLogFixture.fixture(date: DateTime(2026, 9, 9)));

      expect(await repo.findByDate(DateTime(2026, 9, 10)), isNull);
    });

    test('matches on the calendar day, ignoring the time of day', () async {
      await repo.save(DailyLogFixture.fixture(date: DateTime(2026, 9, 9)));

      expect(await repo.findByDate(DateTime(2026, 9, 9, 23, 59)), isNotNull);
    });
  });

  group('findAll', () {
    test('returns an empty list when nothing is stored', () async {
      expect(await repo.findAll(), isEmpty);
    });

    test('returns logs newest first', () async {
      // Saved out of order, so passing cannot be an artefact of insertion
      // order.
      final oldest = await repo.save(
        DailyLogFixture.fixture(date: DateTime(2026, 9, 7)),
      );
      final newest = await repo.save(
        DailyLogFixture.fixture(date: DateTime(2026, 9, 9)),
      );
      final middle = await repo.save(
        DailyLogFixture.fixture(date: DateTime(2026, 9, 8)),
      );

      expect(await repo.findAll(), [newest, middle, oldest]);
    });

    test('orders correctly across a year boundary', () async {
      // yyyyMMdd sorts lexically the same way it sorts chronologically, but
      // only if the encoding is right — 20261231 must come before 20270101.
      final earlier = await repo.save(
        DailyLogFixture.fixture(date: DateTime(2026, 12, 31)),
      );
      final later = await repo.save(
        DailyLogFixture.fixture(date: DateTime(2027, 1, 1)),
      );

      expect(await repo.findAll(), [later, earlier]);
    });
  });

  group('deleteByDate', () {
    test('removes the record', () async {
      await repo.save(DailyLogFixture.fixture());

      await repo.deleteByDate(DailyLogFixture.defaultDate);

      expect(await repo.findByDate(DailyLogFixture.defaultDate), isNull);
      expect(await repo.findAll(), isEmpty);
    });

    test('is idempotent for an unknown date', () async {
      await expectLater(repo.deleteByDate(DateTime(2026, 1, 1)), completes);
    });

    test('deleting one date leaves the others intact', () async {
      final kept = await repo.save(
        DailyLogFixture.fixture(date: DateTime(2026, 9, 9)),
      );
      await repo.save(DailyLogFixture.fixture(date: DateTime(2026, 9, 10)));

      await repo.deleteByDate(DateTime(2026, 9, 10));

      expect(await repo.findAll(), [kept]);
    });

    test('the date is reusable after a delete', () async {
      await repo.save(DailyLogFixture.fixture(totalFatG: 100));
      await repo.deleteByDate(DailyLogFixture.defaultDate);

      final resaved = await repo.save(DailyLogFixture.fixture(totalFatG: 200));

      expect(resaved.totalFatG, 200);
      expect(await repo.findAll(), hasLength(1));
    });
  });

  group('round-trip', () {
    // ketoRatioAvg and waterMl are the two fields the pre-#158 issue text got
    // wrong — one renamed, one missing entirely. This is the case that would
    // have caught either.
    test('ketoRatioAvg and waterMl survive a save/find round-trip', () async {
      await repo.save(
        DailyLogFixture.fixture(ketoRatioAvg: 1.73, waterMl: 2750),
      );

      final found = await repo.findByDate(DailyLogFixture.defaultDate);

      expect(found!.ketoRatioAvg, 1.73);
      expect(found.waterMl, 2750);
    });

    test('all three electrolytes survive a round-trip', () async {
      await repo.save(
        DailyLogFixture.fixture(
          sodiumMg: 4100,
          potassiumMg: 3300,
          magnesiumMg: 420,
        ),
      );

      final found = await repo.findByDate(DailyLogFixture.defaultDate);

      expect(found!.sodiumMg, 4100);
      expect(found.potassiumMg, 3300);
      expect(found.magnesiumMg, 420);
    });

    test('the date round-trips exactly, time of day included', () async {
      final date = DateTime(2026, 9, 9, 6, 15);

      final saved = await repo.save(DailyLogFixture.fixture(date: date));

      expect(saved.date, date);
      expect((await repo.findByDate(date))!.date, date);
    });
  });

  // Every method must surface a storage failure as a typed
  // PersistenceException rather than letting the backing store's own error
  // escape — otherwise `application/` and `presentation/` can only handle a
  // failed write by catching a sembast type, which is the leak the repository
  // abstraction exists to prevent.
  group('failure', () {
    setUp(() async => breakStore());

    test('save throws a PersistenceException', () async {
      await expectLater(
        repo.save(DailyLogFixture.fixture()),
        throwsA(isA<PersistenceException>()),
      );
    });

    test('findByDate throws a PersistenceException', () async {
      await expectLater(
        repo.findByDate(DailyLogFixture.defaultDate),
        throwsA(isA<PersistenceException>()),
      );
    });

    test('findAll throws a PersistenceException', () async {
      await expectLater(repo.findAll(), throwsA(isA<PersistenceException>()));
    });

    test('deleteByDate throws a PersistenceException', () async {
      await expectLater(
        repo.deleteByDate(DailyLogFixture.defaultDate),
        throwsA(isA<PersistenceException>()),
      );
    });

    test('the failure names the operation and keeps its cause', () async {
      await expectLater(
        repo.findAll(),
        throwsA(
          isA<PersistenceException>()
              .having(
                (e) => e.message,
                'message',
                contains('DailyLogRepository.findAll'),
              )
              .having((e) => e.cause, 'cause', isNotNull),
        ),
      );
    });
  });
}

void main() {
  group('SembastDailyLogRepository', () {
    late Database db;

    setUp(() async => db = await openTestDatabase());
    tearDown(() async => closeTestDatabase(db));

    runDailyLogRepositoryContractTests(
      () => SembastDailyLogRepository(db),
      // Closing the database makes every store access throw
      // `DatabaseException.closed()`, which is a real storage failure from
      // inside the repository rather than a stubbed one.
      breakStore: () => db.close(),
    );
  });
}
