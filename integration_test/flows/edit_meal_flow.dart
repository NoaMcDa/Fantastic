import 'package:fantastic/features/dashboard/data/providers.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:fantastic/features/diary/domain/services/macro_estimator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../helpers/app_harness.dart';

class _FixedEstimator implements MacroEstimator {
  _FixedEstimator(this.result);

  final MealEstimate result;

  @override
  Future<MealEstimate> estimate({
    String? description,
    String? imagePath,
  }) async => result;
}

/// The route that only exists **after** something is saved, and the one no
/// add-flow can reach.
void main() {
  const estimate = EstimateSucceeded(
    items: [
      EstimatedItem(
        name: 'פיתה',
        grams: 60,
        fatG: 1,
        netCarbsG: 4,
        proteinG: 5,
      ),
    ],
  );

  Future<AppUnderTest> bootWithEstimate(WidgetTester tester) async {
    final app = await bootApp(
      onboarded: true,
      overrides: <Override>[
        macroEstimatorProvider.overrideWithValue(_FixedEstimator(estimate)),
      ],
    );
    await pumpApp(tester, app);
    return app;
  }

  /// Logs a meal through the description mode, so what lands on disk carries
  /// `MacroSource.estimatedFromText` and its card shows the badge.
  Future<void> logEstimatedMeal(WidgetTester tester, String name) async {
    await openAddMeal(tester, mode: 'add_meal_mode_description');
    await enterInto(tester, 'meal_description_field', 'פיתה');
    await tapAt(tester, find.byKey(const Key('estimate_button')));
    await tapAt(tester, find.byKey(const Key('estimate_confirm_button')));
    await enterInto(tester, 'meal_name_field', name);
    await tapAt(tester, find.byKey(const Key('save_meal_button')));
  }

  /// Brings the meal list back into view after a sheet has closed.
  ///
  /// Scrolling twice from wherever the page happens to be sitting overshoots;
  /// a sliver child past the viewport has no element at all, so the badge
  /// reads as absent rather than off-screen (`design/m5_handoff.md`).
  Future<void> revealMealList(WidgetTester tester) async {
    await tester.drag(
      find.byType(CustomScrollView).first,
      const Offset(0, 900),
    );
    await settle(tester);
    await scrollDown(tester);
  }

  Future<MealEntry> storedMeal(AppUnderTest app) async {
    final meals = await app.container
        .read(mealRepositoryProvider)
        .findByDate(DateTime.now());
    return meals.single;
  }

  // The model called a pitta 4 g of net carbs when it was 25. Before this
  // route existed the only move was to delete the entry and retype it,
  // losing the timestamp.
  testWidgets('correcting a macro updates the day and clears the badge', (
    tester,
  ) async {
    final app = await bootWithEstimate(tester);
    await logEstimatedMeal(tester, 'פיתה');

    await scrollDown(tester);
    expect(find.byKey(const Key('meal_card_source_badge')), findsOneWidget);
    final before = await storedMeal(app);
    expect(before.source, MacroSource.estimatedFromText);

    await tapAt(tester, find.text('פיתה'));

    // Prefilled from the stored meal, and saying it is an edit.
    expect(find.text('עריכת ארוחה'), findsOneWidget);
    expect(fieldText(tester, 'meal_name_field'), 'פיתה');
    expect(fieldText(tester, 'carbs_field'), '4');

    await enterInto(tester, 'carbs_field', '25');
    await tapAt(tester, find.byKey(const Key('save_meal_button')));

    final after = await storedMeal(app);
    expect(after.id, before.id, reason: 'an edit overwrites, never appends');
    expect(after.netCarbsG, 25);
    // A correction must not move the meal to now.
    expect(after.timestamp, before.timestamp);
    // Once a human has corrected the number, a badge still calling it a guess
    // is false.
    expect(after.source, MacroSource.manual);

    final log = await app.container
        .read(dailyLogRepositoryProvider)
        .findByDate(DateTime.now());
    expect(log!.totalNetCarbsG, 25);

    await revealMealList(tester);
    expect(find.byKey(const Key('meal_card_source_badge')), findsNothing);
  });

  // The negative half of the same rule.
  testWidgets('editing only the name leaves the source alone', (tester) async {
    final app = await bootWithEstimate(tester);
    await logEstimatedMeal(tester, 'פיתה');

    await scrollDown(tester);
    await tapAt(tester, find.text('פיתה'));
    await enterInto(tester, 'meal_name_field', 'פיתה מלאה');
    await tapAt(tester, find.byKey(const Key('save_meal_button')));

    final after = await storedMeal(app);
    expect(after.mealName, 'פיתה מלאה');
    // Nothing about the numbers' origin changed.
    expect(after.source, MacroSource.estimatedFromText);

    await revealMealList(tester);
    expect(find.byKey(const Key('meal_card_source_badge')), findsOneWidget);
  });

  // A horizontal drag is the delete gesture and a tap is the edit gesture.
  // The edit gesture must not have eaten the delete one.
  testWidgets('swipe still deletes after tap-to-edit exists', (tester) async {
    final app = await bootWithEstimate(tester);
    await logEstimatedMeal(tester, 'פיתה');

    await scrollDown(tester);
    expect(find.text('פיתה'), findsOneWidget);

    // `endToStart` in an RTL layout drags *rightward* — the trap that cost M2
    // the most time (`design/m2_handoff.md`).
    await tester.drag(find.byType(Dismissible), const Offset(500, 0));
    await settle(tester);

    await waitFor(tester, () async {
      final meals = await app.container
          .read(mealRepositoryProvider)
          .findByDate(DateTime.now());
      return meals.isEmpty;
    }, reason: 'the swiped meal was never deleted');

    final log = await app.container
        .read(dailyLogRepositoryProvider)
        .findByDate(DateTime.now());
    expect(log!.totalNetCarbsG, 0);
  });
}
