// Reproduction for the "אין חיבור לאינטרנט" report: does the estimator's
// HTTP client survive until the request is sent? A spy HttpClient records
// whether a request was ever attempted — no network is involved.
import 'dart:io';

import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_database.dart';

class _SpyHttpClient extends Mock implements HttpClient {}

void main() {
  late _SpyHttpClient spy;

  setUpAll(() => registerFallbackValue(Uri.parse('https://example.invalid')));

  setUp(() {
    spy = _SpyHttpClient();
    when(() => spy.openUrl(any(), any()))
        .thenThrow(const SocketException('spy: a request was attempted'));
    when(() => spy.close(force: any(named: 'force'))).thenReturn(null);
  });

  Future<ProviderContainer> containerWithKey() async {
    final db = await openTestDatabase();
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await closeTestDatabase(db);
    });
    await container
        .read(estimationSettingsRepositoryProvider)
        .save(
          const EstimationSettings(
            apiKey: 'sk-or-v1-test',
            consentAccepted: true,
          ),
        );
    return container;
  }

  test('shipped path (bare ref.read): reports offline without attempting a request', () async {
    await HttpOverrides.runZoned(() async {
      final container = await containerWithKey();

      final sw = Stopwatch()..start();
      // Exactly what AddMealDescriptionSheet._estimate does.
      final estimator = container.read(macroEstimatorProvider);
      final result = await estimator.estimate(description: 'סלט טונה');
      sw.stop();

      // ignore: avoid_print
      print('shipped path: $result after ${sw.elapsedMilliseconds} ms');
      expect(
        result,
        const EstimateFailed(reason: EstimateFailureReason.offline),
      );
      // The transport was never reached: the socket spy was never opened,
      // and the client had already been closed by the provider's onDispose.
      verifyNever(() => spy.openUrl(any(), any()));
      verify(() => spy.close(force: true)).called(1);
    }, createHttpClient: (_) => spy);
  });

  test(
    'same call with the provider kept alive: the request is attempted',
    () async {
      await HttpOverrides.runZoned(() async {
        final container = await containerWithKey();
        final sub = container.listen(macroEstimatorProvider, (_, _) {});
        addTearDown(sub.close);

        final estimator = container.read(macroEstimatorProvider);
        final result = await estimator.estimate(description: 'סלט טונה');

        // Still offline — the spy throws a SocketException — but this time the
        // request reached the socket layer, which is where a real network
        // would have answered.
        expect(
          result,
          const EstimateFailed(reason: EstimateFailureReason.offline),
        );
        verify(() => spy.openUrl('POST', any())).called(1);
        verifyNever(() => spy.close(force: any(named: 'force')));
      }, createHttpClient: (_) => spy);
    },
  );
}
