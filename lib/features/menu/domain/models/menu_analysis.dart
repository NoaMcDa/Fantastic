import 'package:fantastic/core/utils/list_equality.dart';
import 'package:fantastic/features/menu/domain/models/analysed_dish.dart';
import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis_failure_reason.dart';
import 'package:meta/meta.dart';

/// What one analysis attempt produced.
///
/// ## Why this is sealed
///
/// The same reason `ScanResult` and `MealEstimate` are. `design/m6_preflight.md`
/// §1.1 records a failed scan that would have been reported as `Clean Keto`
/// — a user in a shop told a product was safe because the app could not read
/// its label. A menu analyser has the same shape of failure with a wider
/// mouth: no key, offline, rate-limited, OCR unavailable, nothing
/// recognised, or the model returned nonsense. None of those may reach the
/// screen as a verdict. A `switch` over [MenuAnalysis] does not compile until
/// the failure case is handled.
@immutable
sealed class MenuAnalysis {
  const MenuAnalysis();
}

/// An attempt that reached at least one dish, or at least one unclassified
/// name.
@immutable
final class MenuAnalysed extends MenuAnalysis {
  const MenuAnalysed({
    required this.dishes,
    this.unclassified = const [],
    this.pageCount = 0,
    this.unreadPages = const [],
  });

  /// Every dish that earned a verdict, in the order the model listed them.
  ///
  /// May be empty only when [unclassified] is not — "saw dishes, placed
  /// none" is a result the user should see, not a failure they should retry.
  final List<AnalysedDish> dishes;

  /// Names the model listed but could not place, or that failed a parser
  /// rule. Reported, never dropped.
  final List<String> unclassified;

  /// How many pages were read. 0 for pasted text.
  final int pageCount;

  /// 1-based page numbers OCR ran on and read nothing from.
  final List<int> unreadPages;

  /// Whether something about this result is incomplete: a page OCR could not
  /// read, or a name the model could not place.
  bool get isPartial => unreadPages.isNotEmpty || unclassified.isNotEmpty;

  /// [dishes] filtered to [verdict], in the model's original order.
  List<AnalysedDish> withVerdict(DishVerdict verdict) =>
      dishes.where((dish) => dish.verdict == verdict).toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuAnalysed &&
          // Element-wise: two results with equal-but-not-identical lists are
          // equal. A plain `==` on List compares identity.
          listEquals(other.dishes, dishes) &&
          listEquals(other.unclassified, unclassified) &&
          other.pageCount == pageCount &&
          listEquals(other.unreadPages, unreadPages);

  @override
  int get hashCode => Object.hash(
    listHash(dishes),
    listHash(unclassified),
    pageCount,
    listHash(unreadPages),
  );
}

/// An attempt that did not reach a verdict at all.
@immutable
final class MenuAnalysisFailed extends MenuAnalysis {
  const MenuAnalysisFailed({required this.reason, this.statusCode});

  /// Which failure it was. The screen's copy and its retry affordance both
  /// key off this.
  final MenuAnalysisFailureReason reason;

  /// The HTTP status the model provider answered with, when the failure
  /// came from an answer at all; null for every failure that did not (no
  /// key, offline, timeout, nothing recognised, a bad reply shape).
  ///
  /// Shown beneath the headline as a small technical line, because
  /// [MenuAnalysisFailureReason.badResponse] covers a refused request, a
  /// retired model id and an unusable answer alike, and a user who reports
  /// "הניתוח נכשל" cannot otherwise tell us which. It changes no copy, no
  /// retry affordance and no verdict.
  final int? statusCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuAnalysisFailed &&
          other.reason == reason &&
          other.statusCode == statusCode;

  @override
  int get hashCode => Object.hash(reason, statusCode);
}
