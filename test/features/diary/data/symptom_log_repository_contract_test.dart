import 'package:fantastic/features/diary/data/repositories/isar_symptom_log_repository.dart';
import 'package:fantastic/features/diary/data/schemas/isar_symptom_log.dart';
import 'package:fantastic/features/diary/domain/repositories/symptom_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../../fixtures/fixtures.dart';
import '../../../helpers/test_isar.dart';

/// The contract every [SymptomLogRepository] implementation must satisfy.
///
/// A top-level function taking a factory rather than a fixed implementation,
/// so any future backing store runs against these same cases — Liskov
/// substitution enforced at the test level.
void runSymptomLogRepositoryContractTests(
  SymptomLogRepository Function() factory,
) {
  late SymptomLogRepository repo;

  setUp(() => repo = factory());

  group('save', () {
    test('returns a log with a non-null id', () async {
      final saved = await repo.save(SymptomLogFixture.fixture());

      expect(saved.id, isNotNull);
    });

    test('the saved log is retrievable by its date', () async {
      final saved = await repo.save(SymptomLogFixture.fixture());

      expect(await repo.findByDate(SymptomLogFixture.defaultDate), saved);
    });

    test('preserves every field apart from the assigned id', () async {
      final original = SymptomLogFixture.worstDay();

      final saved = await repo.save(original);

      expect(saved, original.copyWith(id: saved.id));
    });

    // The one-record-per-day guarantee. A plain `put` here would either
    // violate the unique index and throw, or leave two rows for one day.
    test('twice for the same date updates rather than duplicating', () async {
      await repo.save(SymptomLogFixture.fixture(energyScore: 2));

      await repo.save(SymptomLogFixture.fixture(energyScore: 5));

      expect(await repo.findAll(), hasLength(1));
      expect(
        (await repo.findByDate(SymptomLogFixture.defaultDate))!.energyScore,
        5,
      );
    });

    test('the second save for a date reuses the first row id', () async {
      final first = await repo.save(SymptomLogFixture.fixture(energyScore: 2));

      final second = await repo.save(SymptomLogFixture.fixture(energyScore: 5));

      expect(second.id, first.id);
    });

    test('two different dates each get their own record', () async {
      await repo.save(SymptomLogFixture.fixture(date: DateTime(2026, 9, 9)));
      await repo.save(SymptomLogFixture.fixture(date: DateTime(2026, 9, 10)));

      expect(await repo.findAll(), hasLength(2));
    });
  });

  group('findByDate', () {
    test('returns null when no record exists', () async {
      expect(await repo.findByDate(SymptomLogFixture.defaultDate), isNull);
    });

    test('returns null for a date other than the one stored', () async {
      await repo.save(SymptomLogFixture.fixture(date: DateTime(2026, 9, 9)));

      expect(await repo.findByDate(DateTime(2026, 9, 10)), isNull);
    });

    test('matches on the calendar day, ignoring the time of day', () async {
      await repo.save(SymptomLogFixture.fixture(date: DateTime(2026, 9, 9)));

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
        SymptomLogFixture.fixture(date: DateTime(2026, 9, 7)),
      );
      final newest = await repo.save(
        SymptomLogFixture.fixture(date: DateTime(2026, 9, 9)),
      );
      final middle = await repo.save(
        SymptomLogFixture.fixture(date: DateTime(2026, 9, 8)),
      );

      expect(await repo.findAll(), [newest, middle, oldest]);
    });

    test('orders correctly across a year boundary', () async {
      final earlier = await repo.save(
        SymptomLogFixture.fixture(date: DateTime(2026, 12, 31)),
      );
      final later = await repo.save(
        SymptomLogFixture.fixture(date: DateTime(2027, 1, 1)),
      );

      expect(await repo.findAll(), [later, earlier]);
    });
  });

  group('deleteByDate', () {
    test('removes the record', () async {
      await repo.save(SymptomLogFixture.fixture());

      await repo.deleteByDate(SymptomLogFixture.defaultDate);

      expect(await repo.findByDate(SymptomLogFixture.defaultDate), isNull);
      expect(await repo.findAll(), isEmpty);
    });

    test('is idempotent for an unknown date', () async {
      await expectLater(repo.deleteByDate(DateTime(2026, 1, 1)), completes);
    });

    test('deleting one date leaves the others intact', () async {
      final kept = await repo.save(
        SymptomLogFixture.fixture(date: DateTime(2026, 9, 9)),
      );
      await repo.save(SymptomLogFixture.fixture(date: DateTime(2026, 9, 10)));

      await repo.deleteByDate(DateTime(2026, 9, 10));

      expect(await repo.findAll(), [kept]);
    });

    test('the date is reusable after a delete', () async {
      await repo.save(SymptomLogFixture.fixture(energyScore: 1));
      await repo.deleteByDate(SymptomLogFixture.defaultDate);

      final resaved = await repo.save(
        SymptomLogFixture.fixture(energyScore: 5),
      );

      expect(resaved.energyScore, 5);
      expect(await repo.findAll(), hasLength(1));
    });
  });

  group('round-trip', () {
    test('all five scores survive a save/find round-trip', () async {
      // Five distinct values, so a repository that crossed two scales cannot
      // pass by coincidence the way an all-3s fixture lets it.
      await repo.save(
        SymptomLogFixture.fixture(
          energyScore: 1,
          clarityScore: 2,
          hungerScore: 3,
          physicalScore: 4,
          moodScore: 5,
        ),
      );

      final found = await repo.findByDate(SymptomLogFixture.defaultDate);

      expect(found!.energyScore, 1);
      expect(found.clarityScore, 2);
      expect(found.hungerScore, 3);
      expect(found.physicalScore, 4);
      expect(found.moodScore, 5);
    });

    test('notes survive a save/find round-trip', () async {
      await repo.save(SymptomLogFixture.worstDay());

      expect(
        (await repo.findByDate(SymptomLogFixture.defaultDate))!.notes,
        'keto flu',
      );
    });

    test('a null notes field round-trips as null', () async {
      await repo.save(SymptomLogFixture.fixture());

      expect(
        (await repo.findByDate(SymptomLogFixture.defaultDate))!.notes,
        isNull,
      );
    });

    test('boundary scores of 1 and 5 both round-trip', () async {
      await repo.save(SymptomLogFixture.worstDay(date: DateTime(2026, 9, 9)));
      await repo.save(SymptomLogFixture.bestDay(date: DateTime(2026, 9, 10)));

      expect((await repo.findByDate(DateTime(2026, 9, 9)))!.energyScore, 1);
      expect((await repo.findByDate(DateTime(2026, 9, 10)))!.energyScore, 5);
    });

    test('the date round-trips exactly, time of day included', () async {
      final date = DateTime(2026, 9, 9, 21, 30);

      final saved = await repo.save(SymptomLogFixture.fixture(date: date));

      expect(saved.date, date);
      expect((await repo.findByDate(date))!.date, date);
    });
  });
}

void main() {
  group('IsarSymptomLogRepository', () {
    late Isar isar;

    setUp(() async => isar = await openTestIsar([IsarSymptomLogSchema]));
    tearDown(() async => closeTestIsar(isar));

    runSymptomLogRepositoryContractTests(() => IsarSymptomLogRepository(isar));
  });
}
