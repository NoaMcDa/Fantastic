// Browser twin of `llm_chat_client_lifecycle_test.dart` (#419).
//
// The VM test proves the request is attempted; this one proves it is allowed
// to *finish*. They are not the same assertion, because `close` cancels
// differently on each transport: `IOClient.close` force-closes the socket, so
// a request that has not started never starts, while `BrowserClient.close`
// calls `abort()` on the `AbortController` of every open `fetch` — a request
// already in flight is torn down mid-answer and rejects with an `AbortError`,
// which `package:http` rewraps as a `ClientException` and `OpenRouterClient`
// reports as `offline`. That is the shape the bug took for the user, who was
// on web.
//
// Real `BrowserClient`, real IndexedDB via `sembast_web`. Only `window.fetch`
// is stubbed, in JavaScript so that it honours its `AbortSignal` exactly as
// the browser's own does.
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
  // 300 ms is the point: long enough to outlast the frame riverpod would have
  // disposed the client on, short enough not to slow the suite. A real
  // OpenRouter answer takes 8–12 s (#414).
  const answerDelayMs = 300;

  const stubJs =
      '''
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
        }, $answerDelayMs);
      });
    };
  ''';

  int fetchCalls() =>
      (globalContext.getProperty('__fetchCalls'.toJS) as JSNumber).toDartInt;

  bool? lastAborted() {
    final signal = globalContext.getProperty('__lastSignal'.toJS);
    return signal.isUndefinedOrNull
        ? null
        : (signal as web.AbortSignal).aborted;
  }

  setUp(() => globalContext.callMethod('eval'.toJS, stubJs.toJS));

  Future<ProviderContainer> containerWithKey() async {
    final db = await databaseFactoryWeb.openDatabase(
      'llm_lifecycle_${DateTime.now().microsecondsSinceEpoch}',
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

  test('a bare ref.read of the estimator: fetch runs to completion', () async {
    final container = await containerWithKey();

    final stopwatch = Stopwatch()..start();
    // Exactly what `AddMealDescriptionSheet._estimate` does.
    final result = await container
        .read(macroEstimatorProvider)
        .estimate(description: 'סלט טונה');
    stopwatch.stop();

    expect(fetchCalls(), 1);
    expect(lastAborted(), isFalse);
    // The whole round trip was waited out rather than cut short one frame in.
    expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(answerDelayMs));
    // The stub's `{}` body has no items, so this is a parse failure rather
    // than a success — the assertion is about the transport, not the parser.
    // `offline` is what the aborted request produced, and is what must not
    // come back.
    expect(
      result,
      isNot(const EstimateFailed(reason: EstimateFailureReason.offline)),
    );
  });
}
