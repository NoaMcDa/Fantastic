import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';

/// Test data for [MealEstimate] and [EstimatedItem].
///
/// **Every number is distinct.** `CLAUDE.md` §Testing records what a fixture
/// whose fields share one value costs: `SymptomLogFixture` defaulting every
/// scale to 3 let a mapper that crossed two fields pass. Totals summed over
/// items are exactly the kind of code that mistake hides.
abstract final class MealEstimateFixture {
  /// One identified food. Defaults are distinct across every field.
  static EstimatedItem item({
    String name = 'ביצה',
    double grams = 50,
    double fatG = 5,
    double netCarbsG = 1,
    double proteinG = 6,
  }) => EstimatedItem(
    name: name,
    grams: grams,
    fatG: fatG,
    netCarbsG: netCarbsG,
    proteinG: proteinG,
  );

  /// Three items whose macros sum to fat 22, net carbs 9, protein 19 — three
  /// different totals, so a getter summing the wrong column fails.
  static List<EstimatedItem> items() => [
    item(),
    item(name: 'אבוקדו', grams: 100, fatG: 15, netCarbsG: 2, proteinG: 2),
    item(name: 'טחינה', grams: 20, fatG: 2, netCarbsG: 6, proteinG: 11),
  ];

  /// A successful estimate over [items].
  static EstimateSucceeded succeeded({
    List<EstimatedItem>? withItems,
    List<String> unidentified = const [],
  }) => EstimateSucceeded(
    items: withItems ?? items(),
    unidentified: unidentified,
  );

  /// A successful estimate that could not identify one of the foods.
  static EstimateSucceeded partial() => succeeded(unidentified: const ['לחם']);

  /// A failed estimate. Every reason has one.
  static EstimateFailed failed({
    EstimateFailureReason reason = EstimateFailureReason.badResponse,
  }) => EstimateFailed(reason: reason);
}
