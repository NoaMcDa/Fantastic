import 'package:fantastic/core/utils/list_equality.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:meta/meta.dart';

/// The result of classifying an ingredient list: the worst-case badge plus the
/// tokens that earned it.
///
/// Pure domain: no Flutter, Isar or Riverpod.
@immutable
class IngredientVerdict {
  const IngredientVerdict({
    required this.badge,
    this.flaggedIngredients = const [],
  });

  final VerdictBadge badge;

  /// The subset of input tokens matching a forbidden or caution rule.
  /// Empty for a clean verdict.
  final List<String> flaggedIngredients;

  /// Whether the badge is clean *and* nothing was flagged.
  ///
  /// Checks both deliberately: a clean badge with a non-empty flag list is
  /// contradictory state, and this reports false rather than trusting the
  /// badge alone.
  bool get isClean =>
      badge == VerdictBadge.cleanKeto && flaggedIngredients.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientVerdict &&
          other.badge == badge &&
          listEquals(other.flaggedIngredients, flaggedIngredients);

  @override
  int get hashCode => Object.hash(badge, listHash(flaggedIngredients));
}
