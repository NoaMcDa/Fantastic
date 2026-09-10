import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_meal_repository.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_symptom_log_repository.dart';
import 'package:fantastic/features/diary/domain/repositories/meal_repository.dart';
import 'package:fantastic/features/diary/domain/repositories/symptom_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../../../fixtures/fixtures.dart';
import '../../../helpers/test_database.dart';

void main() {
  group('diary repository providers', () {
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

    test('mealRepositoryProvider resolves to a MealRepository', () {
      expect(container.read(mealRepositoryProvider), isA<MealRepository>());
    });

    test('symptomLogRepositoryProvider resolves to a SymptomLogRepository', () {
      expect(
        container.read(symptomLogRepositoryProvider),
        isA<SymptomLogRepository>(),
      );
    });

    // Not a redundant type check: this proves the provider handed the
    // repository the *overridden* database rather than opening one of its own,
    // which an isA<> assertion alone cannot distinguish.
    test('the resolved repository writes to the overridden database', () async {
      await container
          .read(mealRepositoryProvider)
          .save(MealEntryFixture.fixture());

      expect(await mealsStore.count(db), 1);
    });

    test('both providers share the one overridden database', () async {
      await container
          .read(mealRepositoryProvider)
          .save(MealEntryFixture.fixture());
      await container
          .read(symptomLogRepositoryProvider)
          .save(SymptomLogFixture.fixture());

      expect(await mealsStore.count(db), 1);
      expect(await symptomLogsStore.count(db), 1);
    });
  });

  test('reading a repository provider without overriding databaseProvider '
      'throws the descriptive UnimplementedError', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // The intended fail-fast from #21 — a missing override must not surface as
    // a null dereference somewhere deeper. riverpod 3 wraps the error in its
    // own non-exported ProviderException, so assert on toString().
    expect(
      () => container.read(mealRepositoryProvider),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'toString()',
          contains('databaseProvider must be overridden at app root'),
        ),
      ),
    );
  });
}
