import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/data/providers.dart';
import 'package:fantastic/features/diary/domain/services/macro_estimator.dart';
import 'package:fantastic/features/recipe/application/providers/recipe_providers.dart';
import 'package:fantastic/features/recipe/data/providers.dart';
import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';
import 'package:fantastic/features/recipe/domain/repositories/saved_recipe_repository.dart';
import 'package:fantastic/features/recipe/domain/substitution_engine.dart';
import 'package:fantastic/features/recipe/presentation/screens/recipe_converter_screen.dart';
import 'package:fantastic/features/recipe/presentation/widgets/ingredient_outcome_row.dart';
import 'package:fantastic/features/recipe/presentation/widgets/recipe_macros_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockSavedRecipeRepository extends Mock
    implements SavedRecipeRepository {}

class _MockEstimator extends Mock implements MacroEstimator {}

/// `RecipeMacrosSection`'s wiring into the converter screen (#397): the
/// hint before a save, the section after one, the write-through to the
/// repository, and the overflow fix correction (3) demands — a real widget
/// test at 320×568 with a full estimate on screen, because Flutter's
/// overflow diagnostic is assertion-based and only a debug widget test
/// catches it.
void main() {
  // A table with two real substitutions, so a converted recipe has enough
  // rows to make a realistic full-estimate screen.
  const testEngine = SubstitutionEngine(
    substitutions: [
      (
        aliases: ['קמח'],
        replacement: 'קמח שקדים',
        ratio: 0.25,
        reason: 'עתיר פחמימות',
      ),
      (
        aliases: ['סוכר'],
        replacement: 'אריתריטול',
        ratio: 1,
        reason: 'ממתיק נטול פחמימות',
      ),
    ],
    staples: ['ביצימ', 'חמאה'],
  );

  late _MockSavedRecipeRepository repository;
  late _MockEstimator estimator;

  setUpAll(() {
    registerFallbackValue(SavedRecipeFixture.fixture());
  });

  setUp(() {
    repository = _MockSavedRecipeRepository();
    estimator = _MockEstimator();
  });

  Future<void> pumpScreen(WidgetTester tester, {SavedRecipe? initial}) =>
      pumpApp(
        tester,
        RecipeConverterScreen(initial: initial),
        overrides: [
          substitutionEngineProvider.overrideWithValue(testEngine),
          savedRecipeRepositoryProvider.overrideWithValue(repository),
          macroEstimatorProvider.overrideWithValue(estimator),
        ],
      );

  Future<void> paste(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('recipe_paste_field')), text);
    await tester.pump();
  }

  Future<void> convert(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('recipe_convert_button')));
    await tester.pumpAndSettle();
  }

  Future<void> save(
    WidgetTester tester, {
    int id = 9,
    bool dismissSnackBar = true,
  }) async {
    when(() => repository.save(any())).thenAnswer(
      (invocation) async =>
          (invocation.positionalArguments.first as SavedRecipe).copyWith(
            id: id,
          ),
    );
    await tester.tap(find.byKey(const Key('save_recipe_button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('recipe_title_field')),
      'פשטידה',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('recipe_title_save_button')));
    await tester.pumpAndSettle();
    if (!dismissSnackBar) {
      // Leaves `RecipeCopy.saved` on screen, which is the state a real user
      // is in the instant the section appears — see the clearance test at
      // the bottom of this file.
      return;
    }
    // The "saved" `SnackBar` sits at the bottom of the screen for its
    // default duration and would otherwise intercept a tap meant for a
    // button underneath it — fire its auto-dismiss timer and let the close
    // animation finish rather than tapping through it.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  /// Types [value] into the servings field and closes the IME.
  ///
  /// **The `receiveAction` call is load-bearing, not decorative.** A plain
  /// `enterText` followed immediately by a `tap()` elsewhere leaves that tap
  /// hit-testing against a focused-field frame in `flutter_test`'s own
  /// synthetic pointer pipeline and it lands nowhere useful — found
  /// empirically: `recipe_estimate_button`'s own tap silently stopped
  /// registering after typing here, every time, with no exception and no
  /// failed hit-test warning to explain it. Closing the IME first is what a
  /// real keyboard's "done" action does anyway, and it is what makes the
  /// *next* tap land where a human's actually would.
  Future<void> setServings(WidgetTester tester, String value) async {
    await tester.enterText(
      find.byKey(const Key('recipe_servings_field')),
      value,
    );
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  }

  testWidgets('the save-first hint shows before the recipe is saved', (
    tester,
  ) async {
    await pumpScreen(tester);
    await paste(tester, 'כוס קמח\nביצים');
    await convert(tester);

    expect(find.byKey(const Key('recipe_macros_save_hint')), findsOneWidget);
    expect(find.byType(RecipeMacrosSection), findsNothing);
  });

  testWidgets(
    'RecipeMacrosSection replaces the hint once the recipe is saved',
    (tester) async {
      await pumpScreen(tester);
      await paste(tester, 'כוס קמח\nביצים');
      await convert(tester);
      await save(tester);

      expect(find.byType(RecipeMacrosSection), findsOneWidget);
      expect(find.byKey(const Key('recipe_macros_save_hint')), findsNothing);
    },
  );

  testWidgets(
    'saving macros writes servings and per-serving totals onto the recipe',
    (tester) async {
      when(
        () => estimator.estimate(
          description: any(named: 'description'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenAnswer((_) async => MealEstimateFixture.succeeded());
      await pumpScreen(tester);
      await paste(tester, 'כוס קמח\nביצים');
      await convert(tester);
      await save(tester);

      await setServings(tester, '4');
      await tester.tap(find.byKey(const Key('recipe_estimate_button')));
      await tester.pumpAndSettle();
      // The review list a real estimate renders pushes the save button
      // below the default test viewport's fold.
      await tester.ensureVisible(
        find.byKey(const Key('recipe_save_macros_button')),
      );
      await tester.tap(find.byKey(const Key('recipe_save_macros_button')));
      await tester.pumpAndSettle();

      final captured =
          verify(() => repository.save(captureAny())).captured.last
              as SavedRecipe;
      expect(captured.id, 9);
      expect(captured.servings, 4);
      expect(captured.perServing!.fatG, 22 / 4);
      expect(captured.perServing!.netCarbsG, 9 / 4);
      expect(captured.perServing!.proteinG, 19 / 4);
      expect(find.text(RecipeCopy.macrosSaved), findsOneWidget);
    },
  );

  testWidgets(
    'a failed macros save shows its own failure copy and keeps the estimate',
    (tester) async {
      when(
        () => estimator.estimate(
          description: any(named: 'description'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenAnswer((_) async => MealEstimateFixture.succeeded());
      await pumpScreen(tester);
      await paste(tester, 'כוס קמח\nביצים');
      await convert(tester);
      await save(tester);

      // The macros save throws, unlike the outcome save above.
      when(() => repository.save(any()))
          .thenThrow(const PersistenceException('boom', 'disk gone'));

      await setServings(tester, '2');
      await tester.tap(find.byKey(const Key('recipe_estimate_button')));
      await tester.pumpAndSettle();
      // The review list a real estimate renders pushes the save button
      // below the default test viewport's fold.
      await tester.ensureVisible(
        find.byKey(const Key('recipe_save_macros_button')),
      );
      await tester.tap(find.byKey(const Key('recipe_save_macros_button')));
      await tester.pumpAndSettle();

      expect(find.text(RecipeCopy.macrosSaveFailed), findsOneWidget);
      // The estimate stays exactly as it was.
      expect(find.byKey(const Key('recipe_per_serving_row')), findsOneWidget);
    },
  );

  testWidgets('reopening a recipe with stored macros shows them without a '
      'request', (tester) async {
    await pumpScreen(tester, initial: SavedRecipeFixture.withPerServing(id: 4));

    expect(find.byType(RecipeMacrosSection), findsOneWidget);
    expect(find.text(RecipeCopy.perServingSummary(18, 4, 9)), findsOneWidget);
    verifyNever(
      () => estimator.estimate(
        description: any(named: 'description'),
        imagePath: any(named: 'imagePath'),
      ),
    );
  });

  testWidgets(
    'a long, saved recipe with a full estimate does not overflow at 320×568',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      when(
        () => estimator.estimate(
          description: any(named: 'description'),
          imagePath: any(named: 'imagePath'),
        ),
      ).thenAnswer(
        (_) async => MealEstimateFixture.succeeded(
          unidentified: const ['תבלין לא ידוע'],
        ),
      );

      // Twelve lines: real substitutions, staples, a flagged line and an
      // unrecognised one — a realistic "full screen" recipe.
      final lines = [
        for (var i = 0; i < 4; i++) '2 כוסות קמח',
        for (var i = 0; i < 4; i++) 'ביצים',
        '3/4 כוס סוכר',
        'כף דבש',
        'קסמוקס בלתי ידוע',
        'חמאה',
      ].join('\n');

      await pumpScreen(tester);
      await paste(tester, lines);
      await convert(tester);
      expect(tester.takeException(), isNull);
      expect(find.byType(IngredientOutcomeRow), findsWidgets);

      await save(tester);
      expect(tester.takeException(), isNull);

      // Servings field, a five-item review list, unidentified rows, the
      // per-serving row and both buttons — all on screen at once. Scrolled
      // into view first: at 320×568 the section starts below the fold, and
      // `tester.tap` needs a real, on-screen hit point — the resolved keys
      // do not.
      await tester.ensureVisible(
        find.byKey(const Key('recipe_servings_field')),
      );
      await setServings(tester, '4');
      await tester.ensureVisible(
        find.byKey(const Key('recipe_estimate_button')),
      );
      await tester.tap(find.byKey(const Key('recipe_estimate_button')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('recipe_per_serving_row')), findsOneWidget);
      expect(
        find.byKey(const Key('recipe_save_macros_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('recipe_log_serving_button')),
        findsOneWidget,
      );

      // The whole point of the fix: scrolling the region reveals whatever
      // did not fit, rather than Flutter painting a yellow-and-black stripe
      // over it. Dragged from a fixed, always-on-screen point rather than
      // the results list's own (possibly since-scrolled-away) center.
      await tester.dragFrom(const Offset(160, 300), const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the estimate button clears the saved SnackBar that reveals it', (
    tester,
  ) async {
    // Saving the recipe does two things with one tap: it shows
    // `RecipeCopy.saved` and it mounts `RecipeMacrosSection`. A user's next
    // action is `ערכים למנה` — so the control that has just appeared must
    // not be sitting underneath the confirmation for the tap that revealed
    // it. `RecipeMacrosSection.snackBarClearance` is what keeps it clear;
    // this asserts the geometry rather than the constant.
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpScreen(tester);
    await paste(tester, 'כוס קמח\nביצים\nחמאה');
    await convert(tester);
    await save(tester, dismissSnackBar: false);

    expect(find.byType(SnackBar), findsOneWidget);

    final button = find.byKey(const Key('recipe_estimate_button'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();

    // `ensureVisible` scrolls it into the viewport; the clearance is what
    // decides whether "in the viewport" also means "not under the
    // SnackBar". Without the padding the two rects overlap and the tap
    // lands on the SnackBar.
    expect(
      tester.getRect(button).bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(SnackBar)).top),
    );
  });
}
