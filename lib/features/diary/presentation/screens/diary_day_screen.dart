import 'package:fantastic/features/dashboard/presentation/widgets/macro_summary_card.dart';
import 'package:fantastic/features/diary/presentation/widgets/meal_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Everything recorded for one calendar date: the day's macro summary, its
/// meals, and a placeholder for the symptom check-in M5 adds.
///
/// Takes its date as a parameter and passes it straight down — no provider
/// override, no state of its own. That is what lets the same widget serve
/// today and any past day.
class DiaryDayScreen extends ConsumerWidget {
  const DiaryDayScreen({required this.date, super.key});

  /// Pass a date-only value — the providers below are families keyed on it.
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MacroSummaryCard(date: date),
          const SizedBox(height: 16),
          MealListSection(date: date),
          const SizedBox(height: 16),
          const _SymptomsPlaceholder(),
        ],
      ),
    );
  }
}

/// Stands in for the symptom check-in until M5 (#75–#78) builds it.
///
/// A named widget rather than a bare `Text` so the swap is a one-line change
/// here, and so a test can assert the slot exists without matching on copy
/// that is going to be replaced.
class _SymptomsPlaceholder extends StatelessWidget {
  const _SymptomsPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'תסמינים — בקרוב',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
