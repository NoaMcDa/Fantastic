import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';

/// Estimates a meal's macros from what the user can give it.
///
/// The outermost seam of M15's estimation engine. Issue #312 decision 2: the
/// app calls a hosted model provider with the user's own key today and our
/// own backend later, and **that swap must be a new file rather than an
/// edit** — so a second implementation lands beside the first and only the
/// composition root names either.
///
/// Which provider is deliberately not named here. It is named in exactly two
/// files — `open_router_client.dart` and the one provider that constructs it
/// — and a domain interface that named it would be the first crack in the
/// invariant it exists to hold (#318).
abstract interface class MacroEstimator {
  /// Estimates the macros of a meal from a Hebrew [description], a photo at
  /// [imagePath], or both.
  ///
  /// **Never throws.** Every outcome, including every transport and provider
  /// failure, comes back as a [MealEstimate] — so no caller can mistake a
  /// failure for a result, and no caller needs a `try`/`catch` to stay
  /// correct. That is a contract the implementation is tested against, not a
  /// hope.
  ///
  /// Returns [EstimateFailed] with [EstimateFailureReason.emptyInput] when
  /// both arguments are null or the description is blank.
  ///
  /// One method with two optional arguments rather than two methods: the photo
  /// mode sends an image *and* an optional description in a single call, and
  /// splitting it would put the "which one do I call?" decision in the UI.
  Future<MealEstimate> estimate({String? description, String? imagePath});
}
