import 'dart:async';
import 'dart:convert';

import 'package:fantastic/core/services/llm/llm_chat_client.dart';
import 'package:fantastic/core/services/llm/llm_credentials.dart';
import 'package:http/http.dart' as http;

/// [LlmChatClient] against OpenRouter.
///
/// **Nothing outside this file and the one provider that constructs it names
/// OpenRouter.** That is what makes the planned swap to our own backend a new
/// file rather than an edit (Epic #312's OCP invariant).
///
/// **Keto Lens's no-network invariant is unaffected.** A scan still makes no
/// network call, nothing in `keto_lens/` may import this, and this imports
/// nothing from `keto_lens/`. Estimation is a different feature that happens
/// to be reached from the same sheet; see
/// `design/m15_meal_entry_research.md` §4.
class OpenRouterClient implements LlmChatClient {
  OpenRouterClient({
    required http.Client httpClient,
    required this.credentials,
    Uri? endpoint,
    this.model = defaultModel,
    this.timeout = defaultTimeout,
  }) : _http = httpClient,
       _endpoint = endpoint ?? defaultEndpoint;

  final http.Client _http;

  /// Public, like `MealLoggingService`'s collaborators: a named parameter
  /// cannot start with an underscore, so a private field here cannot satisfy
  /// `prefer_initializing_formals`. It is an interface, and the tests already
  /// hold it.
  final LlmCredentials credentials;

  final Uri _endpoint;

  /// The model id sent with every request.
  final String model;

  static final Uri defaultEndpoint = Uri.parse(
    'https://openrouter.ai/api/v1/chat/completions',
  );

  /// The pinned model.
  ///
  /// A `:free` id, so a user's own key costs them nothing — the free tier is
  /// 20 requests a minute and 50 a day per key, which
  /// `design/m15_meal_entry_research.md` records as the reason BYOK is the
  /// shipping shape rather than one shared key.
  ///
  /// **Vision-capable, and that is a requirement rather than a preference:**
  /// #312's photo mode sends a plate of food, so a text-only model would fail
  /// half the feature. Structured-output capable too, which the menu scanner
  /// asks for first (`design/m16_structured_output_fix.md`).
  ///
  /// **Chosen by the product owner after the menu scanner failed on every
  /// input mode** (`design/m16_structured_output_fix.md`, third report). It
  /// was the runner-up in #414's measurement: the tidiest itemised JSON on
  /// the Hebrew shakshuka prompt, and 32 s against the real M15 system
  /// prompt — over the 30 s timeout of the day, which is why #414 pinned
  /// `nex-agi/nex-n2.5-pro:free` for latency instead. The timeout has since
  /// been 120 s (#429), so the measured answer fits with room to spare, and
  /// the estimate sheet now waits about half a minute rather than ten
  /// seconds. That trade was the owner's call to make, and it was made
  /// without a fresh measurement: the session that made the switch could not
  /// reach the host. If the estimate sheet starts timing out, this constant
  /// and [fallbackModels] are the two lines to swap back.
  static const String defaultModel = 'dots-studio/dots-3-note-preview:free';

  /// Free model ids come and go upstream.
  ///
  /// Listed rather than used: a 404 on the pinned one is a
  /// [ChatFailureReason.badResponse], never a crash, and choosing between
  /// them is a product decision with a settings screen behind it — not
  /// something a network adapter should do silently on a user's behalf, since
  /// two models do not return the same carb count.
  ///
  /// The first entry is #414's latency pick (8–12 s on the real M15 prompt,
  /// verified live on 2026-09-12) and the model the menu scanner first failed
  /// against; the second produced clean JSON but took 52 s in the same
  /// measurement. Both from unrelated providers to the pinned one.
  static const List<String> fallbackModels = [
    'nex-agi/nex-n2.5-pro:free',
    'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free',
  ];

  /// How long a request may take before it is abandoned.
  ///
  /// A hung call is worse than a failed one: the review sheet would spin, and
  /// an indeterminate spinner is the hazard `design/m6_handoff.md` records.
  final Duration timeout;

  /// The shipped value.
  ///
  /// Injectable rather than a bare constant so the timeout test can prove the
  /// branch in milliseconds. Waiting out the real two minutes would add
  /// them to every CI run of the whole suite, which is how a correct test
  /// becomes one people delete.
  static const Duration defaultTimeout = Duration(seconds: 120);

