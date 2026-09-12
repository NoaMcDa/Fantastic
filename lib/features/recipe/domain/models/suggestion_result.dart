import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:meta/meta.dart';

/// What one `SubstitutionSuggester.suggest` call produced.
///
/// Sealed for the same reason `MealEstimate` and `ScanResult` are: a request
/// that could not be answered must not be expressible as a degenerate
/// success. A model that could not be reached is not "zero suggestions" —
/// that is a real, distinct answer [SuggestionsReturned] already carries when
/// its map is empty.
@immutable
sealed class SuggestionResult {
  const SuggestionResult();
}

/// The request reached the model and came back parseable.
///
/// This does not mean every unrecognised line was answered — a model that
/// looked and had nothing to say for a line, or answered it unusably, simply
/// leaves that key out. An empty [outcomes] is still [SuggestionsReturned],
/// not a failure: the model was reached and had nothing to add.
@immutable
final class SuggestionsReturned extends SuggestionResult {
  const SuggestionsReturned({required this.outcomes});

  /// Keyed by `SubstitutionEngine.key` applied to the input line's name.
  ///
  /// A line absent from this map is left `Unrecognised` by the caller — the
  /// model did not answer it, answered it unusably, or named it `unknown`.
  /// Every value carries `OutcomeSource.suggested`: a clean claim or a
  /// replacement from a model is not evidence the way the rule table's own
  /// answer is, and the marker on screen says so.
  final Map<String, IngredientOutcome> outcomes;

  @override
  String toString() => 'SuggestionsReturned(${outcomes.length} outcomes)';
}

/// The request did not produce an answer at all.
@immutable
final class SuggestionsFailed extends SuggestionResult {
  const SuggestionsFailed({required this.reason});

  final SuggestionFailureReason reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestionsFailed && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;

  @override
  String toString() => 'SuggestionsFailed(${reason.name})';
}

/// Why a `suggest` call produced no [SuggestionsReturned].
///
/// No `unauthorised` value, unlike `EstimateFailureReason`: BYOK's missing
/// and rejected credentials collapse to the same instruction from the user's
/// seat — go to Profile — so `LlmSubstitutionSuggester` maps both onto
/// [notConfigured] and the enum carries no case that could never be reached
/// from here.
enum SuggestionFailureReason {
  /// [SubstitutionSuggester.suggest] was called with nothing to ask about.
  emptyInput,

  /// Estimation is off, or no API key has been entered.
  notConfigured,

  /// The request could not reach the provider, or timed out.
  offline,

  /// The provider refused on quota.
  rateLimited,

  /// A response arrived but was not usable.
  badResponse,
}
