import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/app_harness.dart';

/// F3 (#96) and F4 — the app's main write path, both directions.
void main() {
  testWidgets('logging a meal updates the day totals and the meal list', (
    tester,
  ) async {
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    await tapAt(tester, find.byKey(const Key('add_meal_fab')));
    await enterInto(tester, 'meal_name_field', 'ביצים וחמאה');
    await enterInto(tester, 'fat_field', '20');
    await enterInto(tester, 'carbs_field', '1');
    await enterInto(tester, 'protein_field', '12');
    await tapAt(tester, find.byKey(const Key('save_meal_button')));

    // The macro card, above the fold.
    expect(find.textContaining('20/'), findsOneWidget);

    // The meal row is a sliver child below the fold — until the page is
    // dragged it has no element at all, and `find.text` returns zero rather
    // than "off-screen" (`design/m8_preflight.md` §6.3).
    expect(find.text('ביצים וחמאה'), findsNothing);
    await scrollDown(tester);
    expect(find.text('ביצים וחמאה'), findsOneWidget);

    // The day's totals really were rolled up, not just rendered from the
    // sheet's own state.
    final log = await app.container
        .read(dailyLogRepositoryProvider)
        .findByDate(DateTime.now());
    expect(log, isNotNull);
    expect(log!.totalFatG, 20);
    expect(log.totalNetCarbsG, 1);
    expect(log.totalProteinG, 12);
  });

  testWidgets('deleting a meal recomputes the day totals', (tester) async {
    final app = await bootApp(onboarded: true);
    await pumpApp(tester, app);

    await tapAt(tester, find.byKey(const Key('add_meal_fab')));
    await enterInto(tester, 'meal_name_field', 'אבוקדו');
    await enterInto(tester, 'fat_field', '30');
    await enterInto(tester, 'carbs_field', '2');
    await enterInto(tester, 'protein_field', '3');
    await tapAt(tester, find.byKey(const Key('save_meal_button')));

    await scrollDown(tester);
    expect(find.text('אבוקדו'), findsOneWidget);

    // `endToStart` in an RTL layout drags *rightward* — the trap that cost
    // M2 the most time (`design/m2_handoff.md`).
    await tester.drag(find.byType(Dismissible), const Offset(500, 0));
    await settle(tester);

    expect(find.text('אבוקדו'), findsNothing);

    // The row goes first and the delete lands after: `MealListSection`
    // dismisses optimistically because `Dismissible` asserts that a
    // dismissed child leaves the tree immediately. Asserting on storage on
    // the next frame reads the meal still there.
    await waitFor(
      tester,
      () async =>
          (await app.container
                  .read(mealRepositoryProvider)
                  .findByDate(DateTime.now()))
              .isEmpty,
      reason: 'the dismissed meal was never deleted from storage',
    );

    // The recalculation is the half a delete can silently skip: the meal
    // disappears from the list while the day's totals keep its macros.
    await waitFor(
      tester,
      () async =>
          ((await app.container
                      .read(dailyLogRepositoryProvider)
                      .findByDate(DateTime.now()))
                  ?.totalFatG ??
              0) ==
          0,
      reason: "the day's totals still carry the deleted meal's fat",
    );
  });
}
