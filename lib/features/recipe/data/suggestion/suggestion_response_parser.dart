import 'dart:convert';

import 'package:fantastic/core/constants/ingredient_rules.dart';
import 'package:fantastic/core/utils/numeric_input.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/outcome_source.dart';
import 'package:fantastic/features/recipe/domain/models/parsed_ingredient.dart';
import 'package:fantastic/features/recipe/domain/models/substitution.dart';
import 'package:fantastic/features/recipe/domain/models/suggestion_result.dart';
import 'package:fantastic/features/recipe/domain/substitution_engine.dart';

/// Turns a model's reply into a [SuggestionResult].
///
/// **This is the trust boundary**, borrowed line for line from
/// `EstimateResponseParser` — the reply is JSON from a third party, and
/// everything below treats it as hostile input: nothing is executed, no
/// field is read as a command, an unexpected key is ignored rather than
/// acted on, and every number goes through [NumericInput.positiveFinite].
///
/// **Every proposed replacement is re-checked against [IngredientRules] here,
/// independently of what the prompt asked for.** A model that answers
/// "use maltitol" despite [SubstitutionPrompt.system] saying not to has told
/// us nothing we can show — the app must not recommend what Keto Lens
/// flags — so that line is left out and stays `Unrecognised` in the caller.
abstract final class SuggestionResponseParser {
  static const double minRatio = 0.05;
  static const double maxRatio = 20;
  static const int maxReplacementLength = 60;
  static const int maxReasonLength = 120;

  /// Parses [content] into a [SuggestionResult].
  ///
  /// **Never throws.** Every malformed shape returns
  /// [SuggestionFailureReason.badResponse].
  ///
  /// [requested] is exactly what was sent — so an `original` or
  /// `already_keto` entry that matches nothing in it is ignored, never
  /// added. Matching uses `SubstitutionEngine.key`, the same
  /// normalise-fold-lowercase function the engine itself matches with, so a
  /// model's verbatim echo of a line lines up with the [ParsedIngredient] it
  /// answered for.
  static SuggestionResult parse(
    String content,
    List<ParsedIngredient> requested,
  ) {
    final Object? decoded;
    try {
      decoded = jsonDecode(_withoutFence(content));
    } on Object catch (_) {
      // `Object`, not `Exception`: a malformed document throws a
      // `FormatException`, but a pathological one can throw an `Error` out of
      // the decoder, and an `on Exception` clause would miss it.
      return const SuggestionsFailed(
        reason: SuggestionFailureReason.badResponse,
      );
    }

    if (decoded is! Map) {
      return const SuggestionsFailed(
        reason: SuggestionFailureReason.badResponse,
      );
    }

    final rawSubstitutions = decoded['substitutions'];
    if (rawSubstitutions is! List) {
      return const SuggestionsFailed(
        reason: SuggestionFailureReason.badResponse,
      );
    }

    final byKey = <String, ParsedIngredient>{
      for (final ingredient in requested)
        SubstitutionEngine.key(ingredient.name): ingredient,
    };

    final outcomes = <String, IngredientOutcome>{};

    for (final raw in rawSubstitutions) {
      if (raw is! Map) {
        continue;
      }
      final original = raw['original'];
      if (original is! String) {
        continue;
      }
      final key = SubstitutionEngine.key(original);
      final ingredient = byKey[key];
      if (ingredient == null) {
        // Answered a line that was never asked about — ignored, not added.
        continue;
      }

      final replacementRaw = raw['replacement'];
      if (replacementRaw is! String) {
        continue;
      }
      final replacement = replacementRaw.trim();
      if (replacement.isEmpty || replacement.length > maxReplacementLength) {
        continue;
      }

      final ratio = NumericInput.positiveFinite(raw['ratio']?.toString());
      if (ratio == null || ratio < minRatio || ratio > maxRatio) {
        continue;
      }

      if (_namesForbiddenIngredient(replacement)) {
        // The classifier's own rule, re-applied: a model that says "use
        // maltitol" has told us nothing we can show.
        continue;
      }

      outcomes[key] = Substituted(
        ingredient,
        substitution: Substitution(
          replacement: replacement,
          ratio: ratio,
          reason: _reason(raw['reason']),
        ),
        source: OutcomeSource.suggested,
      );
    }

    for (final entry in _strings(decoded['already_keto'])) {
      final key = SubstitutionEngine.key(entry);
      final ingredient = byKey[key];
      if (ingredient == null) {
        continue;
      }
      // A `substitutions` answer for the same line, if any, was processed
      // first and wins — a model should never name one line in two lists,
      // but if it does, "here is a fix" is the more useful of the two.
      outcomes.putIfAbsent(
        key,
        () => AlreadyKeto(ingredient, source: OutcomeSource.suggested),
      );
    }

    // Nothing usable is still a returned, empty answer, not a failure: the
    // model was reached and had nothing to add.
    return SuggestionsReturned(outcomes: outcomes);
  }

  /// Whether [replacement] names an ingredient `IngredientClassifierImpl`
  /// would flag — the classifier's own `contains` match, lowercased, applied
  /// here rather than redeclared.
  static bool _namesForbiddenIngredient(String replacement) {
    final lower = replacement.toLowerCase();
    return IngredientRules.allForbiddenSeedOils.any(lower.contains) ||
        IngredientRules.allInsulinSpikingSweeteners.any(lower.contains);
  }

  static String _reason(Object? raw) {
    if (raw is! String) {
      return '';
    }
    final trimmed = raw.trim();
    return trimmed.length > maxReasonLength
        ? trimmed.substring(0, maxReasonLength)
        : trimmed;
  }

  /// The non-empty strings in [raw], or an empty list.
  static List<String> _strings(Object? raw) {
    if (raw is! List) {
      return [];
    }
    return [
      for (final entry in raw)
        if (entry is String && entry.trim().isNotEmpty) entry.trim(),
    ];
  }

  /// [content] with a markdown fence stripped, if it has one.
  ///
  /// Identical to `EstimateResponseParser._withoutFence` — models add a fence
  /// despite being told not to, and rejecting an otherwise good answer over
  /// three backticks is a self-inflicted failure.
  static String _withoutFence(String content) {
    var text = content.trim();
    if (!text.startsWith('```')) {
      return text;
    }
    final firstBreak = text.indexOf('\n');
    if (firstBreak == -1) {
      return text;
    }
    text = text.substring(firstBreak + 1);
    final closing = text.lastIndexOf('```');
    return (closing == -1 ? text : text.substring(0, closing)).trim();
  }
}
