import 'package:fantastic/core/database/isar_provider.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/dashboard/data/schemas/isar_daily_log.dart';
import 'package:fantastic/features/dashboard/domain/repositories/daily_log_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../../fixtures/fixtures.dart';
import '../../../helpers/test_isar.dart';

void main() {
  group('dashboard repository providers', () {
    late Isar isar;
    late ProviderContainer container;

    setUp(() async {
      isar = await openTestIsar([IsarDailyLogSchema]);
      container = ProviderContainer(
        overrides: [isarProvider.overrideWithValue(isar)],
      );
      addTearDown(container.dispose);
    });

    tearDown(() async => closeTestIsar(isar));

    test('dailyLogRepositoryProvider resolves to a DailyLogRepository', () {
      expect(
        container.read(dailyLogRepositoryProvider),
        isA<DailyLogRepository>(),
      );
    });

    test('the resolved repository writes to the overridden instance', () async {
      await container
          .read(dailyLogRepositoryProvider)
          .save(DailyLogFixture.fixture());

      expect(await isar.isarDailyLogs.count(), 1);
    });
  });
}
