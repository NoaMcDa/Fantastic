import 'package:meta/meta.dart';

/// One food the estimator identified, and what it contributes.
///
/// The weight is carried separately from the macros because the review surface
/// shows both: `ביצה · 100 גרם · שומן 10 · פחמימות 1 · חלבון 13`. A user who
/// disagrees with an estimate almost always disagrees with the *weight*, so
/// the weight has to be visible and editable rather than folded into the
/// macros.
///
/// Nothing here polices its own constructor — validation belongs to the
/// estimator, which is where a bad number arrives, and every other domain
/// model in this codebase is a plain value object too.
@immutable
class EstimatedItem {
  const EstimatedItem({
    required this.name,
    required this.grams,
    required this.fatG,
    required this.netCarbsG,
    required this.proteinG,
  });

  /// What the estimator called it, in the language the user wrote.
  final String name;

  /// How much of it the estimator thinks there was.
  final double grams;

  final double fatG;
  final double netCarbsG;
  final double proteinG;

  EstimatedItem copyWith({
    String? name,
    double? grams,
    double? fatG,
    double? netCarbsG,
    double? proteinG,
  }) => EstimatedItem(
    name: name ?? this.name,
    grams: grams ?? this.grams,
    fatG: fatG ?? this.fatG,
    netCarbsG: netCarbsG ?? this.netCarbsG,
    proteinG: proteinG ?? this.proteinG,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstimatedItem &&
          other.name == name &&
          other.grams == grams &&
          other.fatG == fatG &&
          other.netCarbsG == netCarbsG &&
          other.proteinG == proteinG;

  @override
  int get hashCode => Object.hash(name, grams, fatG, netCarbsG, proteinG);
}
