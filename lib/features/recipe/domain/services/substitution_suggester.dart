import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/models/suggestion_result.dart';

/// The opt-in second pass over the lines `SubstitutionEngine` could not place
/// (#396).
///
/// **Which provider answers is deliberately not named here** — the same
/// reasoning as `MacroEstimator`: a domain interface that named OpenRouter
/// would be the first crack in Epic #312's OCP invariant. The concrete
/// adapter lives in `data/suggestion/`, behind `LlmChatClient`.
///
/// A separate interface from `MacroEstimator` rather than a shared one: the
/// two send different shapes (ingredient names, never quantities or macros)
/// to a different prompt and parse a different schema, and forcing one
/// signature to cover both would leave one of them passing arguments the
/// other ignores.
abstract interface class SubstitutionSuggester {
  /// One request for every line the engine could not place.
  ///
  /// **Never throws.** Every transport and provider failure is a value, not
  /// an exception — the contract `LlmChatClient.complete` already makes, kept
  /// unbroken here. Returns [SuggestionsFailed] with
  /// [SuggestionFailureReason.emptyInput] for an empty [unrecognised], and
  /// **no request is made** for that case — it costs nothing against a
  /// 50-requests-a-day quota.
  ///
  /// Sends [ParsedIngredient.name] only — never [ParsedIngredient.raw], the
  /// quantity, the unit, or anything recognised by the rule table. Only what
  /// is needed to ask "what keto substitute is this?" leaves the device.
  Future<SuggestionResult> suggest(List<ParsedIngredient> unrecognised);
}
