import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/features/onboarding/data/providers.dart';
import 'package:fantastic/features/onboarding/data/repositories/sembast_user_profile_repository.dart';
import 'package:fantastic/features/onboarding/domain/repositories/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../../../fixtures/fixtures.dart';
import '../../../helpers/test_database.dart';

void main() {
  group('onboarding repository providers', () {
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

    test('userProfileRepositoryProvider resolves to the interface', () {
      expect(
        container.read(userProfileRepositoryProvider),
        isA<UserProfileRepository>(),
      );
    });

    test('the resolved repository writes to the overridden database', () async {
      await container
          .read(userProfileRepositoryProvider)
          .save(UserProfileFixture.profile());

      expect(await userProfileStore.count(db), 1);
    });

    test('watch() on the resolved repository emits immediately', () async {
      final repo = container.read(userProfileRepositoryProvider);
      await repo.save(UserProfileFixture.profile(age: 44));

      expect((await repo.watch().first)!.age, 44);
    });
  });
}
