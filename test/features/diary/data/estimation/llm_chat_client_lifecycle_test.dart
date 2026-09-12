// Regression tests for #419: the estimator's `http.Client` must outlive the
// request it is carrying.
//
// Every screen that estimates reaches its engine with a bare `ref.read` inside
// a button handler and holds no listener, so an autoDispose client provider is
// disposed one frame into the call. `ref.onDispose(client.close)` then closes
// the socket, and closing a client *cancels what it is carrying* —
// `IOClient.close` force-closes it here, `BrowserClient.close` aborts the
// `fetch` in the browser twin. `OpenRouterClient` maps the resulting
// `ClientException` to `offline`, which the sheet words as "אין חיבור
// לאינטרנט" — on a working connection, instantly. The fix is `keepAlive` on
// `llmChatClientProvider`; revert it and the first test here fails.
//
// A spy `HttpClient` under `HttpOverrides` records whether the request was
// attempted. No network is involved.
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
    // Throwing from `openUrl` is how the spy records that the transport was
    // reached: a real network would have answered here instead.
    when(() => spy.openUrl(any(), any()))
        .thenThrow(const SocketException('spy: a request was attempted'));
    when(() => spy.close(force: any(named: 'force'))).thenReturn(null);
  });

  /// A container over a real in-memory store with estimation configured.
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

  /// One full scheduler tick — long enough for riverpod to dispose anything
  /// that spent a frame without a listener.
  Future<void> settle() async {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }

  test('a bare ref.read of the estimator still sends the request', () async {
    await HttpOverrides.runZoned(() async {
      final container = await containerWithKey();

      // Exactly what `AddMealDescriptionSheet._estimate` does: read once,
      // await, hold no listener.
      final estimator = container.read(macroEstimatorProvider);
      await estimator.estimate(description: 'סלט טונה');

      verify(() => spy.openUrl('POST', any())).called(1);
      verifyNever(() => spy.close(force: any(named: 'force')));
    }, createHttpClient: (_) => spy);
  });

  test('losing the last listener does not close the http client', () async {
    await HttpOverrides.runZoned(() async {
      final container = await containerWithKey();

      container.read(llmChatClientProvider);
      await settle();

      verifyNever(() => spy.close(force: any(named: 'force')));
    }, createHttpClient: (_) => spy);
  });

  test('disposing the container closes the http client exactly once', () async {
    await HttpOverrides.runZoned(() async {
      final db = await openTestDatabase();
      final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)],
      );
      addTearDown(() => closeTestDatabase(db));

      container.read(llmChatClientProvider);
      container.dispose();

      // `keepAlive` postpones disposal; it does not cancel it. A container
      // that goes still releases its socket, which is what the provider's
      // own docstring promises a test overriding it can rely on.
      verify(() => spy.close(force: true)).called(1);
    }, createHttpClient: (_) => spy);
  });

  test('a socket failure is still reported as offline', () async {
    await HttpOverrides.runZoned(() async {
      final container = await containerWithKey();

      final result = await container
          .read(macroEstimatorProvider)
          .estimate(description: 'סלט טונה');

      // The fix keeps the client alive; it does not change what a genuine
      // transport failure looks like to the user.
      expect(
        result,
        const EstimateFailed(reason: EstimateFailureReason.offline),
      );
    }, createHttpClient: (_) => spy);
  });
}
