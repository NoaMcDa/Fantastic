import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:meta/meta.dart';

/// One dish read off a menu, and the verdict it earned.
///
/// Nothing here polices [why] or [modification] — validation belongs to the
/// parser, which is where a bad value arrives. `estimated_item.dart`
/// documents the same convention, and for the same reason: a `const`
/// construction site in a test must stay legal.
@immutable
class AnalysedDish {
  const AnalysedDish({
    required this.name,
    required this.verdict,
    required this.why,
    this.description,
    this.modification,
  });

  /// Exactly as printed on the menu — the user matches it to the page.
  final String name;

  /// The menu's own description line, if it had one.
  final String? description;

  final DishVerdict verdict;

  /// The carb traps or the keto-friendly macros. Never empty: the parser
  /// enforces it, this class does not.
  final String why;

  /// What to ask the server. Non-null iff [verdict] is
  /// [DishVerdict.modifiable] — again the parser's rule, not a constructor
  /// assertion.
  final String? modification;

  /// [clearDescription] and [clearModification] follow `StreakState`'s
  /// convention: passing `null` for a nullable field never clears it, since
  /// there is no way to tell "clear" from "unchanged" on a `??` default.
  AnalysedDish copyWith({
    String? name,
    DishVerdict? verdict,
    String? why,
    String? description,
    bool clearDescription = false,
    String? modification,
    bool clearModification = false,
  }) => AnalysedDish(
    name: name ?? this.name,
    verdict: verdict ?? this.verdict,
    why: why ?? this.why,
    description: clearDescription ? null : description ?? this.description,
    modification: clearModification ? null : modification ?? this.modification,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalysedDish &&
          other.name == name &&
          other.description == description &&
          other.verdict == verdict &&
          other.why == why &&
          other.modification == modification;

  @override
  int get hashCode =>
      Object.hash(name, description, verdict, why, modification);
}
