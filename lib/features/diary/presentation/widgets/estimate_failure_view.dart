import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:flutter/material.dart';

/// One headline, one explanation and one way out per failure reason.
///
/// Per reason rather than generic, for the reason `ScanFailureReason`
/// established: "turn it on in settings" and "you are offline" are not the
/// same problem, and a user told only that something failed has nothing to
/// do next. **Every one of them also offers manual entry**, so no failure is
/// a dead end and nothing typed is discarded.
///
/// Shared by the description and photo modes rather than copied into each.
/// The failure vocabulary is identical — the same seven reasons come back
/// from the same estimator — and two copies would be two chances to word one
/// of them differently. Only [retryLabel] differs: retyping a description
/// and re-sending the *same* unreadable photograph are not the same offer.
class EstimateFailureView extends StatelessWidget {
  const EstimateFailureView({
    required this.reason,
    required this.onRetry,
    required this.onManual,
    required this.onProfile,
    this.retryLabel = AddMealCopy.retry,
    super.key,
  });

  final EstimateFailureReason reason;
  final VoidCallback onRetry;
  final Future<void> Function() onManual;
  final VoidCallback onProfile;

  /// What the retry control says. The photo mode offers "try another photo",
  /// because re-sending the same unreadable file would fail identically.
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const Key('estimate_failure'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _headline,
          key: const Key('estimate_failure_headline'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        if (_detail != null) ...[
          const SizedBox(height: 4),
          Text(_detail!, style: theme.textTheme.bodySmall),
        ],
        const SizedBox(height: 12),
        if (_offersRetry)
          OutlinedButton(
            key: const Key('estimate_retry_button'),
            onPressed: onRetry,
            child: Text(retryLabel),
          ),
        if (_offersProfile)
          OutlinedButton(
            key: const Key('estimate_profile_button'),
            onPressed: onProfile,
            child: const Text(AddMealCopy.openProfile),
          ),
        const SizedBox(height: 8),
        TextButton(
          key: const Key('estimate_manual_button'),
          onPressed: () => onManual(),
          child: const Text(AddMealCopy.enterManually),
        ),
      ],
    );
  }

  String get _headline => switch (reason) {
    // Unreachable in this sheet — the estimate button is disabled on an
    // empty field — and worded anyway, because an unhandled case would be a
    // blank headline rather than a compile error.
    EstimateFailureReason.emptyInput => AddMealCopy.failedEmptyInput,
    EstimateFailureReason.notConfigured => AddMealCopy.failedNotConfigured,
    EstimateFailureReason.offline => AddMealCopy.failedOffline,
    EstimateFailureReason.rateLimited => AddMealCopy.failedRateLimited,
    EstimateFailureReason.unauthorised => AddMealCopy.failedUnauthorised,
    EstimateFailureReason.badResponse => AddMealCopy.failedBadResponse,
    EstimateFailureReason.nothingIdentified =>
      AddMealCopy.failedNothingIdentified,
  };

  String? get _detail => switch (reason) {
    EstimateFailureReason.rateLimited => AddMealCopy.rateLimitDetail,
    EstimateFailureReason.nothingIdentified =>
      AddMealCopy.nothingIdentifiedDetail,
    _ => null,
  };

  /// Retry is offered only where retrying could plausibly work.
  ///
  /// Not for a missing or rejected key: the same request would fail the same
  /// way, and a button that cannot help is worse than no button.
  bool get _offersRetry => switch (reason) {
    EstimateFailureReason.offline ||
    EstimateFailureReason.badResponse ||
    EstimateFailureReason.nothingIdentified => true,
    _ => false,
  };

  bool get _offersProfile =>
      reason == EstimateFailureReason.notConfigured ||
      reason == EstimateFailureReason.unauthorised;
}
