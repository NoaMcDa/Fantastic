import 'package:fantastic/core/utils/list_equality.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:meta/meta.dart';

/// The result of classifying an ingredient list: the worst-case badge plus the
/// tokens that earned it.
///
/// Pure domain: no Flutter, no persistence package, no Riverpod.
@immutable
class IngredientVerdict {
  const IngredientVerdict({
    required this.badge,
    this.flaggedIngredients = const [],
    this.matchedCleanIngredients = const [],
  });

  final VerdictBadge badge;

  /// The subset of input tokens matching a forbidden or caution rule.
  /// Empty for a clean verdict.
  final List<String> flaggedIngredients;

  /// The subset of input tokens matching a *clean* rule.
  ///
  /// Exists because a clean badge is not evidence of anything on its own.
  /// `IngredientClassifier` does not flag a token it does not recognise —
  /// "the verdict describes what was found, not what was understood" — so a
  /// list of entirely unknown ingredients also earns `cleanKeto`. Without
  /// this the UI cannot tell that case from a label whose ingredients were
  /// positively recognised as keto-clean, and a green tick on an unreadable
  /// label is the one failure this feature must not have.
  ///
  /// See [recognisedNothing] and `design/m6_preflight.md` §4.1.
  final List<String> matchedCleanIngredients;

  /// Whether the badge is clean *and* nothing was flagged.
  ///
  /// Checks both deliberately: a clean badge with a non-empty flag list is
  /// contradictory state, and this reports false rather than trusting the
  /// badge alone.
  bool get isClean =>
      badge == VerdictBadge.cleanKeto && flaggedIngredients.isEmpty;

  /// Whether the classifier recognised nothing at all — no rule matched, in
  /// either direction.
  ///
  /// True for an empty ingredient list and for a list of tokens none of the
  /// rules know. The badge will be [VerdictBadge.cleanKeto] in both cases,
  /// and the UI must say "nothing problematic was found" rather than
  /// "clean keto", because those are different claims.
  bool get recognisedNothing =>
      flaggedIngredients.isEmpty && matchedCleanIngredients.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientVerdict &&
          other.badge == badge &&
          listEquals(other.flaggedIngredients, flaggedIngredients) &&
          listEquals(other.matchedCleanIngredients, matchedCleanIngredients);

  @override
  int get hashCode => Object.hash(
    badge,
    listHash(flaggedIngredients),
    listHash(matchedCleanIngredients),
  );
}
