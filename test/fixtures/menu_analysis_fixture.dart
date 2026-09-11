import 'package:fantastic/features/menu/domain/models/analysed_dish.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis_failure_reason.dart';

import 'analysed_dish_fixture.dart';

/// Test data for [MenuAnalysis].
abstract final class MenuAnalysisFixture {
  /// One dish per verdict — see [AnalysedDishFixture].
  static List<AnalysedDish> dishes() => [
    AnalysedDishFixture.orderAsIs(),
    AnalysedDishFixture.modifiable(),
    AnalysedDishFixture.nonKeto(),
  ];

  /// A successful analysis carrying all three verdicts plus an unclassified
  /// name and one unread page — every field distinct so a crossed field is
  /// visible in a test.
  static MenuAnalysed analysed({
    List<AnalysedDish>? withDishes,
    List<String> unclassified = const ['מנת היום'],
    int pageCount = 2,
    List<int> unreadPages = const [2],
  }) => MenuAnalysed(
    dishes: withDishes ?? dishes(),
    unclassified: unclassified,
    pageCount: pageCount,
    unreadPages: unreadPages,
  );

  /// A successful analysis with nothing left over: no unclassified name, no
  /// unread page.
  static MenuAnalysed clean() => MenuAnalysed(dishes: dishes());

  /// A failed analysis. Every reason has one.
  static MenuAnalysisFailed failed({
    MenuAnalysisFailureReason reason = MenuAnalysisFailureReason.badResponse,
  }) => MenuAnalysisFailed(reason: reason);
}
