import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:flutter/material.dart';

/// What a mode that has no flow behind it yet shows.
///
/// A real widget with real Hebrew copy rather than a `TODO`: a mode that
/// does nothing when tapped reads as a bug, and `issue_conventions.md`
/// forbids the comment anyway. Both placeholders share it so the two say the
/// same thing, and so deleting it when the second flow lands is one step.
///
/// Deliberately static — no spinner, no animation. An indeterminate
/// `CircularProgressIndicator` on a sheet reachable from a tab screen never
/// lets `pumpAndSettle` return (`design/m6_handoff.md`).
class ComingSoonSheet extends StatelessWidget {
  const ComingSoonSheet({required this.title, super.key});

  /// The mode's own name, so the sheet says which one is coming.
  final String title;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String sheetKey,
  }) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => ComingSoonSheet(title: title, key: Key(sheetKey)),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            const Text(AddMealCopy.comingSoon, key: Key('coming_soon_message')),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('coming_soon_close'),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AddMealCopy.close),
            ),
          ],
        ),
      ),
    );
  }
}
