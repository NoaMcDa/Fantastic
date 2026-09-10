import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/adaptation/data/repositories/isar_streak_repository.dart';
import 'package:fantastic/features/adaptation/data/schemas/isar_streak_state.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/domain/models/streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../../fixtures/fixtures.dart';
import '../../../helpers/test_isar.dart';

/// The contract every [StreakRepository] implementation must satisfy.
///
/// A top-level function taking a factory rather than a fixed implementation,
/// so any future backing store runs against these same cases — Liskov
/// substitution enforced at the test level.
void runStreakRepositoryContractTests(
  StreakRepository Function() factory, {
  required Future<void> Function() breakStore,
}) {
  late StreakRepository repo;

  setUp(() => repo = factory());

  group('load', () {
    test('returns null on a fresh database', () async {
      expect(await repo.load(), isNull);
    });

    test('returns the saved state', () async {
      final saved = await repo.save(StreakStateFixture.withStreak(12));

      expect(await repo.load(), saved);
    });

    test('returns the most recent save, not the first', () async {
      await repo.save(StreakStateFixture.withStreak(5));
      await repo.save(StreakStateFixture.withStreak(6));

      expect((await repo.load())!.currentStreak, 6);
    });
  });

  group('save', () {
    test('returns a state equal to the one given', () async {
      final original = StreakStateFixture.withStreak(12);

      expect(await repo.save(original), original);
    });

    // The singleton invariant. Anything that appended rather than overwrote
    // would leave a second row here.
    test('twice does not duplicate — one record remains', () async {
      await repo.save(StreakStateFixture.withStreak(5));
      await repo.save(StreakStateFixture.withStreak(6));

      expect(await repo.load(), StreakStateFixture.withStreak(6));
    });

    test('a reset back to the initial state overwrites cleanly', () async {
      // The streak-breach path: a long streak is replaced by zeroes, and the
      // old values must not survive underneath.
      await repo.save(StreakStateFixture.withStreak(30));

      await repo.save(StreakStateFixture.initial());

      expect(await repo.load(), StreakState.initial());
    });
  });

  group('round-trip', () {
    test('a state with a grace period end round-trips', () async {
      final original = StreakStateFixture.inGracePeriod();

      await repo.save(original);

      final loaded = await repo.load();
      expect(loaded, original);
      expect(loaded!.inGracePeriod, isTrue);
      expect(loaded.gracePeriodEnd, StreakStateFixture.defaultGracePeriodEnd);
    });

    test('a state with a null grace period end round-trips', () async {
      await repo.save(StreakStateFixture.withStreak(3));

      final loaded = await repo.load();
      expect(loaded!.gracePeriodEnd, isNull);
      expect(loaded.inGracePeriod, isFalse);
    });

    test('a null lastCompliantDate round-trips', () async {
      await repo.save(StreakStateFixture.initial());

      expect((await repo.load())!.lastCompliantDate, isNull);
    });

    test('highestStreak is kept independently of currentStreak', () async {
      // After a reset the two diverge, and a mapper that dropped one would
      // still pass every fixture where they happen to be equal.
      final original = StreakStateFixture.withStreak(30)
          .copyWith(currentStreak: 0);

      await repo.save(original);

      final loaded = await repo.load();
      expect(loaded!.currentStreak, 0);
      expect(loaded.highestStreak, 30);
    });

    // Catches ordinal drift between AdaptationPhase and AdaptationPhaseIsar,
    // which would silently reinterpret every stored record.
    test('every AdaptationPhase value survives the enum round-trip', () async {
      for (final phase in AdaptationPhase.values) {
        await repo.save(StreakStateFixture.withStreak(10, phase: phase));

        expect(
          (await repo.load())!.phase,
          phase,
          reason: 'phase $phase (ordinal ${phase.index}) did not round-trip',
        );
      }
    });
  });

  group('watch', () {
    test('emits immediately on subscription', () async {
      await repo.save(StreakStateFixture.withStreak(7));

      expect(await repo.watch().first, StreakStateFixture.withStreak(7));
    });

    test('emits null immediately when no record exists', () async {
      expect(await repo.watch().first, isNull);
    });

    test('emits again after a save', () async {
      await repo.save(StreakStateFixture.withStreak(7));

      // Subscribe before writing, so the write is what produces the second
      // event rather than a re-read.
      final emissions = repo.watch().take(2).toList();
      await repo.save(StreakStateFixture.withStreak(8));

      expect(
        (await emissions).map((state) => state?.currentStreak),
        containsAllInOrder([7, 8]),
      );
    });

    test('emits the first record written to an empty database', () async {
      final emissions = repo.watch().take(2).toList();

      await repo.save(StreakStateFixture.withStreak(1));

      expect(
        (await emissions).map((state) => state?.currentStreak),
        containsAllInOrder([null, 1]),
      );
    });

    test('two subscribers each get their own immediate emission', () async {
      await repo.save(StreakStateFixture.withStreak(7));

      expect(await repo.watch().first, isNotNull);
      expect(await repo.watch().first, isNotNull);
    });
  });

  // Every method must surface a storage failure as a typed
  // PersistenceException rather than letting the backing store's own error
  // escape — otherwise `application/` and `presentation/` can only handle a
  // failed write by catching an Isar type, which is the leak the repository
  // abstraction exists to prevent.
  group('failure', () {
    setUp(() async => breakStore());

    test('load throws a PersistenceException', () async {
      await expectLater(repo.load(), throwsA(isA<PersistenceException>()));
    });

    test('save throws a PersistenceException', () async {
      await expectLater(
        repo.save(StreakStateFixture.initial()),
        throwsA(isA<PersistenceException>()),
      );
    });

    // The stream is the case a future-only guard would miss: a closed store
    // throws while the stream is being *built*, before any event, and
    // streakStateProvider (#59) needs that to arrive as AsyncValue.error like
    // any other failure.
    test('watch surfaces the failure on the stream', () async {
      await expectLater(repo.watch(), emitsError(isA<PersistenceException>()));
    });

    test('the failure names the operation and keeps its cause', () async {
      await expectLater(
        repo.load(),
        throwsA(
          isA<PersistenceException>()
              .having(
                (e) => e.message,
                'message',
                contains('StreakRepository.load'),
              )
              .having((e) => e.cause, 'cause', isNotNull),
        ),
      );
    });
  });
}

void main() {
  group('IsarStreakRepository', () {
    late Isar isar;

    setUp(() async => isar = await openTestIsar([IsarStreakStateSchema]));
    tearDown(() async => closeTestIsar(isar));

    runStreakRepositoryContractTests(
      () => IsarStreakRepository(isar),
      breakStore: () => isar.close(),
    );
  });
}
