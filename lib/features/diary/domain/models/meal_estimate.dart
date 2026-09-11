import 'package:fantastic/core/utils/list_equality.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:meta/meta.dart';

/// What an estimation attempt produced.
///
/// ## Why this is sealed
///
/// The same reason `ScanResult` is. #83 specified reporting a failed scan as
/// `Clean Keto`, which would have told a user standing in a shop that a
/// product was keto-safe **because the app could not read its label**;
/// `design/m6_preflight.md` §1.1 calls it the most dangerous defect the M6
/// audit found, and the fix was structural rather than careful.
///
/// An estimator has the same shape of failure with a wider mouth — no key, no
/// network, rate-limited, malformed, or nothing recognised — and none of those
/// may reach the diary as a number. A `switch` over [MealEstimate] does not
/// compile until the failure case is handled.
@immutable
sealed class MealEstimate {
  const MealEstimate();
}

/// An attempt that identified at least one food.
@immutable
final class EstimateSucceeded extends MealEstimate {
  const EstimateSucceeded({required this.items, this.unidentified = const []});

  /// Every food the estimator named, in the order it named them.
  ///
  /// Never empty: an attempt that identified nothing is an [EstimateFailed]
  /// carrying [EstimateFailureReason.nothingIdentified], because "zero items"
  /// and "zero macros" would otherwise be the same value.
  final List<EstimatedItem> items;

  /// Tokens the estimator could not identify.
  ///
  /// **Reported, never dropped.** A silently ignored `לחם` turns a 40 g-carb
  /// meal into a 2 g one, and the day still reads compliant — which is the
  /// failure mode the whole milestone is built to avoid.
  final List<String> unidentified;

  /// Summed over [items], never stored.
  ///
  /// A stored copy goes stale against what it was derived from — the same
  /// reasoning as `MealEntry.ketoRatio` — and it is what lets the review
  /// surface delete one item and have the totals follow.
  double get fatG => _sum((item) => item.fatG);

  double get netCarbsG => _sum((item) => item.netCarbsG);

  double get proteinG => _sum((item) => item.proteinG);

  /// Whether anything went unidentified. The review surface warns on this.
  bool get isPartial => unidentified.isNotEmpty;

  double _sum(double Function(EstimatedItem) of) =>
      items.fold<double>(0, (total, item) => total + of(item));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstimateSucceeded &&
          // Element-wise: two estimates with equal-but-not-identical lists are
          // equal. A plain `==` on List compares identity.
          listEquals(other.items, items) &&
          listEquals(other.unidentified, unidentified);

  @override
  int get hashCode => Object.hash(listHash(items), listHash(unidentified));
}

/// An attempt that produced no usable macros.
@immutable
final class EstimateFailed extends MealEstimate {
  const EstimateFailed({required this.reason});

  /// Which failure it was. The UI picks its copy and its button from this.
  final EstimateFailureReason reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstimateFailed && other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}
