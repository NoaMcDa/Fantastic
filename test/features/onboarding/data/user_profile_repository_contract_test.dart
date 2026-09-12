import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/onboarding/data/repositories/sembast_user_profile_repository.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:fantastic/features/onboarding/domain/models/keto_goal.dart';
import 'package:fantastic/features/onboarding/domain/repositories/user_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../../../fixtures/fixtures.dart';
import '../../../helpers/test_database.dart';

/// The contract every [UserProfileRepository] implementation must satisfy.
///
/// A top-level function taking a factory rather than a fixed implementation,
/// so any future backing store runs against these same cases — Liskov
/// substitution enforced at the test level.
void runUserProfileRepositoryContractTests(
  UserProfileRepository Function() factory, {
  required Future<void> Function() breakStore,
}) {
  late UserProfileRepository repo;

  setUp(() => repo = factory());

  group('load', () {
    // The whole first-launch gate rests on this one value. If a fresh
    // database ever returned a profile, onboarding would be skipped on a new
    // install and the user would be measured against targets they never set.
    test('returns null on a fresh database', () async {
      expect(await repo.load(), isNull);
    });

    test('returns the saved profile', () async {
      final saved = await repo.save(UserProfileFixture.profile());

      expect(await repo.load(), saved);
    });

    test('returns the most recent save, not the first', () async {
      await repo.save(UserProfileFixture.profile(age: 30));
      await repo.save(UserProfileFixture.profile(age: 31));

      expect((await repo.load())!.age, 31);
    });
  });

  group('save', () {
    test('returns a profile equal to the one given', () async {
      final original = UserProfileFixture.profile(
        ketoStartDate: UserProfileFixture.defaultKetoStartDate,
      );

      expect(await repo.save(original), original);
    });

    // The singleton invariant. Anything that appended rather than overwrote
    // would leave a second row here, and `load` would start returning
    // whichever one the store happened to hand back first.
    test('twice does not duplicate — one record remains', () async {
      await repo.save(UserProfileFixture.profile(age: 30));
      await repo.save(UserProfileFixture.profile(age: 31));

      expect(await repo.load(), UserProfileFixture.profile(age: 31));
    });

    test('re-editing the targets overwrites cleanly', () async {
      await repo.save(
        UserProfileFixture.profile(targets: UserProfileFixture.targets()),
      );

      await repo.save(
        UserProfileFixture.profile(
          targets: UserProfileFixture.targets(fatG: 210, proteinG: 90),
        ),
      );

      final loaded = await repo.load();
      expect(loaded!.targets.fatG, 210);
      expect(loaded.targets.proteinG, 90);
    });
  });

  group('round-trip', () {
    test('a profile with a keto start date round-trips', () async {
      final original = UserProfileFixture.profile(
        ketoStartDate: UserProfileFixture.defaultKetoStartDate,
      );

      await repo.save(original);

      final loaded = await repo.load();
      expect(loaded, original);
      expect(loaded!.ketoStartDate, UserProfileFixture.defaultKetoStartDate);
    });

    test('a null keto start date round-trips as null', () async {
      await repo.save(UserProfileFixture.profile());

      expect((await repo.load())!.ketoStartDate, isNull);
    });

    test('every BiologicalSex value survives the enum round-trip', () async {
      for (final sex in BiologicalSex.values) {
        await repo.save(UserProfileFixture.profile(sex: sex));

        expect((await repo.load())!.sex, sex, reason: 'sex $sex');
      }
    });

    test('every KetoGoal value survives the enum round-trip', () async {
      for (final goal in KetoGoal.values) {
        await repo.save(UserProfileFixture.profile(goals: {goal}));

        expect((await repo.load())!.goals, {goal}, reason: 'goal ${goal.name}');
      }
    });
  });

  group('watch', () {
    test('emits immediately on subscription', () async {
      final saved = await repo.save(UserProfileFixture.profile());

      expect(await repo.watch().first, saved);
    });

    // What `macroTargetsProvider` depends on to fall back to the defaults
    // rather than sit in loading forever on a fresh install.
    test('emits null immediately when no record exists', () async {
      expect(await repo.watch().first, isNull);
    });

    test('emits again after a save', () async {
      await repo.save(UserProfileFixture.profile(age: 30));

      // Subscribe before writing, so the write is what produces the second
      // event rather than a re-read.
      final emissions = repo.watch().take(2).toList();
      await repo.save(UserProfileFixture.profile(age: 31));

      expect(
        (await emissions).map((profile) => profile?.age),
        containsAllInOrder([30, 31]),
      );
    });

    // The dashboard is already listening when screen 4 saves; this is what
    // repaints its macro bars with the new targets.
    test('emits the first record written to an empty database', () async {
      final emissions = repo.watch().take(2).toList();

      await repo.save(UserProfileFixture.profile(age: 31));

      expect(
        (await emissions).map((profile) => profile?.age),
        containsAllInOrder([null, 31]),
      );
    });
  });

  // Every method must surface a storage failure as a typed
  // PersistenceException rather than letting the backing store's own error
  // escape — otherwise `application/` and `presentation/` can only handle a
  // failed write by catching a sembast type, which is the leak the
  // repository abstraction exists to prevent.
  group('failure', () {
    setUp(() async => breakStore());

    test('load throws a PersistenceException', () async {
      await expectLater(repo.load(), throwsA(isA<PersistenceException>()));
    });

    test('save throws a PersistenceException', () async {
      await expectLater(
        repo.save(UserProfileFixture.profile()),
        throwsA(isA<PersistenceException>()),
      );
    });

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
                contains('UserProfileRepository.load'),
              )
              .having((e) => e.cause, 'cause', isNotNull),
        ),
      );
    });
  });
}

void main() {
  group('SembastUserProfileRepository', () {
    late Database db;

    setUp(() async => db = await openTestDatabase());
    tearDown(() async => closeTestDatabase(db));

    runUserProfileRepositoryContractTests(
      () => SembastUserProfileRepository(db),
      // Closing the database makes every store access throw
      // `DatabaseException.closed()`, which is a real storage failure from
      // inside the repository rather than a stubbed one.
      breakStore: () => db.close(),
    );
  });
}
