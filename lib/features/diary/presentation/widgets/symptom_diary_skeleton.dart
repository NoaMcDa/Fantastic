import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';

/// The five-scale strip's shape, before the day's symptom log resolves.
class SymptomDiarySkeleton extends StatelessWidget {
  const SymptomDiarySkeleton({super.key});

  /// One per `SymptomScale` value.
  static const int _scales = 5;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _scales; i++)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _ScaleRow(),
          ),
      ],
    ),
  );
}

class _ScaleRow extends StatelessWidget {
  const _ScaleRow();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      SkeletonBox(width: 80, height: 12),
      SizedBox(width: 12),
      Expanded(child: SkeletonBox(width: double.infinity, height: 12)),
    ],
  );
}
