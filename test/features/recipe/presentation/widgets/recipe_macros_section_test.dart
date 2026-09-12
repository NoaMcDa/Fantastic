import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/models/estimate_failure_reason.dart';
import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_estimate.dart';
import 'package:fantastic/features/diary/domain/services/macro_estimator.dart';
import 'package:fantastic/features/diary/presentation/widgets/add_meal_bottom_sheet.dart';
import 'package:fantastic/features/diary/presentation/widgets/estimate_review_list.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';
import 'package:fantastic/features/recipe/presentation/widgets/recipe_macros_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockEstimator extends Mock implements MacroEstimator {}

/// `RecipeMacrosSection` — the batch-to-serving estimate, review and
/// hand-off (#397). `MealEstimateFixture.items()` sums to fat 22, net carbs
/// 9, protein 19, over three distinct-valued items, so a getter that summed
/// the wrong column would fail here.
void main() {
  late _MockEstimator estimator;

  final date = DateTime(2026, 9, 12);
  const title = 'פשטידת כרובית';
  final recordedSaves = <({int servings, MacroTotals perServing})>[];

  setUp(() {
    estimator = _MockEstimator();
    recordedSaves.clear();
  });

  void answers(MealEstimate result) => when(
    () => estimator.estimate(
      description: any(named: 'description'),
      imagePath: any(named: 'imagePath'),
    ),
  ).thenAnswer((_) async => result);

  Future<void> pumpSection(
    WidgetTester tester, {
    List<IngredientOutcome>? outcomes,
    int? initialServings,
    MacroTotals? initialPerServing,
  }) => pumpApp(
    tester,
    RecipeMacrosSection(
      outcomes: outcomes ?? SavedRecipeFixture.allOutcomeVariants(),
      recipeTitle: title,
      date: date,
      onSaved: recordedSaves.add,
      initialServings: initialServings,
      initialPerServing: initialPerServing,
    ),
    overrides: [macroEstimatorProvider.overrideWithValue(estimator)],
  );

  Future<void> setServings(WidgetTester tester, String value) async {
    await tester.enterText(
      find.byKey(const Key('recipe_servings_field')),
      value,
    );
    await tester.pump();
  }

  Future<void> estimate(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('recipe_estimate_button')));
    await tester.pumpAndSettle();
  }

  bool estimateEnabled(WidgetTester tester) =>
      tester
          .widget<FilledButton>(find.byKey(const Key('recipe_estimate_button')))
          .onPressed !=
      null;

  group('the servings field', () {
    testWidgets('below 1 or non-numeric disables estimate', (tester) async {
      await pumpSection(tester);

      for (final value in ['0', '-1', 'abc', 'Infinity', 'NaN', '']) {
        await setServings(tester, value);
        expect(estimateEnabled(tester), isFalse, reason: 'value: $value');
      }
    });

    testWidgets('a valid count enables estimate', (tester) async {
      await pumpSection(tester);

      await setServings(tester, '4');

      expect(estimateEnabled(tester), isTrue);
    });
  });

  group('a successful estimate', () {
    testWidgets(
      'renders the batch review and a per-serving row divided by servings',
      (tester) async {
        answers(MealEstimateFixture.succeeded());
        await pumpSection(tester);
        await setServings(tester, '4');
        await estimate(tester);

        expect(find.byType(EstimateReviewList), findsOneWidget);
        expect(find.byKey(const Key('recipe_per_serving_row')), findsOneWidget);
        // Servings = 4 dividing every figure by 4 — the batch-is-not-a-meal
        // rule, and the bug most likely to ship.
        expect(
          find.text(RecipeCopy.perServingSummary(22 / 4, 9 / 4, 19 / 4)),
          findsOneWidget,
        );
      },
    );

    testWidgets('removing an item moves the per-serving row', (tester) async {
      answers(MealEstimateFixture.succeeded());
      await pumpSection(tester);
      await setServings(tester, '2');
      await estimate(tester);
      expect(
        find.text(RecipeCopy.perServingSummary(22 / 2, 9 / 2, 19 / 2)),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('estimate_item_remove_0')));
      await tester.pump();

      // Item 0 (fat 5, carbs 1, protein 6) removed: 17/8/13 left, over 2.
      expect(
        find.text(RecipeCopy.perServingSummary(17 / 2, 8 / 2, 13 / 2)),
        findsOneWidget,
      );
    });

    testWidgets('excluded lines appear as unidentified, not in the total', (
      tester,
    ) async {
      final flagged = SavedRecipeFixture.flagged() as Flagged;
      answers(MealEstimateFixture.succeeded());
      await pumpSection(
        tester,
        outcomes: [SavedRecipeFixture.alreadyKeto(), flagged],
      );
      await setServings(tester, '1');
      await estimate(tester);

      expect(find.text(flagged.ingredient.raw), findsOneWidget);
      expect(find.text(AddMealCopy.unidentifiedMarker), findsOneWidget);
    });

    testWidgets('the original recipe is never estimated — only the '
        'converted description is sent', (tester) async {
      answers(MealEstimateFixture.succeeded());
      await pumpSection(
        tester,
        outcomes: [SavedRecipeFixture.substitutedRuleUnitRatio()],
      );
      await setServings(tester, '1');
      await estimate(tester);

      verify(() => estimator.estimate(description: '1 כוס קמח שקדים'))
          .called(1);
    });

    testWidgets(
      'log serving opens AddMealBottomSheet with per-serving figures and '
      'estimatedFromText',
      (tester) async {
        answers(MealEstimateFixture.succeeded());
        await pumpSection(tester);
        await setServings(tester, '4');
        await estimate(tester);

        await tester.tap(find.byKey(const Key('recipe_log_serving_button')));
        await tester.pumpAndSettle();

        final sheet = tester.widget<AddMealBottomSheet>(
          find.byType(AddMealBottomSheet),
        );
        expect(sheet.initialFatG, 22 / 4);
        expect(sheet.initialNetCarbsG, 9 / 4);
        expect(sheet.initialProteinG, 19 / 4);
        expect(sheet.source, MacroSource.estimatedFromText);
        expect(sheet.initialName, title);
        expect(sheet.date, date);
      },
    );

    testWidgets('save hands the servings and per-serving totals to onSaved', (
      tester,
    ) async {
      answers(MealEstimateFixture.succeeded());
      await pumpSection(tester);
      await setServings(tester, '4');
      await estimate(tester);

      await tester.tap(find.byKey(const Key('recipe_save_macros_button')));
      await tester.pump();

      expect(recordedSaves, hasLength(1));
      expect(recordedSaves.single.servings, 4);
      expect(recordedSaves.single.perServing.fatG, 22 / 4);
      expect(recordedSaves.single.perServing.netCarbsG, 9 / 4);
      expect(recordedSaves.single.perServing.proteinG, 19 / 4);
    });
  });

  group('failures', () {
    // Per reason, not as a group — `EstimateFailureView`'s own doc: "turn it
    // on in settings" and "you are offline" are not the same problem.
    for (final (reason, headline) in <(EstimateFailureReason, String)>[
      (EstimateFailureReason.notConfigured, AddMealCopy.failedNotConfigured),
      (EstimateFailureReason.offline, AddMealCopy.failedOffline),
      (EstimateFailureReason.rateLimited, AddMealCopy.failedRateLimited),
      (EstimateFailureReason.unauthorised, AddMealCopy.failedUnauthorised),
      (EstimateFailureReason.badResponse, AddMealCopy.failedBadResponse),
      (
        EstimateFailureReason.nothingIdentified,
        AddMealCopy.failedNothingIdentified,
      ),
    ]) {
      testWidgets('${reason.name} renders its own headline', (tester) async {
        answers(EstimateFailed(reason: reason));
        await pumpSection(tester);
        await setServings(tester, '1');
        await estimate(tester);

        expect(find.text(headline), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      });
    }

    testWidgets('a throwing estimator is badResponse, not an uncaught error', (
      tester,
    ) async {
      when(
        () => estimator.estimate(
          description: any(named: 'description'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenThrow(StateError('boom'));
      await pumpSection(tester);
      await setServings(tester, '1');
      await estimate(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(AddMealCopy.failedBadResponse), findsOneWidget);
    });

    testWidgets(
      'a recipe of only excluded lines is emptyInput, not a request',
      (tester) async {
        await pumpSection(tester, outcomes: [SavedRecipeFixture.flagged()]);
        await setServings(tester, '1');
        await estimate(tester);

        verifyNever(
          () => estimator.estimate(
            description: any(named: 'description'),
            imagePath: any(named: 'imagePath'),
          ),
        );
        expect(find.text(AddMealCopy.failedEmptyInput), findsOneWidget);
      },
    );

    testWidgets('the manual escape opens the form with no macros', (
      tester,
    ) async {
      answers(const EstimateFailed(reason: EstimateFailureReason.badResponse));
      await pumpSection(tester);
      await setServings(tester, '1');
      await estimate(tester);

      await tester.tap(find.byKey(const Key('estimate_manual_button')));
      await tester.pumpAndSettle();

      final sheet = tester.widget<AddMealBottomSheet>(
        find.byType(AddMealBottomSheet),
      );
      expect(sheet.initialFatG, isNull);
      expect(sheet.initialNetCarbsG, isNull);
      expect(sheet.initialProteinG, isNull);
      expect(sheet.initialName, title);
      expect(sheet.source, MacroSource.manual);
    });

    testWidgets('notConfigured and unauthorised offer the profile escape', (
      tester,
    ) async {
      answers(
        const EstimateFailed(reason: EstimateFailureReason.notConfigured),
      );
      await pumpSection(tester);
      await setServings(tester, '1');
      await estimate(tester);

      expect(find.byKey(const Key('estimate_profile_button')), findsOneWidget);
      // No router in this harness — tapping must not crash.
      await tester.tap(find.byKey(const Key('estimate_profile_button')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('reopening a recipe with stored macros', () {
    const stored = MacroTotals(fatG: 18, netCarbsG: 4, proteinG: 9);

    testWidgets('renders the per-serving row and log button immediately, '
        'with no request', (tester) async {
      await pumpSection(tester, initialServings: 6, initialPerServing: stored);

      expect(find.byKey(const Key('recipe_per_serving_row')), findsOneWidget);
      expect(
        find.byKey(const Key('recipe_log_serving_button')),
        findsOneWidget,
      );
      expect(find.text(RecipeCopy.perServingSummary(18, 4, 9)), findsOneWidget);
      verifyNever(
        () => estimator.estimate(
          description: any(named: 'description'),
          imagePath: any(named: 'imagePath'),
        ),
      );
    });

    testWidgets('relabels the estimate button as a recalculation', (
      tester,
    ) async {
      await pumpSection(tester, initialServings: 6, initialPerServing: stored);

      expect(find.text(RecipeCopy.recalculateMacrosButton), findsOneWidget);
      expect(find.text(RecipeCopy.estimateMacrosButton), findsNothing);
    });

    testWidgets('the save button is absent until a fresh estimate runs', (
      tester,
    ) async {
      await pumpSection(tester, initialServings: 6, initialPerServing: stored);

      expect(find.byKey(const Key('recipe_save_macros_button')), findsNothing);
    });
  });
}
