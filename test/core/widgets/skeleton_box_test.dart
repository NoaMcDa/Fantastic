import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/core/widgets/skeleton_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  BoxDecoration decorationOf(WidgetTester tester) =>
      tester.widget<DecoratedBox>(find.byType(DecoratedBox)).decoration
          as BoxDecoration;

  testWidgets('occupies exactly the size it was given', (tester) async {
    await pumpApp(
      tester,
      const Center(child: SkeletonBox(width: 120, height: 16)),
    );

    expect(tester.getSize(find.byType(SkeletonBox)), const Size(120, 16));
  });

  testWidgets('a circle is round, at the dimension given', (tester) async {
    await pumpApp(
      tester,
      const Center(child: SkeletonBox.circle(dimension: 140)),
    );

    expect(tester.getSize(find.byType(SkeletonBox)), const Size(140, 140));
    expect(decorationOf(tester).borderRadius, BorderRadius.circular(70));
  });

  // Hardcoded greys vanish against the dark-mode-first palette. The original
  // issue's snippet used `Colors.grey.shade300`, which is a light-mode value.
  testWidgets('takes its colour from the theme, not a literal grey', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const Center(child: SkeletonBox(width: 100, height: 10)),
    );

    final context = tester.element(find.byType(SkeletonBox));
    final painted = decorationOf(tester).color;

    expect(
      painted,
      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
    );
    expect(painted, isNot(Colors.grey));
    expect(painted, isNot(Colors.grey.shade300));
  });

  // `surfaceContainerHighest` is the obvious role and lands within a few
  // points of `AppTheme.surface` on this palette, which would make a skeleton
  // on a card invisible. A foreground tint contrasts by construction.
  testWidgets('is visible against the card colour it sits on', (tester) async {
    await pumpApp(
      tester,
      const Card(child: SkeletonBox(width: 100, height: 10)),
    );

    final painted = decorationOf(tester).color!;
    const surface = AppTheme.surface;
    final distance =
        (painted.r - surface.r).abs() +
        (painted.g - surface.g).abs() +
        (painted.b - surface.b).abs();

    expect(distance, greaterThan(0.05), reason: 'painted $painted vs $surface');
  });

  // The whole point: a static placeholder settles, where an indeterminate
  // animation never lets `pumpAndSettle` return.
  testWidgets('settles — it does not animate', (tester) async {
    await pumpApp(
      tester,
      const Center(child: SkeletonBox(width: 100, height: 10)),
    );

    await tester.pumpAndSettle();

    expect(find.byType(SkeletonBox), findsOneWidget);
  });
}
