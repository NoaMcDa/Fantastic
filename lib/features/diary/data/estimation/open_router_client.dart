import 'dart:async';
import 'dart:convert';

import 'package:fantastic/features/diary/data/estimation/estimation_credentials.dart';
import 'package:fantastic/features/diary/data/estimation/llm_chat_client.dart';
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
  final EstimationCredentials credentials;

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
  /// half the feature.
  static const String defaultModel =
      'meta-llama/llama-3.2-11b-vision-instruct:free';

  /// Free model ids come and go upstream.
  ///
  /// Listed rather than used: a 404 on the pinned one is a
  /// [ChatFailureReason.badResponse], never a crash, and choosing between
  /// them is a product decision with a settings screen behind it — not
  /// something a network adapter should do silently on a user's behalf, since
  /// two models do not return the same carb count.
  static const List<String> fallbackModels = [
    'qwen/qwen2.5-vl-32b-instruct:free',
    'google/gemini-2.0-flash-exp:free',
  ];

  /// How long a request may take before it is abandoned.
  ///
  /// A hung call is worse than a failed one: the review sheet would spin, and
  /// an indeterminate spinner is the hazard `design/m6_handoff.md` records.
  final Duration timeout;

  /// The shipped value.
  ///
  /// Injectable rather than a bare constant so the timeout test can prove the
  /// branch in milliseconds. Waiting out the real thirty seconds would add
  /// them to every CI run of the whole suite, which is how a correct test
  /// becomes one people delete.
  static const Duration defaultTimeout = Duration(seconds: 30);

  @override
  Future<ChatResult> complete({
    required String systemPrompt,
    required String userPrompt,
    String? imageBase64,
    String? imageMediaType,
  }) async {
    final token = await credentials.token();
    if (token == null || token.isEmpty) {
      // Short-circuits with **no request made**. Sending an empty bearer to
      // find out what we already know would spend a rate-limit slot and leak
      // the fact that this device is trying.
      return const ChatFailed(ChatFailureReason.unauthorised);
    }

    try {
      final response = await _http
          .post(
            _endpoint,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(
              _body(
                systemPrompt: systemPrompt,
                userPrompt: userPrompt,
                imageBase64: imageBase64,
                imageMediaType: imageMediaType,
              ),
            ),
          )
          .timeout(timeout);

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

  /// The OpenAI-compatible request body.
  Map<String, Object?> _body({
    required String systemPrompt,
    required String userPrompt,
    String? imageBase64,
    String? imageMediaType,
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
    'response_format': {'type': 'json_object'},
  };

  static const String _defaultImageMediaType = 'image/jpeg';

  /// Maps a response onto the sealed result.
  ///
  /// Exhaustive by status, then by shape. **No retry:** a 429 against a
  /// 50-per-day quota will not succeed a second later, and retrying a request
  /// that may already have been counted is worse than reporting it.
  ChatResult _read(http.Response response) {
    switch (response.statusCode) {
      case 401:
      case 403:
        return const ChatFailed(ChatFailureReason.unauthorised);
      case 429:
        return const ChatFailed(ChatFailureReason.rateLimited);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const ChatFailed(ChatFailureReason.badResponse);
    }

    final Object? decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, Object?>) {
      return const ChatFailed(ChatFailureReason.badResponse);
    }

    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      return const ChatFailed(ChatFailureReason.badResponse);
    }

    final first = choices.first;
    if (first is! Map) {
      return const ChatFailed(ChatFailureReason.badResponse);
    }

    final message = first['message'];
    if (message is! Map) {
      return const ChatFailed(ChatFailureReason.badResponse);
    }

    final content = message['content'];
    // Empty is a failure, not a success carrying `''`. A caller handed an
    // empty string would parse it, find no macros, and have to invent a
    // second failure path for a case this one already owns.
    if (content is! String || content.isEmpty) {
      return const ChatFailed(ChatFailureReason.badResponse);
    }

    return ChatSucceeded(content);
  }
}
