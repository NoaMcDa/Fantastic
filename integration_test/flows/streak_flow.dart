import 'package:fantastic/features/adaptation/data/providers.dart';
import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';
import 'package:fantastic/features/adaptation/presentation/widgets/streak_ring_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

/// F5 (#97) — a compliant day drives the adaptation state machine.
void main() {
  testWidgets('a compliant day takes the streak to 1 and stays in phase 1', (
    tester,
  ) async {
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    // Day zero.
    expect(
      find.descendant(
        of: find.byType(StreakRingWidget),
        matching: find.text('0'),
      ),
      findsOneWidget,
    );

    // Net carbs 2, comfortably inside the 50 g limit the streak measures.
    // The keto ratio these macros imply is no longer what decides this — see
    // `DayCompliance` and #303.
    await openAddMeal(tester);
    await enterInto(tester, 'meal_name_field', 'אבוקדו וחמאה');
    await enterInto(tester, 'fat_field', '50');
    await enterInto(tester, 'carbs_field', '2');
    await enterInto(tester, 'protein_field', '3');
    await tapAt(tester, find.byKey(const Key('save_meal_button')));

    // Scoped to the ring: a dashboard full of macro numbers has plenty of
    // other `1`s, which is why #97's bare `find.text('1')` cannot work.
    expect(
      find.descendant(
        of: find.byType(StreakRingWidget),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    // Scrolled to: the macro card above it grew a training-day chip, and a
    // sliver child below the fold has no element at all
    // (`design/m5_handoff.md`).
    await scrollDown(tester);
    expect(find.text('שלב ההסתגלות'), findsOneWidget);

    final streak = await app.container.read(streakRepositoryProvider).load();
    expect(streak!.currentStreak, 1);
    expect(streak.phase, AdaptationPhase.induction);
    expect(streak.inGracePeriod, isFalse);
  });

  testWidgets('a second meal on the same day does not increment again', (
    tester,
  ) async {
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    for (final name in ['ארוחה ראשונה', 'ארוחה שנייה']) {
      await openAddMeal(tester);
      await enterInto(tester, 'meal_name_field', name);
      await enterInto(tester, 'fat_field', '40');
      await enterInto(tester, 'carbs_field', '2');
      await enterInto(tester, 'protein_field', '5');
      await tapAt(tester, find.byKey(const Key('save_meal_button')));
    }

    // The streak counts days, not meals — the defect `m3_preflight.md` §1.2
    // caught in the issue text, asserted here through the UI that would
    // show it.
    final streak = await app.container.read(streakRepositoryProvider).load();
    expect(streak!.currentStreak, 1);
    expect(
      find.descendant(
        of: find.byType(StreakRingWidget),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('back-filling a missed day repairs the streak across the gap', (
    tester,
  ) async {
    // The retroactive path, which shipped inert: `MealLoggingService` dropped
    // any evaluation of a day that was not today, so back-filling a forgotten
    // day repainted the calendar and left the streak exactly as broken as it
    // was (#303, clause 3).
    //
    // `design/user_bugs_handoff.md`'s first lesson applies directly — every
    // other streak flow logs to *today* only, which is precisely why a whole
    // capability shipped untested.
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    final today = DateTime.now();
    DateTime daysBefore(int n) =>
        DateTime(today.year, today.month, today.day - n);

    Future<void> logCompliantMealOn(DateTime date) async {
      await goToTab(tester, 'tab_diary');
      await tapAt(
        tester,
        find.byKey(Key('date_chip_${date.year}_${date.month}_${date.day}')),
      );
      await openAddMeal(tester, fabKey: 'add_meal_fab_diary');
      await enterInto(tester, 'meal_name_field', 'סלט אבוקדו');
      await enterInto(tester, 'fat_field', '45');
      await enterInto(tester, 'carbs_field', '4');
      await enterInto(tester, 'protein_field', '20');
      await tapAt(tester, find.byKey(const Key('save_meal_button')));
    }

    Future<int> storedStreak() async {
      final state = await app.container.read(streakRepositoryProvider).load();
      return state?.currentStreak ?? 0;
    }

    // Today, then the day before yesterday — leaving yesterday empty.
    await logCompliantMealOn(today);
    await logCompliantMealOn(daysBefore(2));

    // The gap at yesterday stops the walk, so only today counts.
    expect(await storedStreak(), 1);
    await goToTab(tester, 'tab_home');
    expect(
      find.descendant(
        of: find.byType(StreakRingWidget),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );

    // Fill the gap. Nothing about today changed, and the streak still moves.
    await logCompliantMealOn(daysBefore(1));

    expect(await storedStreak(), 3);
    await goToTab(tester, 'tab_home');
    expect(
      find.descendant(
        of: find.byType(StreakRingWidget),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });
}
