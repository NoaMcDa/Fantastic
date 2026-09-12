// Browser twin of provider_lifecycle_repro_test.dart: real IndexedDB via
// sembast_web, the real BrowserClient, and window.fetch replaced by a stub
// that counts calls and answers 200 — so the only question is whether the
// request is ever made.
@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:fantastic/core/database/database_provider.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sembast_web/sembast_web.dart';
import 'package:web/web.dart' as web;

void main() {
  // The stub is written in JavaScript so it behaves exactly like the
  // browser's fetch: it settles after 300 ms, or rejects with an AbortError
  // the moment its AbortSignal is aborted.
  const stubJs = """
    window.__fetchCalls = 0;
    window.__lastSignal = null;
    window.fetch = function (input, init) {
      window.__fetchCalls++;
      window.__lastSignal = init.signal;
      return new Promise(function (resolve, reject) {
        init.signal.addEventListener('abort', function () {
          reject(new DOMException('The user aborted a request.', 'AbortError'));
        });
        setTimeout(function () {
          resolve(new Response(
            '{"choices":[{"message":{"content":"{}"}}]}',
            { status: 200, headers: { 'content-type': 'application/json' } }
          ));
        }, 300);
      });
    };
  """;

  int fetchCalls() =>
      (globalContext.getProperty('__fetchCalls'.toJS) as JSNumber).toDartInt;
  bool? lastAborted() {
    final signal = globalContext.getProperty('__lastSignal'.toJS);
    return signal.isUndefinedOrNull
        ? null
        : (signal as web.AbortSignal).aborted;
  }

  setUp(() {
    globalContext.callMethod('eval'.toJS, stubJs.toJS);
  });

  Future<ProviderContainer> containerWithKey() async {
    final db = await databaseFactoryWeb.openDatabase(
      'repro_${DateTime.now().microsecondsSinceEpoch}',
    );
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await db.close();
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

  test('shipped path (bare ref.read): offline before the answer arrives, request aborted', () async {
    final container = await containerWithKey();

    final sw = Stopwatch()..start();
    final estimator = container.read(macroEstimatorProvider);
    final result = await estimator.estimate(description: 'סלט טונה');
    sw.stop();

    // ignore: avoid_print
    print(
      'browser shipped path: $result after ${sw.elapsedMilliseconds} ms, '
      'fetch calls: ${fetchCalls()}, request aborted: ${lastAborted()}',
    );
    expect(result, const EstimateFailed(reason: EstimateFailureReason.offline));
    expect(fetchCalls(), 1);
    expect(lastAborted(), isTrue);
    // Reported long before the 300 ms answer could have arrived.
    expect(sw.elapsedMilliseconds, lessThan(250));
  });

  test('provider kept alive: fetch is called and the answer is read', () async {
    final container = await containerWithKey();
    final sub = container.listen(macroEstimatorProvider, (_, _) {});
    addTearDown(sub.close);

    final estimator = container.read(macroEstimatorProvider);
    final result = await estimator.estimate(description: 'סלט טונה');

    // ignore: avoid_print
    print(
      'browser kept alive: $result, fetch calls: ${fetchCalls()}, '
      'request aborted: ${lastAborted()}',
    );
    expect(fetchCalls(), 1);
    expect(lastAborted(), isFalse);
    expect(
      result,
      isNot(const EstimateFailed(reason: EstimateFailureReason.offline)),
    );
  });
}
