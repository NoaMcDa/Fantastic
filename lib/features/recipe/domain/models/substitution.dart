import 'package:meta/meta.dart';

/// A known keto replacement for one ingredient.
@immutable
class Substitution {
  const Substitution({
    required this.replacement,
    required this.ratio,
    required this.reason,
  });

  final String replacement;

  /// Quantity multiplier — 0.25 means use a quarter as much.
  final double ratio;

  /// One short Hebrew line.
  final String reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Substitution &&
          other.replacement == replacement &&
          other.ratio == ratio &&
          other.reason == reason;

  @override
  int get hashCode => Object.hash(replacement, ratio, reason);

  @override
  String toString() =>
      'Substitution(replacement: $replacement, ratio: $ratio, reason: $reason)';
}
