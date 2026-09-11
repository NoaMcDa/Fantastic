import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

/// The `+` → chooser → manual → saved route, from **both** hosts.
///
/// `design/user_bugs_handoff.md` records why this flow is worth its runtime
/// rather than being covered by `meal_logging_flow`: the first defect a real
/// user hit was the diary's empty state telling them to tap a `+` the diary
/// did not have, while 1,220 tests, a 99.58% coverage gate, ten e2e flows and
/// six platform builds were green. Its lesson — *"a flow that exercises one
/// route to a capability is not a test that the capability is reachable"* — is
/// the reason each host is driven separately here.
void main() {
  testWidgets('the dashboard + offers all three modes', (tester) async {
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    await tapAt(tester, find.byKey(const Key('add_meal_fab')));

    expect(find.byKey(const Key('add_meal_mode_manual')), findsOneWidget);
    expect(find.byKey(const Key('add_meal_mode_description')), findsOneWidget);
    expect(find.byKey(const Key('add_meal_mode_photo')), findsOneWidget);
    expect(find.text(AddMealCopy.manualSubtitle), findsOneWidget);
  });

  // The host that shipped without the affordance at all.
  testWidgets('the diary + offers all three modes too', (tester) async {
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    await goToTab(tester, 'tab_diary');
    await tapAt(tester, find.byKey(const Key('add_meal_fab_diary')));

    expect(find.byKey(const Key('add_meal_mode_manual')), findsOneWidget);
    expect(find.byKey(const Key('add_meal_mode_description')), findsOneWidget);
    expect(find.byKey(const Key('add_meal_mode_photo')), findsOneWidget);
  });

  testWidgets('manual entry saves a meal with no provenance badge', (
    tester,
  ) async {
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    await openAddMeal(tester);
    await enterInto(tester, 'meal_name_field', 'סלמון בחמאה');
    await enterInto(tester, 'fat_field', '28');
    await enterInto(tester, 'carbs_field', '0');
    await enterInto(tester, 'protein_field', '34');
    await tapAt(tester, find.byKey(const Key('save_meal_button')));

    await scrollDown(tester);
    expect(find.text('סלמון בחמאה'), findsOneWidget);
    // A meal the user typed needs no explanation, and a badge on every card
    // is a badge nobody reads.
    expect(find.byKey(const Key('meal_card_source_badge')), findsNothing);

    final log = await app.container
        .read(dailyLogRepositoryProvider)
        .findByDate(DateTime.now());
    expect(log!.totalFatG, 28);
    expect(log.totalProteinG, 34);

    final meals = await app.container
        .read(mealRepositoryProvider)
        .findByDate(DateTime.now());
    expect(meals.single.source.name, 'manual');
  });

  testWidgets('dismissing the chooser saves nothing', (tester) async {
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    await tapAt(tester, find.byKey(const Key('add_meal_fab')));
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);

    expect(find.byKey(const Key('meal_name_field')), findsNothing);
    final meals = await app.container
        .read(mealRepositoryProvider)
        .findByDate(DateTime.now());
    expect(meals, isEmpty);
  });

  // The diary's `+` carries the *selected* day, which is what the sheet's
  // date-keyed providers are families on.
  testWidgets('the diary + logs against the selected day, not today', (
    tester,
  ) async {
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    await goToTab(tester, 'tab_diary');
    await tapAt(
      tester,
      find.byKey(
        Key('date_chip_${yesterday.year}_${yesterday.month}_${yesterday.day}'),
      ),
    );
    await openAddMeal(tester, fabKey: 'add_meal_fab_diary');
    await enterInto(tester, 'meal_name_field', 'אתמול');
    await enterInto(tester, 'fat_field', '10');
    await enterInto(tester, 'carbs_field', '2');
    await enterInto(tester, 'protein_field', '5');
    await tapAt(tester, find.byKey(const Key('save_meal_button')));

    final stored = await app.container
        .read(mealRepositoryProvider)
        .findByDate(yesterday);
    expect(stored, hasLength(1));
    expect(stored.single.mealName, 'אתמול');

    // And today stayed empty.
    final todaysMeals = await app.container
        .read(mealRepositoryProvider)
        .findByDate(DateTime.now());
    expect(todaysMeals, isEmpty);
  });
}
