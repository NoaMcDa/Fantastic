import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

/// The shape of [MacroSummaryCard] before its providers resolve.
///
/// A header line and three macro rows, at the real card's rhythm, so the
/// dashboard does not jump when the figures arrive. Presentational only — no
/// provider access, Epic #11's invariant.
class MacroSummaryCardSkeleton extends StatelessWidget {
  const MacroSummaryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonBox(width: 120, height: 20),
          SizedBox(height: 20),
          _MacroRow(),
          SizedBox(height: 16),
          _MacroRow(),
          SizedBox(height: 16),
          _MacroRow(),
        ],
      ),
    ),
  );
}

/// A label line above the bar it labels, matching `_MacroProgressRow`.
class _MacroRow extends StatelessWidget {
  const _MacroRow();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      SkeletonBox(width: 90, height: 12),
      SizedBox(height: 8),
      SkeletonBox(width: double.infinity, height: 8, borderRadius: 4),
    ],
  );
}
