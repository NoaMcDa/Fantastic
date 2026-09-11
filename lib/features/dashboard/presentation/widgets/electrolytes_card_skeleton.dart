import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

/// The shape of [ElectrolytesCard] before its day resolves: a header and
/// three gauges.
class ElectrolytesCardSkeleton extends StatelessWidget {
  const ElectrolytesCardSkeleton({super.key});

  /// Sodium, potassium, magnesium.
  static const int _gauges = 3;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SkeletonBox(width: 110, height: 20),
          const SizedBox(height: 20),
          for (var i = 0; i < _gauges; i++)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SkeletonBox(width: 80, height: 12),
                  SizedBox(height: 8),
                  SkeletonBox(
                    width: double.infinity,
                    height: 8,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
