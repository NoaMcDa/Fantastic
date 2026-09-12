import 'package:fantastic/core/services/llm/llm_chat_client.dart';
import 'package:fantastic/features/recipe/data/suggestion/substitution_prompt.dart';
import 'package:fantastic/features/recipe/data/suggestion/suggestion_response_parser.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/models/suggestion_result.dart';
import 'package:fantastic/features/recipe/domain/services/substitution_suggester.dart';

/// [SubstitutionSuggester] over any [LlmChatClient].
///
/// **Names no provider, and must survive the backend swap untouched** — the
/// same shape `RemoteMacroEstimator` follows for the same reason: the
/// destination is already known to be temporary, and that swap must be a new
/// `LlmChatClient` implementation and nothing else.
class LlmSubstitutionSuggester implements SubstitutionSuggester {
  const LlmSubstitutionSuggester({required this.client});

  /// Public rather than private: a named parameter cannot start with an
  /// underscore, so a private field cannot satisfy `prefer_initializing_formals`
  /// — the same reasoning `RemoteMacroEstimator.client` and
  /// `OpenRouterClient.credentials` record.
  final LlmChatClient client;

  @override
  Future<SuggestionResult> suggest(List<ParsedIngredient> unrecognised) async {
    if (unrecognised.isEmpty) {
      // Before anything else, so an empty call costs nothing against a
      // 50-requests-a-day quota.
      return const SuggestionsFailed(
        reason: SuggestionFailureReason.emptyInput,
      );
    }

    // Only what is actually sent is what a model could answer for — capping
    // here, once, is what makes "excess stays Unrecognised" true both for
    // what leaves the device and for what the parser is asked to match.
    final requested = unrecognised.length > SubstitutionPrompt.maxLines
        ? unrecognised.sublist(0, SubstitutionPrompt.maxLines)
        : unrecognised;

    // Names only — never `raw`, quantity or unit. Only what is needed to ask
    // "what keto substitute is this?" leaves the device.
    final names = [for (final ingredient in requested) ingredient.name];

    final ChatResult result;
    try {
      result = await client.complete(
        systemPrompt: SubstitutionPrompt.system,
        userPrompt: SubstitutionPrompt.user(names),
      );
    } on Object catch (_) {
      // `LlmChatClient` promises never to throw; this catch is here because a
      // promise is not an enforcement — the same reasoning
      // `RemoteMacroEstimator.estimate` records.
      return const SuggestionsFailed(
        reason: SuggestionFailureReason.badResponse,
      );
    }

    return switch (result) {
      ChatSucceeded(:final content) => SuggestionResponseParser.parse(
        content,
        requested,
      ),
      ChatFailed(:final reason) => SuggestionsFailed(
        reason: _reasonFor(reason),
      ),
    };
  }

  /// Maps a transport failure onto the one the UI words.
  ///
  /// **`timeout` becomes `offline`** — from the user's seat a request that
  /// never came back and one that could not leave are the same event, and
  /// `RemoteMacroEstimator._reasonFor` makes the identical choice. #416 is
  /// exactly why this mapping is not free: the same collapse there sent a
  /// slow-but-working model's timeout out as "אין חיבור אינטרנט" to a user
  /// who had a perfectly good connection. It is kept here deliberately —
  /// [SubstitutionPrompt] is built short precisely so this call finishes well
  /// inside the transport's timeout — rather than invented differently, so
  /// the two features fail the same way for the same reason.
  ///
  /// **`unauthorised` becomes `notConfigured`** — BYOK's missing and rejected
  /// credentials are one instruction from the user's seat: go to Profile.
  static SuggestionFailureReason _reasonFor(ChatFailureReason reason) =>
      switch (reason) {
        ChatFailureReason.offline => SuggestionFailureReason.offline,
        ChatFailureReason.timeout => SuggestionFailureReason.offline,
        ChatFailureReason.unauthorised => SuggestionFailureReason.notConfigured,
        ChatFailureReason.rateLimited => SuggestionFailureReason.rateLimited,
        ChatFailureReason.badResponse => SuggestionFailureReason.badResponse,
      };
}
