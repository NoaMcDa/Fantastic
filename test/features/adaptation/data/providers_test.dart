import 'package:fantastic/core/database/isar_provider.dart';
import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/data/schemas/isar_streak_state.dart';
import 'package:fantastic/features/adaptation/domain/repositories/streak_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../../fixtures/fixtures.dart';
import '../../../helpers/test_isar.dart';

void main() {
  group('adaptation repository providers', () {
    late Isar isar;
    late ProviderContainer container;

    setUp(() async {
      isar = await openTestIsar([IsarStreakStateSchema]);
      container = ProviderContainer(
        overrides: [isarProvider.overrideWithValue(isar)],
      );
      addTearDown(container.dispose);
    });

    tearDown(() async => closeTestIsar(isar));

    test('streakRepositoryProvider resolves to a StreakRepository', () {
      expect(container.read(streakRepositoryProvider), isA<StreakRepository>());
    });

    test('the resolved repository writes to the overridden instance', () async {
      await container
          .read(streakRepositoryProvider)
          .save(StreakStateFixture.withStreak(5));

      expect(await isar.isarStreakStates.count(), 1);
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
