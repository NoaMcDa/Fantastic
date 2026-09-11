import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

/// Three meal-card-shaped rows, standing in for the day's meal list.
///
/// Three rather than one: a single row would leave the section shorter than
/// almost any real day, and a skeleton smaller than its content makes the
/// screen jump on load — which is worse than a spinner, not better.
class MealListSectionSkeleton extends StatelessWidget {
  const MealListSectionSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [_MealRow(), _MealRow(), _MealRow()],
    ),
  );
}

class _MealRow extends StatelessWidget {
  const _MealRow();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonBox(width: 140, height: 16),
          SizedBox(height: 10),
          SkeletonBox(width: 200, height: 12),
        ],
      ),
    ),
  );
}
