import 'package:fantastic/core/database/isar_provider.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/data/schemas/isar_meal_entry.dart';
import 'package:fantastic/features/diary/data/schemas/isar_symptom_log.dart';
import 'package:fantastic/features/diary/domain/repositories/meal_repository.dart';
import 'package:fantastic/features/diary/domain/repositories/symptom_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../../fixtures/fixtures.dart';
import '../../../helpers/test_isar.dart';

void main() {
  group('diary repository providers', () {
    late Isar isar;
    late ProviderContainer container;

    setUp(() async {
      isar = await openTestIsar([IsarMealEntrySchema, IsarSymptomLogSchema]);
      container = ProviderContainer(
        overrides: [isarProvider.overrideWithValue(isar)],
      );
      addTearDown(container.dispose);
    });

    tearDown(() async => closeTestIsar(isar));

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
    // repository the *overridden* instance rather than opening one of its own,
    // which an isA<> assertion alone cannot distinguish.
    test('the resolved repository writes to the overridden instance', () async {
      await container
          .read(mealRepositoryProvider)
          .save(MealEntryFixture.fixture());

      expect(await isar.isarMealEntrys.count(), 1);
    });

    test('both providers share the one overridden instance', () async {
      await container
          .read(mealRepositoryProvider)
          .save(MealEntryFixture.fixture());
      await container
          .read(symptomLogRepositoryProvider)
          .save(SymptomLogFixture.fixture());

      expect(await isar.isarMealEntrys.count(), 1);
      expect(await isar.isarSymptomLogs.count(), 1);
    });
  });

  test('reading a repository provider without overriding isarProvider throws '
      'the descriptive UnimplementedError', () {
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
          contains('isarProvider must be overridden at app root'),
        ),
      ),
    );
  });
}
