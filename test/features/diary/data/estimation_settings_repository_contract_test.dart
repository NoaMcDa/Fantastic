import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/data/repositories/sembast_estimation_settings_repository.dart';
import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';
import 'package:fantastic/features/diary/domain/repositories/estimation_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../../../helpers/test_database.dart';

/// The contract every [EstimationSettingsRepository] implementation must
/// satisfy.
///
/// A top-level function taking a factory rather than a fixed implementation:
/// any future backing store is run against these same cases, which is what
/// enforces Liskov substitution at the test level.
void runEstimationSettingsRepositoryContractTests(
  EstimationSettingsRepository Function() factory, {
  required Future<void> Function() breakStore,
}) {
  late EstimationSettingsRepository repo;

  setUp(() => repo = factory());

  group('load', () {
    // Absence carries no meaning here, unlike the user profile record — so the
    // repository answers with defaults rather than pushing a null check into
    // every caller.
    test('a fresh database returns defaults, not null', () async {
      final settings = await repo.load();

      expect(settings.apiKey, isNull);
      expect(settings.consentAccepted, isFalse);
      expect(settings.isEnabled, isFalse);
    });
  });

  group('save', () {
    test('returns what it wrote', () async {
      const settings = EstimationSettings(
        apiKey: 'sk-test',
        consentAccepted: true,
      );

      expect(await repo.save(settings), settings);
    });

    test('a saved value survives a reload', () async {
      await repo.save(
        const EstimationSettings(apiKey: 'sk-test', consentAccepted: true),
      );

      final loaded = await repo.load();

      expect(loaded.apiKey, 'sk-test');
      expect(loaded.consentAccepted, isTrue);
      expect(loaded.isEnabled, isTrue);
    });

    // The singleton record is addressed by a fixed key, so a second write
    // replaces the first rather than appending.
    test('a second save replaces the first', () async {
      await repo.save(const EstimationSettings(apiKey: 'first'));
      await repo.save(const EstimationSettings(apiKey: 'second'));

      expect((await repo.load()).apiKey, 'second');
    });

    test(
      'clearing the key persists as absent, not as an empty string',
      () async {
        await repo.save(
          const EstimationSettings(apiKey: 'sk-test', consentAccepted: true),
        );

        await repo.save((await repo.load()).withoutApiKey());

        final loaded = await repo.load();
        expect(loaded.apiKey, isNull);
        // Consent is a separate fact and survives the key being removed.
        expect(loaded.consentAccepted, isTrue);
      },
    );
  });

  // Every method must surface a storage failure as a typed
  // PersistenceException rather than letting the backing store's own error
  // escape.
  group('failure', () {
    test('load surfaces a storage failure as PersistenceException', () async {
      await breakStore();

      expect(repo.load, throwsA(isA<PersistenceException>()));
    });

    test('save surfaces a storage failure as PersistenceException', () async {
      await breakStore();

      expect(
        () => repo.save(const EstimationSettings(apiKey: 'sk-test')),
        throwsA(isA<PersistenceException>()),
      );
    });

    // Epic #312's invariant: no API key is logged, printed, or included in any
    // exception or failure value.
    test('a failure never carries the key it was given', () async {
      await breakStore();

      try {
        await repo.save(const EstimationSettings(apiKey: 'sk-super-secret'));
        fail('expected a PersistenceException');
      } on PersistenceException catch (error) {
        expect(error.toString(), isNot(contains('sk-super-secret')));
      }
    });
  });
}

void main() {
  group('SembastEstimationSettingsRepository', () {
    late Database db;

    setUp(() async => db = await openTestDatabase());
    tearDown(() async => closeTestDatabase(db));

    runEstimationSettingsRepositoryContractTests(
      () => SembastEstimationSettingsRepository(db),
      // Closing the database makes every store access throw
      // `DatabaseException.closed()`, which is a real storage failure from
      // inside the repository rather than a stubbed one.
      breakStore: () => db.close(),
    );
  });
}
