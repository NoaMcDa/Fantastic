import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/data/repositories/sembast_daily_log_repository.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast/sembast.dart';

import '../../../fixtures/fixtures.dart';
import '../../../helpers/test_database.dart';

void main() {
  group('dashboard repository providers', () {
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

    test('dailyLogRepositoryProvider resolves to a DailyLogRepository', () {
      expect(
        container.read(dailyLogRepositoryProvider),
        isA<DailyLogRepository>(),
      );
    });

    test('the resolved repository writes to the overridden database', () async {
      await container
          .read(dailyLogRepositoryProvider)
          .save(DailyLogFixture.fixture());

      expect(await dailyLogsStore.count(db), 1);
    });
  });
}
