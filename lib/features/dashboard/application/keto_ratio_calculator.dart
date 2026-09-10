import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'keto_ratio_calculator.g.dart';

/// The app's core metric: `Fat(g) / (NetCarbs(g) + Protein(g))`.
///
/// Stateless and injectable as a `const` singleton. Pure Dart — no Flutter,
/// no storage, no I/O.
///
/// The thresholds that give the number meaning (`KetoConstants.targetKetoRatioMin`
/// and `targetKetoRatioIdeal`) belong to the UI that renders it, not here: this
/// class answers "what is the ratio", never "is it good enough".
class KetoRatioCalculator {
  const KetoRatioCalculator();

  /// Returns `fat / (netCarbs + protein)`.
  ///
  /// Returns `0` when the denominator is zero — semantically "no net carbs or
  /// protein logged" rather than an infinite ratio. Mirrors
  /// [MealEntry.ketoRatio], which makes the same choice for a single meal.
  ///
  /// Throws [ArgumentError] if any argument is negative. A negative macro is a
  /// caller bug, not a user condition: the form validates its input, and a
  /// stored value can only be negative if something upstream is broken.
  double calculate({
    required double fat,
    required double netCarbs,
    required double protein,
  }) {
    if (fat < 0 || netCarbs < 0 || protein < 0) {
      throw ArgumentError(
        'Macro values must be non-negative, got '
        'fat: $fat, netCarbs: $netCarbs, protein: $protein.',
      );
    }
    final denominator = netCarbs + protein;
    if (denominator == 0) {
      return 0;
    }
    return fat / denominator;
  }
}

/// The calculator as a `const` singleton — it holds no state, so every consumer
/// shares one instance.
@riverpod
KetoRatioCalculator ketoRatioCalculator(Ref ref) => const KetoRatioCalculator();
