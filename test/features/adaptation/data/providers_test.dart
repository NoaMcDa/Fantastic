import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/data/repositories/sembast_streak_repository.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../../../fixtures/fixtures.dart';
import '../../../helpers/test_database.dart';

void main() {
  group('adaptation repository providers', () {
    late Database db;
    late ProviderContainer container;

    setUp(() async {
      db = await openTestDatabase();
      container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(container.dispose);
    });

    tearDown(() async => closeTestDatabase(db));

    test('streakRepositoryProvider resolves to a StreakRepository', () {
      expect(container.read(streakRepositoryProvider), isA<StreakRepository>());
    });

    test('the resolved repository writes to the overridden database', () async {
      await container
          .read(streakRepositoryProvider)
          .save(StreakStateFixture.withStreak(5));

      expect(await streakStateStore.count(db), 1);
    });

    // The stream M3's streakStateProvider (#59) is built on has to survive the
    // trip through the provider, not just through a directly-constructed
    // repository.
    test('watch() on the resolved repository emits immediately', () async {
      final repo = container.read(streakRepositoryProvider);
      await repo.save(StreakStateFixture.withStreak(5));

      expect((await repo.watch().first)!.currentStreak, 5);
    });
  });
}
