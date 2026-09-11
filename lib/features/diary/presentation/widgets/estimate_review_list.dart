import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/core/utils/numeric_input.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:flutter/material.dart';

/// The estimator's working, shown rather than summarised.
///
/// **This is where M15's safety argument is paid for.**
/// `KetoConstants.defaultNetCarbTargetG` is 20 g for a whole day, and the best
/// 2026 vision model's 80.7 kcal mean calorie error *is* 20 g of
/// carbohydrate. The number does not stop at the meal card either:
/// `MealLoggingService` rolls it into the `DailyLog` and hands the day to
/// `AdaptationPhaseService`, so a wrong estimate reaches the streak. A user
/// cannot correct a total they were never shown the parts of.
///
/// Two rules inherited from #257 are made visible here rather than merely
/// obeyed:
///
/// - **The total shown is the total that will be logged.** Remove an item and
///   the total follows, because `EstimateSucceeded`'s macro getters are
///   computed over `items` rather than stored.
/// - **An unidentified token is shown, never dropped.** A silently ignored
///   `לחם` turns a 40 g-carb meal into a 2 g one and the day still reads
///   compliant.
class EstimateReviewList extends StatelessWidget {
  const EstimateReviewList({
    required this.items,
    required this.unidentified,
    required this.onRemove,
    super.key,
  });

  final List<EstimatedItem> items;

  /// Tokens the estimator could not identify. Rendered in the same list,
  /// greyed and marked — never hidden and never behind a "show more".
  final List<String> unidentified;

  /// Called with the index of the item to drop.
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(AddMealCopy.reviewTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < items.length; i++) _row(context, i, items[i]),
        for (final token in unidentified) _unidentifiedRow(context, token),
        if (unidentified.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            AddMealCopy.unidentifiedWarning,
            key: const Key('estimate_unidentified_warning'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const Divider(height: 24),
        _totalRow(context),
      ],
    );
  }

  Widget _row(BuildContext context, int index, EstimatedItem item) {
    final theme = Theme.of(context);

    return Padding(
      key: Key('estimate_item_$index'),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name),
                Text(
                  _detail(item),
                  // Digit runs, not prose: without this the grams and the
                  // three macros are reordered inside the RTL layout.
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            key: Key('estimate_item_remove_$index'),
            tooltip: AddMealCopy.removeItem,
            icon: const Icon(Icons.close),
            onPressed: () => onRemove(index),
          ),
        ],
      ),
    );
  }

  Widget _unidentifiedRow(BuildContext context, String token) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(token, style: TextStyle(color: muted)),
          ),
          Text(
            AddMealCopy.unidentifiedMarker,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }

  /// The total row wraps rather than overflowing.
  ///
  /// A `Wrap`, not a `Row`: at 320 px the label and a three-macro figure do
  /// not fit on one line, and a `Row` with an unconstrained second child
  /// paints a yellow stripe instead of moving it down. Measured — the first
  /// draft overflowed by 145 px.
  Widget _totalRow(BuildContext context) => Wrap(
    key: const Key('estimate_total_row'),
    alignment: WrapAlignment.spaceBetween,
    spacing: 12,
    runSpacing: 4,
    children: [
      Text(AddMealCopy.total, style: Theme.of(context).textTheme.titleSmall),
      Text(
        _macros(fatG, netCarbsG, proteinG),
        textDirection: TextDirection.ltr,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    ],
  );

  /// `100 גרם · שומן 10 · פחמימות 1 · חלבון 13`.
  String _detail(EstimatedItem item) =>
      '${GramsText.format(item.grams)} גרם · '
      '${_macros(item.fatG, item.netCarbsG, item.proteinG)}';

  static String _macros(double fat, double netCarbs, double protein) =>
      'שומן ${GramsText.format(fat)} · '
      'פחמימות ${GramsText.format(netCarbs)} · '
      'חלבון ${GramsText.format(protein)}';

  /// Summed over what is *still in the list*, never over what arrived.
  double get fatG => _sum((item) => item.fatG);

  double get netCarbsG => _sum((item) => item.netCarbsG);

  double get proteinG => _sum((item) => item.proteinG);

  double _sum(double Function(EstimatedItem) of) =>
      items.fold<double>(0, (total, item) => total + of(item));
}
