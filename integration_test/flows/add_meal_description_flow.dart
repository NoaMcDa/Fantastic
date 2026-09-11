import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/estimated_item.dart';
import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:fantastic/features/diary/domain/services/macro_estimator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../helpers/app_harness.dart';

/// A fixed estimator. **The only thing standing between this suite and a
/// network call**, which is why it is a hand-written fake rather than a
/// `mocktail` stub that could fall through to a real implementation.
class _FixedEstimator implements MacroEstimator {
  _FixedEstimator(this.result);

  final MealEstimate result;

  /// What the last call was given, so a flow can assert the description
  /// reached the engine rather than being swallowed by the sheet.
  String? lastDescription;
  String? lastImagePath;
  int calls = 0;

  @override
  Future<MealEstimate> estimate({
    String? description,
    String? imagePath,
  }) async {
    calls++;
    lastDescription = description;
    lastImagePath = imagePath;
    return result;
  }
}

/// `+` → describe → review → confirm → save, and the failure route out.
void main() {
  const items = [
    EstimatedItem(
      name: 'חזה עוף',
      grams: 200,
      fatG: 6,
      netCarbsG: 0,
      proteinG: 46,
    ),
    EstimatedItem(
      name: 'ביצה',
      grams: 100,
      fatG: 10,
      netCarbsG: 1,
      proteinG: 13,
    ),
    EstimatedItem(
      name: 'שמן זית',
      grams: 14,
      fatG: 0.09,
      netCarbsG: 0.09,
      proteinG: 0,
    ),
  ];

  const description = '200 גרם חזה עוף, 2 ביצים, כף שמן זית, פרוסת לחם';

  List<Override> withEstimator(_FixedEstimator fake) => [
    macroEstimatorProvider.overrideWithValue(fake),
  ];

  Future<void> openDescriptionMode(WidgetTester tester) =>
      openAddMeal(tester, mode: 'add_meal_mode_description');

  testWidgets('an estimate is itemised, editable and saved', (tester) async {
    final fake = _FixedEstimator(
      const EstimateSucceeded(items: items, unidentified: ['פרוסת לחם']),
    );
    final app = await bootApp(onboarded: true, overrides: withEstimator(fake));
    await pumpApp(tester, app);

    await openDescriptionMode(tester);
    await enterInto(tester, 'meal_description_field', description);
    await tapAt(tester, find.byKey(const Key('estimate_button')));

    // What the user typed reached the engine.
    expect(fake.lastDescription, description);

    // Every item, with its weight — a user who disagrees with an estimate
    // almost always disagrees with the weight.
    expect(find.text('חזה עוף'), findsOneWidget);
    expect(find.text('ביצה'), findsOneWidget);
    expect(find.text('שמן זית'), findsOneWidget);
    // The weight is on the row, beside the macros it contributes.
    expect(find.textContaining('200 גרם · שומן 6'), findsOneWidget);

    // A silently dropped `פרוסת לחם` turns a 40 g-carb meal into a 2 g one
    // and the day still reads compliant.
    expect(find.text('פרוסת לחם'), findsOneWidget);
    expect(find.text(AddMealCopy.unidentifiedMarker), findsOneWidget);

    // Drop the egg; the total must follow. #257's rule: the number in front
    // of the user when they save is the number that gets saved.
    await tapAt(tester, find.byKey(const Key('estimate_item_remove_1')));
    expect(find.text('ביצה'), findsNothing);

    await tapAt(tester, find.byKey(const Key('estimate_confirm_button')));

    // The prefill is the **post-removal** total, rounded to one decimal —
    // 6 + 0.09 is 6.09, and `0.17999999999999988` in a field is the defect
    // `design/m8_preflight.md` recorded on the scan prefill.
    expect(fieldText(tester, 'fat_field'), '6.1');
    expect(fieldText(tester, 'carbs_field'), '0.1');
    expect(fieldText(tester, 'protein_field'), '46');

    await enterInto(tester, 'meal_name_field', 'צהריים');
    await tapAt(tester, find.byKey(const Key('save_meal_button')));

    await scrollDown(tester);
    expect(find.text('צהריים'), findsOneWidget);
    // The badge is what makes an estimate read as an estimate a week later.
    expect(find.byKey(const Key('meal_card_source_badge')), findsOneWidget);

    final stored = await app.container
        .read(mealRepositoryProvider)
        .findByDate(DateTime.now());
    expect(stored.single.source, MacroSource.estimatedFromText);
    expect(stored.single.proteinG, 46);

    // One request, not one per keystroke or per rebuild.
    expect(fake.calls, 1);
  });

  testWidgets('a failed estimate explains itself and keeps the typed text', (
    tester,
  ) async {
    final fake = _FixedEstimator(
      const EstimateFailed(reason: EstimateFailureReason.offline),
    );
    final app = await bootApp(onboarded: true, overrides: withEstimator(fake));
    await pumpApp(tester, app);

    await openDescriptionMode(tester);
    await enterInto(tester, 'meal_description_field', description);
    await tapAt(tester, find.byKey(const Key('estimate_button')));

    expect(find.text(AddMealCopy.failedOffline), findsOneWidget);
    // An error, never a spinner (`design/m3_handoff.md`).
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // And nothing they wrote was discarded.
    expect(find.text(description), findsOneWidget);
  });

  testWidgets('a failure is never a dead end — manual entry carries the text', (
    tester,
  ) async {
    final fake = _FixedEstimator(
      const EstimateFailed(reason: EstimateFailureReason.notConfigured),
    );
    final app = await bootApp(onboarded: true, overrides: withEstimator(fake));
    await pumpApp(tester, app);

    await openDescriptionMode(tester);
    await enterInto(tester, 'meal_description_field', 'שקשוקה');
    await tapAt(tester, find.byKey(const Key('estimate_button')));
    await tapAt(tester, find.byKey(const Key('estimate_manual_button')));

    expect(fieldText(tester, 'meal_name_field'), 'שקשוקה');
    // No estimate survived, so nothing is prefilled and nothing is labelled.
    expect(fieldText(tester, 'fat_field'), isEmpty);

    await enterInto(tester, 'fat_field', '18');
    await enterInto(tester, 'carbs_field', '6');
    await enterInto(tester, 'protein_field', '14');
    await tapAt(tester, find.byKey(const Key('save_meal_button')));

    final stored = await app.container
        .read(mealRepositoryProvider)
        .findByDate(DateTime.now());
    expect(stored.single.source, MacroSource.manual);
  });
}
