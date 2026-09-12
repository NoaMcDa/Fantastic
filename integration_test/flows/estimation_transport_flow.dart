// The composition root, end to end (#425).
//
// **What this flow guards, and what it does not.**
//
// Every other test of estimation replaces something. `open_router_client_test.dart`
// builds `OpenRouterClient` by hand with a `MockClient`, and both add-meal flows
// override `macroEstimatorProvider` with a fake — correctly, because they are
// about the review sheet. The consequence is that nothing drove a real screen
// through the real provider graph down to the transport, which is precisely the
// seam #419 broke: `llmChatClientProvider` was autoDispose, every estimating
// screen reads its engine with a bare `ref.read` and so holds no listener, and
// riverpod closed the `http.Client` one frame into the request. Closing a client
// cancels what it is carrying, and the user saw "אין חיבור לאינטרנט" on a working
// connection.
//
// So this flow overrides **only** the database and the `dart:io` HTTP layer.
// The router, the sheet, the widget's own `ref.read`, riverpod's disposal
// timing, `UserApiKeyCredentials`, `OpenRouterClient` and the parser are all the
// shipped objects.
//
// **The discriminating assertion is `close` was never called**, not that the
// user saw a review. Mocking `HttpClient` makes `close()` a no-op, so the
// request completes either way and the review renders even with the bug
// reintroduced — a real socket close would have killed it. Measured, by
// reverting the fix and re-running:
//
// | `llmChatClientProvider` | `client.close` calls during the request |
// |---|---|
// | `@Riverpod(keepAlive: true)` (shipped) | 0 |
// | `@riverpod` (the #419 bug)             | 1 |
//
// The *consequence* — that the user gets an answer rather than an offline chip —
// is guarded by `llm_chat_client_lifecycle_test.dart` and its browser twin,
// which use transports whose `close` really does cancel. Do not "strengthen"
// this flow into an outcome-only assertion: that yields a test which passes
// under the bug.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/app_harness.dart';

class _MockHttpClient extends Mock implements HttpClient {}

class _MockRequest extends Mock implements HttpClientRequest {}

class _MockHeaders extends Mock implements HttpHeaders {}

/// A real [Stream] that also answers as an [HttpClientResponse].
///
/// **Not a `Mock`, deliberately.** `IOClient` calls Stream combinators on the
/// response — not just `listen` — and a bare `Mock` returns null from those, so
/// the body never arrives and `OpenRouterClient` reports `badResponse`. The
/// sheet then shows `ההערכה נכשלה` and the transport looks broken when it is the
/// double that is. Extending `Stream` gives every combinator its real
/// implementation.
class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  _FakeResponse(this._bytes, this._headers);

  final List<int> _bytes;
  final HttpHeaders _headers;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.fromIterable([_bytes]).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  int get statusCode => 200;

  @override
  String get reasonPhrase => 'OK';

  @override
  HttpHeaders get headers => _headers;

  @override
  int get contentLength => _bytes.length;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  List<Cookie> get cookies => const [];

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  X509Certificate? get certificate => null;

  @override
  HttpConnectionInfo? get connectionInfo => null;

  // Neither is reachable on this path: the stub never redirects and
  // `OpenRouterClient` reads a body rather than upgrading the connection.
  // They throw rather than returning a plausible value so that a future
  // change which does reach them fails loudly instead of silently.
  @override
  Future<Socket> detachSocket() =>
      throw UnsupportedError('the stubbed response has no socket');

  @override
  Future<HttpClientResponse> redirect([
    String? method,
    Uri? url,
    bool? followLoops,
  ]) => throw UnsupportedError('the stubbed response never redirects');
}

/// The estimator's own reply schema, inside an OpenRouter envelope.
const String _content =
    '{"items":[{"name":"סלט טונה","grams":200,"fat_g":18.0,'
    '"net_carbs_g":4.0,"protein_g":25.0}],"unidentified":[]}';

/// Long enough to outlive the frame an autoDispose client would be disposed on.
///
/// A response that resolves synchronously would never reach the disposal, so
/// the flow would pass under the bug. A real answer takes 8–12 s (#414).
const Duration _answerDelay = Duration(milliseconds: 300);

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.invalid'));
    registerFallbackValue(const Stream<List<int>>.empty());
  });

  testWidgets('the client is not closed while a request is in flight', (
    tester,
  ) async {
    final bytes = utf8.encode(
      jsonEncode({
        'choices': [
          {
            'message': {'content': _content},
          },
        ],
      }),
    );

    final client = _MockHttpClient();
    final request = _MockRequest();
    final headers = _MockHeaders();
    final response = _FakeResponse(bytes, headers);

    when(() => request.headers).thenReturn(headers);
    when(() => headers.set(any(), any())).thenReturn(null);
    when(() => headers.contentType).thenReturn(ContentType.json);
    when(() => request.add(any())).thenReturn(null);
    // `Stream.pipe` is `addStream(...).then((_) => close())`, so an unstubbed
    // `addStream` returns null, the `.then` throws, and the failure arrives
    // as `badResponse` — nowhere near where it was caused.
    when(() => request.addStream(any())).thenAnswer(
      (invocation) async =>
          (invocation.positionalArguments[0] as Stream<List<int>>)
              .drain<void>(),
    );
    when(() => request.close()).thenAnswer((_) async {
      await Future<void>.delayed(_answerDelay);
      return response;
    });
    when(() => client.openUrl(any(), any())).thenAnswer((_) async => request);
    when(() => client.close(force: any(named: 'force'))).thenReturn(null);

    await HttpOverrides.runZoned(() async {
      // **No estimator override.** That is the whole point of this flow.
      final app = await bootApp(onboarded: true);
      // The user's own key, stored the way the Profile screen stores it.
      await app.container
          .read(estimationSettingsRepositoryProvider)
          .save(
            const EstimationSettings(
              apiKey: 'sk-or-v1-test',
              consentAccepted: true,
            ),
          );
      await pumpApp(tester, app);

      await openAddMeal(tester, mode: 'add_meal_mode_description');
      await enterInto(tester, 'meal_description_field', 'סלט טונה');
      await tapAt(tester, find.byKey(const Key('estimate_button')));

      // Either outcome ends the spinner; which one arrives is the test.
      await waitFor(
        tester,
        () async =>
            find
                .byKey(const Key('estimate_review_list'))
                .evaluate()
                .isNotEmpty ||
            find.byKey(const Key('estimate_failure')).evaluate().isNotEmpty,
        timeout: const Duration(seconds: 15),
        reason: 'the estimate never resolved either way',
      );

      // **The regression guard.** Revert #419 and this records one call.
      verifyNever(() => client.close(force: any(named: 'force')));

      // The real composition root reached the real transport.
      verify(() => client.openUrl('POST', any())).called(1);

      // The user-visible outcome. Worth asserting, but note these two pass
      // under the bug as well — see this file's header.
      expect(find.text(AddMealCopy.failedOffline), findsNothing);
      expect(find.byKey(const Key('estimate_review_list')), findsOneWidget);
      expect(find.textContaining('סלט טונה'), findsWidgets);
    }, createHttpClient: (_) => client);
  });
}