  @override
  Future<ChatResult> complete({
    required String systemPrompt,
    required String userPrompt,
    String? imageBase64,
    String? imageMediaType,
    int? maxOutputTokens,
    Map<String, Object?>? responseSchema,
  }) async {
    final token = await credentials.token();
    if (token == null || token.isEmpty) {
      // Short-circuits with **no request made**. Sending an empty bearer to
      // find out what we already know would spend a rate-limit slot and leak
      // the fact that this device is trying.
      return const ChatFailed(ChatFailureReason.unauthorised);
    }

    try {
      var response = await _post(
        token,
        _body(
          systemPrompt: systemPrompt,
          userPrompt: userPrompt,
          imageBase64: imageBase64,
          imageMediaType: imageMediaType,
          maxOutputTokens: maxOutputTokens,
          responseSchema: responseSchema,
        ),
      );

      if (responseSchema != null && rejectsRequestShape(response.statusCode)) {
        // **The structured-output fallback** (`design/m16_structured_output_fix.md`).
        //
        // A `json_schema` request is only honoured by models whose endpoint
        // advertises structured outputs, and a strict schema is also
        // validated before any model sees it. Either way the gateway answers
        // with a 4xx **before the request reaches a model** — so the refusal
        // costs no quota and comes back in well under a second, which is why
        // a menu analysis failed on every input mode while an identical
        // `json_object` request from the meal estimator succeeded, and why
        // lengthening the timeout changed nothing.
        //
        // Re-sent once, as the exact `json_object` shape the estimator has
        // been verified live with. The schema was only ever a strong hint —
        // `MenuResponseParser` trusts nothing in the reply — so dropping it
        // loses no correctness. Not a general retry: 401/403/429 and 5xx are
        // answers about the key, the quota and the provider, and asking
        // again with a different `response_format` changes none of them.
        response = await _post(
          token,
          _body(
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            imageBase64: imageBase64,
            imageMediaType: imageMediaType,
            maxOutputTokens: maxOutputTokens,
            responseSchema: null,
          ),
        );
      }

      return _read(response);
    } on TimeoutException catch (_) {
      return const ChatFailed(ChatFailureReason.timeout);
    } on Object catch (error) {
      // `Object`, not `Exception` — the reasoning `guardPersistence`
      // documents. A malformed response throws an `Error` out of a cast, and
      // an `on Exception` clause misses it.
      //
      // **The caught error is not carried into the result.** An upstream
      // `ClientException` stringifies its request, and this value is the one
      // thing that crosses into a layer that might log it.
      return ChatFailed(
        error is http.ClientException
            ? ChatFailureReason.offline
            : ChatFailureReason.badResponse,
      );
    }
  }

  /// Whether [statusCode] is the gateway refusing the *shape* of a request
  /// rather than answering it: a malformed or unsupported parameter (400),
  /// no endpoint able to serve the requested parameters (404), or a body that
  /// parsed but failed validation (422).
  ///
  /// These are the only statuses the structured-output fallback acts on.
  /// Public and static so the test names each of them; nothing else calls it.
  static bool rejectsRequestShape(int statusCode) =>
      statusCode == 400 || statusCode == 404 || statusCode == 422;

  /// One POST of [body] with [token], bounded by [timeout].
  ///
  /// Each request gets the full [timeout] of its own, so a fallback after a
  /// slow refusal is never cut short by time the first attempt spent.
  Future<http.Response> _post(String token, Map<String, Object?> body) => _http
      .post(
        _endpoint,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      )
      .timeout(timeout);

  /// The OpenAI-compatible request body.
  Map<String, Object?> _body({
    required String systemPrompt,
    required String userPrompt,
    String? imageBase64,
    String? imageMediaType,
    int? maxOutputTokens,
    Map<String, Object?>? responseSchema,
  }) => {
    'model': model,
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': userPrompt},
          if (imageBase64 != null)
            {
              'type': 'image_url',
              // A `data:` URI is how the OpenAI-compatible schema carries an
              // inline image; there is no upload step and nothing is stored
              // anywhere by us.
              'image_url': {
                'url':
                    'data:${imageMediaType ?? _defaultImageMediaType};'
                    'base64,$imageBase64',
              },
            },
        ],
      },
    ],
    // The same meal typed twice must not produce two different carb counts.
    // The daily net-carb budget is 20 g; a sampled answer would move a
    // meaningful fraction of it at random.
    'temperature': 0,
    'max_tokens': ?maxOutputTokens,
    // `json_object` is the shape M15 verified live; `json_schema` is what a
    // menu asks for first, and falls back to `json_object` when the gateway
    // refuses it — see `complete`.
    'response_format': responseSchema == null
        ? {'type': 'json_object'}
        : {
            'type': 'json_schema',
            'json_schema': {
              'name': 'reply',
              'strict': true,
              'schema': responseSchema,
            },
          },
  };

  static const String _defaultImageMediaType = 'image/jpeg';

  /// Maps a response onto the sealed result.
  ///
  /// Exhaustive by status, then by shape. **No retry:** a 429 against a
  /// 50-per-day quota will not succeed a second later, and retrying a request
  /// that may already have been counted is worse than reporting it.
  ChatResult _read(http.Response response) {
    final status = response.statusCode;
    switch (status) {
      case 401:
      case 403:
        return ChatFailed(ChatFailureReason.unauthorised, statusCode: status);
      case 429:
        return ChatFailed(ChatFailureReason.rateLimited, statusCode: status);
    }
    if (status < 200 || status >= 300) {
      return ChatFailed(ChatFailureReason.badResponse, statusCode: status);
    }

    // Every unusable 2xx below carries its status too: a `badResponse` with
    // `http 200` says "the model answered and we could not use it", which
    // is a different fix from a 400 or a 404 and the same headline.
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (_) {
      // A 2xx that is not JSON at all (an HTML error page from a proxy, a
      // truncated body) is still "the provider answered": stamped with its
      // status here rather than left to `complete`'s catch-all, which has
      // no status to give it.
      return ChatFailed(ChatFailureReason.badResponse, statusCode: status);
    }
    if (decoded is! Map<String, Object?>) {
      return ChatFailed(ChatFailureReason.badResponse, statusCode: status);
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      return ChatFailed(ChatFailureReason.badResponse, statusCode: status);
    }

    final first = choices.first;
    if (first is! Map) {
      return ChatFailed(ChatFailureReason.badResponse, statusCode: status);
    }

    final message = first['message'];
    if (message is! Map) {
      return ChatFailed(ChatFailureReason.badResponse, statusCode: status);
    }

    final content = message['content'];
    // Empty is a failure, not a success carrying `''`. A caller handed an
    // empty string would parse it, find no macros, and have to invent a
    // second failure path for a case this one already owns.
    if (content is! String || content.isEmpty) {
      return ChatFailed(ChatFailureReason.badResponse, statusCode: status);
    }

    return ChatSucceeded(content);
  }
}
