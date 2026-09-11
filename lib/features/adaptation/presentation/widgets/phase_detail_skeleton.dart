import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

/// Three stepper rows, standing in for the phase detail body.
///
/// Three because `AdaptationPhase` has exactly three values, so this is the
/// real height rather than an approximation of it.
class PhaseDetailSkeleton extends StatelessWidget {
  const PhaseDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [_StepRow(), _StepRow(), _StepRow()],
    ),
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox.circle(dimension: 24),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBox(width: 160, height: 16),
              SizedBox(height: 8),
              SkeletonBox(width: double.infinity, height: 12),
            ],
          ),
        ),
      ],
    ),
  );
}
