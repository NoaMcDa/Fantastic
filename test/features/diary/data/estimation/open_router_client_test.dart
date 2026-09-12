import 'dart:async';
import 'dart:convert';

import 'package:fantastic/core/llm/llm_chat_client.dart';
import 'package:fantastic/features/diary/data/estimation/estimation_credentials.dart';
import 'package:fantastic/features/diary/data/estimation/open_router_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A fixed token, so a test can search every produced value for it.
const _token = 'sk-or-v1-SECRET-DO-NOT-LEAK';

class _FixedCredentials implements EstimationCredentials {
  const _FixedCredentials(this._token);
  final String? _token;

  @override
  Future<String?> token() async => _token;
}

void main() {
  /// A well-formed OpenAI-compatible body carrying [content].
  String okBody(String content) => jsonEncode({
    'choices': [
      {
        'message': {'role': 'assistant', 'content': content},
      },
    ],
  });

  /// The request the client sent, captured.
  late List<http.Request> sent;

  setUp(() => sent = []);

  /// A client whose transport answers with [respond].
  ///
  /// **No test in this suite makes a real network request.** `MockClient`
  /// answers from a function, so every status code is reachable offline —
  /// which is also the only way the socket-failure branch is testable at all.
  OpenRouterClient clientThat(
    FutureOr<http.Response> Function(http.Request) respond, {
    String? token = _token,
    String? model,
    Duration? timeout,
  }) => OpenRouterClient(
    httpClient: MockClient((request) async {
      sent.add(request);
      return respond(request);
    }),
    credentials: _FixedCredentials(token),
    model: model ?? OpenRouterClient.defaultModel,
    timeout: timeout ?? OpenRouterClient.defaultTimeout,
  );

  Future<ChatResult> complete(
    OpenRouterClient client, {
    String? imageBase64,
    String? imageMediaType,
  }) => client.complete(
    systemPrompt: 'system',
    userPrompt: 'סלט טונה',
    imageBase64: imageBase64,
    imageMediaType: imageMediaType,
  );

  Map<String, Object?> bodyOf(http.Request request) =>
      jsonDecode(request.body) as Map<String, Object?>;

  group('a successful round trip', () {
    test('returns ChatSucceeded carrying the content string', () async {
      final client = clientThat((_) => http.Response(okBody('{"a":1}'), 200));

      expect(await complete(client), const ChatSucceeded('{"a":1}'));
    });

    test(
      'pins the model, sets temperature 0 and asks for a JSON object',
      () async {
        final client = clientThat((_) => http.Response(okBody('{}'), 200));
        await complete(client);

        final body = bodyOf(sent.single);
        expect(body['model'], OpenRouterClient.defaultModel);
        // The daily net-carb budget is 20 g. A sampled answer would move a
        // meaningful fraction of it at random, so the same meal typed twice
        // must not produce two different carb counts.
        expect(body['temperature'], 0);
        expect(body['response_format'], {'type': 'json_object'});
      },
    );

    test('carries a Bearer header built from the credentials', () async {
      final client = clientThat((_) => http.Response(okBody('{}'), 200));
      await complete(client);

      expect(sent.single.headers['Authorization'], 'Bearer $_token');
      expect(sent.single.headers['Content-Type'], contains('application/json'));
    });

    test('sends the system and user prompts as two messages', () async {
      final client = clientThat((_) => http.Response(okBody('{}'), 200));
      await complete(client);

      final messages = bodyOf(sent.single)['messages']! as List;
      expect(messages, hasLength(2));
      expect((messages.first as Map)['role'], 'system');
      expect((messages.last as Map)['role'], 'user');
    });

    // Hebrew goes out as UTF-8 and comes back as UTF-8. `http.Response.body`
    // defaults to latin-1 when a server sends no charset, which is why the
    // client decodes `bodyBytes` itself.
    test('reads a Hebrew response body as UTF-8', () async {
      final client = clientThat(
        (_) => http.Response.bytes(utf8.encode(okBody('{"שם":"סלט"}')), 200),
      );

      expect(await complete(client), const ChatSucceeded('{"שם":"סלט"}'));
    });
  });

  group('an image', () {
    test('produces exactly one image_url part with a data: URI', () async {
      final client = clientThat((_) => http.Response(okBody('{}'), 200));
      await complete(client, imageBase64: 'QUJD', imageMediaType: 'image/png');

      final user = (bodyOf(sent.single)['messages']! as List).last as Map;
      final parts = user['content']! as List;
      final images = parts.where((p) => (p as Map)['type'] == 'image_url');
      expect(images, hasLength(1));
      expect(
        ((images.single as Map)['image_url']! as Map)['url'],
        'data:image/png;base64,QUJD',
      );
    });

    test('defaults the media type when none is given', () async {
      final client = clientThat((_) => http.Response(okBody('{}'), 200));
      await complete(client, imageBase64: 'QUJD');

      final user = (bodyOf(sent.single)['messages']! as List).last as Map;
      final image = (user['content']! as List).last as Map;
      expect(
        (image['image_url']! as Map)['url'],
        startsWith('data:image/jpeg;'),
      );
    });

    test('sends no image part when none is given', () async {
      final client = clientThat((_) => http.Response(okBody('{}'), 200));
      await complete(client);

      final user = (bodyOf(sent.single)['messages']! as List).last as Map;
      expect(user['content'], hasLength(1));
    });
  });

  group('failure mapping', () {
    // Every status branch, named. This class is almost entirely error
    // handling, so a gap here is an untested failure path in front of a user.
    const statuses = {
      401: ChatFailureReason.unauthorised,
      403: ChatFailureReason.unauthorised,
      429: ChatFailureReason.rateLimited,
      400: ChatFailureReason.badResponse,
      404: ChatFailureReason.badResponse,
      500: ChatFailureReason.badResponse,
      503: ChatFailureReason.badResponse,
    };

    for (final entry in statuses.entries) {
      test('${entry.key} maps to ${entry.value.name}', () async {
        final client = clientThat((_) => http.Response('nope', entry.key));

        expect(await complete(client), ChatFailed(entry.value));
      });
    }

    // A 404 is what a retired `:free` model id looks like. It is a
    // `badResponse`, never a crash — free ids come and go upstream.
    test('a retired model id is a badResponse, not a throw', () async {
      final client = clientThat(
        (_) => http.Response('{"error":"no such model"}', 404),
        model: 'someone/retired-model:free',
      );

      expect(
        await complete(client),
        const ChatFailed(ChatFailureReason.badResponse),
      );
    });

    test('a socket failure is offline, not badResponse', () async {
      final client = clientThat(
        (_) => throw http.ClientException('Failed host lookup'),
      );

      expect(
        await complete(client),
        const ChatFailed(ChatFailureReason.offline),
      );
    });

    // Milliseconds rather than the shipped thirty seconds. Waiting out the
    // real window would add half a minute to every CI run of the whole
    // suite, which is how a correct test becomes one people delete.
    test('a slow response is abandoned and reported as timeout', () async {
      final client = clientThat((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response(okBody('{}'), 200);
      }, timeout: const Duration(milliseconds: 20));

      expect(
        await complete(client),
        const ChatFailed(ChatFailureReason.timeout),
      );
    });

    test('the shipped timeout is thirty seconds', () {
      expect(OpenRouterClient.defaultTimeout, const Duration(seconds: 30));
    });
  });

  group('a 200 that is not usable', () {
    Future<void> expectBad(String body) async {
      final client = clientThat((_) => http.Response(body, 200));

      expect(
        await complete(client),
        const ChatFailed(ChatFailureReason.badResponse),
      );
    }

    test('a body that is not JSON', () => expectBad('not json at all'));
    test('a JSON array rather than an object', () => expectBad('[1,2,3]'));
    test('no choices key', () => expectBad('{}'));
    test('an empty choices list', () => expectBad('{"choices":[]}'));
    test('a choice with no message', () => expectBad('{"choices":[{}]}'));
    test(
      'a message with no content',
      () => expectBad('{"choices":[{"message":{}}]}'),
    );
    test(
      'content that is not a string',
      () => expectBad('{"choices":[{"message":{"content":42}}]}'),
    );

    // Not a success carrying `''`: a caller handed an empty string would
    // parse it, find no macros, and need a second failure path for a case
    // this one already owns.
    test('empty content', () => expectBad(okBody('')));
  });

  group('credentials', () {
    // Sending an empty bearer to find out what we already know would spend a
    // rate-limit slot and tell the provider this device is trying.
    test(
      'null credentials short-circuit to unauthorised with no request made',
      () async {
        final client = clientThat(
          (_) => http.Response(okBody('{}'), 200),
          token: null,
        );

        expect(
          await complete(client),
          const ChatFailed(ChatFailureReason.unauthorised),
        );
        expect(sent, isEmpty);
      },
    );

    test('an empty token short-circuits too', () async {
      final client = clientThat(
        (_) => http.Response(okBody('{}'), 200),
        token: '',
      );

      expect(
        await complete(client),
        const ChatFailed(ChatFailureReason.unauthorised),
      );
      expect(sent, isEmpty);
    });
  });

  // Epic #312's invariant, asserted rather than left to review.
  group('the token does not leak', () {
    test('it appears in no failure value, on any branch', () async {
      final results = <ChatResult>[];

      for (final respond in <FutureOr<http.Response> Function(http.Request)>[
        (_) => http.Response('{"error":"bad key $_token"}', 401),
        (_) => http.Response('over quota', 429),
        (_) => http.Response('boom', 500),
        (_) => http.Response('not json', 200),
        (_) => throw http.ClientException('failed for Bearer $_token'),
      ]) {
        results.add(await complete(clientThat(respond)));
      }

      for (final result in results) {
        expect(result.toString(), isNot(contains(_token)));
        expect(result.toString(), isNot(contains('sk-or')));
      }
    });

    test('a success value carries only the content', () async {
      final client = clientThat((_) => http.Response(okBody('{"a":1}'), 200));
      final result = await complete(client) as ChatSucceeded;

      expect(result.content, isNot(contains(_token)));
      expect(result.toString(), isNot(contains(_token)));
    });
  });

  // The interface's central promise. Written as a loop over every shape this
  // client can be handed, in a form a second implementation can be pointed at
  // when the backend lands.
  group('the never-throws contract', () {
    test('no input or response shape produces a throw', () async {
      final responses = <FutureOr<http.Response> Function(http.Request)>[
        (_) => http.Response(okBody('{}'), 200),
        (_) => http.Response('', 200),
        (_) => http.Response('null', 200),
        (_) => http.Response('{"choices":null}', 200),
        (_) => http.Response('', 204),
        (_) => http.Response('gone', 410),
        (_) => throw http.ClientException('socket'),
        (_) => throw StateError('an Error, not an Exception'),
      ];

      for (final respond in responses) {
        final result = await complete(clientThat(respond));
        expect(result, isA<ChatResult>());
      }
    });
  });
}
