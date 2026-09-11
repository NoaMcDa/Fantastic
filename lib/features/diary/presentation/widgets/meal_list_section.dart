import 'dart:async';

import 'package:fantastic/features/dashboard/application/providers/daily_log_providers.dart';
import 'package:fantastic/features/diary/application/meal_logging_service.dart';
import 'package:fantastic/features/diary/application/providers/meal_providers.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/meal_card.dart';
import 'package:fantastic/features/diary/presentation/widgets/meal_list_section_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The day's meals, each swipeable to delete.
///
/// A `Column`, not a `ListView`: this sits inside the dashboard's outer scroll
/// view, and a nested scrollable would either fight it for gestures or need a
/// fixed height it has no way to know.
///
/// Stateful only to track rows already swiped away — see [_dismissedIds].
class MealListSection extends ConsumerStatefulWidget {
  const MealListSection({required this.date, super.key});

  /// Pass a date-only value — `todaysMealsProvider` is keyed on it.
  final DateTime date;

  @override
  ConsumerState<MealListSection> createState() => _MealListSectionState();
}

class _MealListSectionState extends ConsumerState<MealListSection> {
  /// Ids swiped away but still present in the provider's last value.
  ///
  /// `Dismissible` asserts that a dismissed child leaves the tree immediately,
  /// but deleting is asynchronous: the delete and the refetch both have to
  /// complete before the list stops containing the row, and the widget
  /// rebuilds well before that. Hiding the id on dismissal closes that gap —
  /// and stops the row visibly flashing back mid-refetch.
  ///
  /// Entries are dropped once the refetched list no longer contains them, so
  /// this cannot grow without bound.
  final Set<int> _dismissedIds = {};

  @override
  Widget build(BuildContext context) {
    final mealsAsync = ref.watch(todaysMealsProvider(widget.date));

    // `hasError` first, and `AsyncValue.when` deliberately not used at all.
    //
    // riverpod 3 reports a provider that failed *before ever producing a
    // value* as `AsyncLoading` **with an error attached** — both flags are
    // true — and `when` is loading-first, so this section spun forever on a
    // storage failure while the macro card and the symptom strip either side
    // of it reported the failure correctly. That is
    // `design/m8_preflight.md` Part 10 defect 2, and it sits directly under
    // the add-meal button: the user was left watching a spinner with no way
    // to tell a broken store from a slow one.
    //
    // Says the read failed rather than rendering nothing: an empty list and a
    // failed load look identical otherwise, and mean opposite things.
    if (mealsAsync.hasError) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: Text('לא ניתן לטעון את הארוחות')),
      );
    }

    if (!mealsAsync.hasValue) {
      return const MealListSectionSkeleton();
    }

    // No empty-state widget here — MacroSummaryCard above already shows one
    // for a day with nothing logged, and two would stack.
    return _buildList(mealsAsync.requireValue);
  }

  Widget _buildList(List<MealEntry> meals) {
    _pruneDismissed(meals);
    final visible = meals.where((m) => !_isHidden(m)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (final meal in visible) _dismissible(meal)],
    );
  }

  bool _isHidden(MealEntry meal) =>
      meal.id != null && _dismissedIds.contains(meal.id);

  /// Forgets ids the refetch has confirmed gone.
  void _pruneDismissed(List<MealEntry> meals) {
    final present = meals.map((m) => m.id).whereType<int>().toSet();
    _dismissedIds.removeWhere((id) => !present.contains(id));
  }

  Widget _dismissible(MealEntry meal) {
    final id = meal.id;
    // An unsaved meal has no id and nothing to delete by. It cannot normally
    // reach this list — every entry here came from the repository — but
    // rendering it un-dismissible beats `meal.id!` throwing inside a build.
    if (id == null) {
      return MealCard(meal: meal);
    }

    return Dismissible(
      // Keyed by id, not by index: dismissing re-orders the list, and an index
      // key would leave Flutter animating the wrong row out.
      key: ValueKey(id),
      direction: DismissDirection.endToStart,
      background: const _DeleteBackground(),
      onDismissed: (_) {
        setState(() => _dismissedIds.add(id));
        unawaited(_delete(id));
      },
      child: MealCard(meal: meal, onTap: () => _edit(meal)),
    );
  }

  /// Opens the edit sheet for [meal], then refreshes what the edit touched.
  ///
  /// The meal's **own** day, not `widget.date`: they are the same today and
  /// differ the moment a meal is edited from a list showing another day, and
  /// the sheet stamps and keys off what it is given.
  Future<void> _edit(MealEntry meal) async {
    await AddMealBottomSheet.show(context, date: widget.date, existing: meal);
    if (!mounted) {
      return;
    }
    // Both, for the reason the delete path invalidates both: the list is what
    // the user is looking at and the macro totals above it are stale too.
    ref
      ..invalidate(todaysMealsProvider(widget.date))
      ..invalidate(todaysDailyLogProvider(widget.date));
  }

  Future<void> _delete(int id) async {
    await ref.read(mealLoggingServiceProvider).deleteMeal(id, widget.date);
    if (!mounted) {
      return;
    }
    // Both, and after the delete: the list is what the user is looking at, and
    // the macro totals above it are stale too. The refetch also self-heals a
    // delete that failed — the row comes back and leaves [_dismissedIds].
    ref
      ..invalidate(todaysMealsProvider(widget.date))
      ..invalidate(todaysDailyLogProvider(widget.date));
  }
}

/// The panel revealed behind a row being swiped away.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      // An `endToStart` dismissal slides the row toward the start edge, so the
      // panel behind it is revealed at the *end*. Directional alignment rather
      // than `Alignment.centerRight`: end is the right in LTR and the left in
      // RTL, and this app runs RTL.
      alignment: AlignmentDirectional.centerEnd,
      padding: const EdgeInsetsDirectional.only(end: 20),
      child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
    );
  }
}
