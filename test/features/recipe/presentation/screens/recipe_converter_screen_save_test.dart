import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/recipe/application/providers/recipe_providers.dart';
import 'package:fantastic/features/recipe/data/providers.dart';
import 'package:fantastic/features/recipe/domain/models/saved_recipe.dart';
import 'package:fantastic/features/recipe/domain/repositories/saved_recipe_repository.dart';
import 'package:fantastic/features/recipe/domain/substitution_engine.dart';
import 'package:fantastic/features/recipe/presentation/screens/recipe_converter_screen.dart';
import 'package:fantastic/features/recipe/presentation/widgets/ingredient_outcome_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

class _MockSavedRecipeRepository extends Mock
    implements SavedRecipeRepository {}

/// The save affordance on #119's screen (#120): appears only for a
/// convertible recipe, writes exactly what is on screen, and never loses the
/// conversion when the write fails.
void main() {
  // The same small table `recipe_converter_screen_test.dart` uses — never an
  // assertion against the whole shipped set.
  const testEngine = SubstitutionEngine(
    substitutions: [
      (
        aliases: ['קמח'],
        replacement: 'קמח שקדים',
        ratio: 0.25,
        reason: 'עתיר פחמימות',
      ),
    ],
    staples: ['ביצימ'],
  );

  late _MockSavedRecipeRepository repository;

  setUpAll(() {
    registerFallbackValue(SavedRecipeFixture.fixture());
  });

  setUp(() {
    repository = _MockSavedRecipeRepository();
  });

  Future<void> pumpScreen(WidgetTester tester, {SavedRecipe? initial}) =>
      pumpApp(
        tester,
        RecipeConverterScreen(initial: initial),
        overrides: [
          substitutionEngineProvider.overrideWithValue(testEngine),
          savedRecipeRepositoryProvider.overrideWithValue(repository),
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

  /// Taps Save, types [title] into the dialog, and confirms it.
  Future<void> saveAs(WidgetTester tester, String title) async {
    await tester.tap(find.byKey(const Key('save_recipe_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('recipe_title_field')), title);
    await tester.pump();
    await tester.tap(find.byKey(const Key('recipe_title_save_button')));
    await tester.pumpAndSettle();
  }

  testWidgets('save is absent until results exist', (tester) async {
    await pumpScreen(tester);

    expect(find.byKey(const Key('save_recipe_button')), findsNothing);
  });

  testWidgets('save is absent when every outcome is Unrecognised', (
    tester,
  ) async {
    await pumpScreen(tester);
    await paste(tester, 'קסמוקס בלתי ידוע לגמרי');
    await convert(tester);

    expect(find.byKey(const Key('outcome_unrecognised_0')), findsOneWidget);
    expect(find.byKey(const Key('save_recipe_button')), findsNothing);
  });

  testWidgets('save appears once at least one outcome is recognised', (
    tester,
  ) async {
    await pumpScreen(tester);
    await paste(tester, 'ביצים\nקסמוקס בלתי ידוע');
    await convert(tester);

    expect(find.byKey(const Key('save_recipe_button')), findsOneWidget);
  });

  testWidgets('save writes title, originalText and the on-screen outcomes and '
      'invalidates the list', (tester) async {
    when(() => repository.save(any())).thenAnswer(
      (invocation) async =>
          (invocation.positionalArguments.first as SavedRecipe).copyWith(id: 9),
    );

    await pumpScreen(tester);
    await paste(tester, 'ביצים');
    await convert(tester);
    await saveAs(tester, 'פשטידה');

    final captured =
        verify(() => repository.save(captureAny())).captured.single
            as SavedRecipe;
    expect(captured.id, isNull);
    expect(captured.title, 'פשטידה');
    expect(captured.originalText, 'ביצים');
    expect(captured.outcomes, hasLength(1));
    expect(find.text(RecipeCopy.saved), findsOneWidget);
    // Still on screen, unsaved failure copy absent.
    expect(find.byType(IngredientOutcomeRow), findsOneWidget);
    expect(find.text(RecipeCopy.saveFailed), findsNothing);
  });

  testWidgets('save on a reopened recipe carries its id', (tester) async {
    final initial = SavedRecipeFixture.fixture(
      id: 4,
      title: 'קיים',
      outcomes: [SavedRecipeFixture.alreadyKeto()],
    );
    when(() => repository.save(any())).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as SavedRecipe,
    );

    await pumpScreen(tester, initial: initial);
    await saveAs(tester, 'קיים מעודכן');

    final captured =
        verify(() => repository.save(captureAny())).captured.single
            as SavedRecipe;
    expect(captured.id, 4);
    expect(captured.title, 'קיים מעודכן');
  });

  testWidgets('a PersistenceException shows saveFailed and keeps the '
      'conversion', (tester) async {
    when(() => repository.save(any()))
        .thenThrow(const PersistenceException('boom', 'disk gone'));

    await pumpScreen(tester);
    await paste(tester, 'ביצים');
    await convert(tester);
    await saveAs(tester, 'פשטידה');

    expect(find.text(RecipeCopy.saveFailed), findsOneWidget);
    // The conversion is untouched — never a silent loss of the user's work.
    expect(find.byType(IngredientOutcomeRow), findsOneWidget);
    expect(find.byKey(const Key('outcome_already_keto_0')), findsOneWidget);
  });
}
