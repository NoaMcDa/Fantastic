import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/streak_ring_widget.dart';
import 'package:flutter/material.dart';

/// A circle at the ring's real diameter.
///
/// Sized rather than centred: the ring reserves a
/// [StreakRingWidget.diameter] square and the dashboard below is laid out
/// against it, so a skeleton that expanded to fill its parent would make the
/// screen jump when the arc arrives — which is worse than a spinner, not
/// better.
class StreakRingSkeleton extends StatelessWidget {
  const StreakRingSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.square(
    dimension: StreakRingWidget.diameter,
    child: SkeletonBox.circle(dimension: StreakRingWidget.diameter),
  );
}
