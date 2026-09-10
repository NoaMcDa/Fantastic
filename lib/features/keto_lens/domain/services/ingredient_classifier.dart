import 'package:fantastic/features/keto_lens/domain/models/ingredient_verdict.dart';

/// Classifies an ingredient list against the keto rule set.
///
/// Synchronous by design: classification is pure CPU work with no I/O.
///
/// The rule lists themselves live in
/// `lib/core/constants/ingredient_rules.dart` (#20) — implementations read
/// them rather than redeclaring them, so the forbidden and clean sets have one
/// source of truth.
abstract interface class IngredientClassifier {
  /// Classifies [ingredients] against the keto rule set.
  ///
  /// Returns the worst-case badge plus the tokens that earned it, reduced via
  /// `VerdictBadge.worst`. An empty list returns a clean verdict with no flags.
  ///
  /// Matching is case-insensitive. An unrecognised token is not flagged — the
  /// verdict describes what was *found*, not what was understood.
  IngredientVerdict classify(List<String> ingredients);
}
