import 'package:fantastic/core/utils/list_equality.dart';
import 'package:meta/meta.dart';

/// A single logged meal — the macros, timestamp and optional ingredient list
/// that the diary and the keto ratio calculator both read.
///
/// Pure domain: no Flutter, no persistence package, no Riverpod. The data
/// layer converts to and from a record map via `MealEntryMapper`.
@immutable
class MealEntry {
  const MealEntry({
    required this.timestamp,
    required this.fatG,
    required this.netCarbsG,
    required this.proteinG,
    required this.mealName,
    this.id,
    this.ingredients = const [],
    this.imageRef,
  });

  /// Null until first persisted, then the store's record key. `int?` rather
  /// than any type the persistence package defines — the domain layer never
  /// imports it.
  final int? id;

  final DateTime timestamp;
  final double fatG;
  final double netCarbsG;
  final double proteinG;
  final String mealName;

  /// Ingredient tokens. Defaults to empty — never null.
  final List<String> ingredients;

  /// Optional reference to a captured label image.
  final String? imageRef;

  /// Fat / (net carbs + protein), per `CLAUDE.md`'s keto ratio formula.
  ///
  /// Computed rather than stored: a persisted copy can go stale against the
  /// macros it was derived from. Returns 0 when the denominator is 0 rather
  /// than dividing.
  double get ketoRatio =>
      (netCarbsG + proteinG) == 0 ? 0 : fatG / (netCarbsG + proteinG);

  MealEntry copyWith({
    int? id,
    DateTime? timestamp,
    double? fatG,
    double? netCarbsG,
    double? proteinG,
    String? mealName,
    List<String>? ingredients,
    String? imageRef,
  }) => MealEntry(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    fatG: fatG ?? this.fatG,
    netCarbsG: netCarbsG ?? this.netCarbsG,
    proteinG: proteinG ?? this.proteinG,
    mealName: mealName ?? this.mealName,
    ingredients: ingredients ?? this.ingredients,
    imageRef: imageRef ?? this.imageRef,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MealEntry &&
          other.id == id &&
          other.timestamp == timestamp &&
          other.fatG == fatG &&
          other.netCarbsG == netCarbsG &&
          other.proteinG == proteinG &&
          other.mealName == mealName &&
          other.imageRef == imageRef &&
          // Element-wise: two entries with equal-but-not-identical ingredient
          // lists are equal. A plain `==` on List compares identity.
          listEquals(other.ingredients, ingredients);

  @override
  int get hashCode => Object.hash(
    id,
    timestamp,
    fatG,
    netCarbsG,
    proteinG,
    mealName,
    imageRef,
    listHash(ingredients),
  );
}
