import 'package:flutter/material.dart';

/// A placeholder block in the shape of content that has not loaded.
///
/// ## Why this does not animate
///
/// `design/architecture.md` asks for a shimmer, and a shimmer is exactly the
/// hazard `design/m6_handoff.md` records: **an indeterminate animation on a tab
/// screen hangs `pumpAndSettle`**, which never returns while one runs, and the
/// app-level router tests visit every tab knowing nothing about what is on it.
/// Two router tests went red before that was found, and `CameraScreen`'s
/// opening state is a static icon for the same reason.
///
/// Swapping a spinner for a shimmer changes nothing about that and makes it
/// worse — a shimmer covers more of the screen, and more screens. A bounded
/// repeat is no better in the harness: `pumpAndSettle` still waits out every
/// cycle on every test that renders one, and a shimmer frozen mid-sweep reads
/// as broken content rather than as loading.
///
/// So these are static, and the shape carries the meaning: a skeleton in the
/// outline of the content it stands in for reads as loading without moving.
/// The gain is not only neutral — `pumpAndSettle` now **settles** on screens
/// where it previously could not (#88).
///
/// Colours come from the theme, never from `Colors.grey`: the palette is
/// dark-mode first and a light-mode grey is invisible on `#1C1C1E`.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = defaultRadius,
    super.key,
  });

  /// A circular placeholder of [dimension] across.
  const SkeletonBox.circle({required double dimension, super.key})
    : width = dimension,
      height = dimension,
      borderRadius = dimension / 2;

  static const double defaultRadius = 8;

  /// Pass `double.infinity` for a full-width bar.
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      // A tint of the foreground over whatever sits behind it, rather than
      // `surfaceContainerHighest`: on this palette that role lands within a
      // few points of `AppTheme.surface`, so a skeleton on a card would be
      // invisible. This contrasts by construction on any ground.
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(borderRadius),
    ),
    child: SizedBox(width: width, height: height),
  );
}
