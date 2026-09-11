import 'package:fantastic/features/dashboard/presentation/widgets/macro_summary_card.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_fab.dart';
import 'package:fantastic/features/diary/presentation/widgets/meal_list_section.dart';
import 'package:fantastic/features/diary/presentation/widgets/symptom_diary_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Everything recorded for one calendar date: the day's macro summary, its
/// meals, and its symptom check-in.
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
      // Extra room at the bottom clears the add-meal FAB, which floats over
      // this body rather than displacing it — without it the symptom section
      // ends underneath the button.
      padding: const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + AddMealFab.bodyClearance,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MacroSummaryCard(date: date),
          const SizedBox(height: 16),
          MealListSection(date: date),
          const SizedBox(height: 16),
          SymptomDiarySection(date: date),
        ],
      ),
    );
  }
}
