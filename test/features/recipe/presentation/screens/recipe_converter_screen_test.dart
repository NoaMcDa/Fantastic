import 'package:fantastic/features/recipe/application/providers/recipe_providers.dart';
import 'package:fantastic/features/recipe/domain/substitution_engine.dart';
import 'package:fantastic/features/recipe/presentation/screens/recipe_converter_screen.dart';
import 'package:fantastic/features/recipe/presentation/widgets/ingredient_outcome_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  // A small two-row table (plus the one staple), per the issue's "Test
  // doubles needed" — never an assertion against the whole shipped set.
  //
  // Stored final-form folded, per `SubstitutionRules`' own convention:
  // `SubstitutionEngine.key` folds sofit letters on the *input* it
  // matches (ם→מ here), so an unfolded table entry never matches a name
  // that ends in one — `ביצים` only matches as `ביצימ`.
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

  Future<void> pumpScreen(WidgetTester tester) => pumpApp(
    tester,
    const RecipeConverterScreen(),
    overrides: [substitutionEngineProvider.overrideWithValue(testEngine)],
  );

  Future<void> paste(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('recipe_paste_field')), text);
    await tester.pump();
  }

  Future<void> convert(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('recipe_convert_button')));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the paste field and a disabled convert button', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.byKey(const Key('recipe_paste_field')), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('recipe_convert_button')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('convert: one row per non-blank line, in order', (tester) async {
    await pumpScreen(tester);
    await paste(tester, '2 כוסות קמח\nביצים\nמלטיטול');
    await convert(tester);

    expect(find.byType(IngredientOutcomeRow), findsNWidgets(3));
    expect(find.byKey(const Key('outcome_substituted_0')), findsOneWidget);
    expect(find.byKey(const Key('outcome_already_keto_1')), findsOneWidget);
    expect(find.byKey(const Key('outcome_flagged_2')), findsOneWidget);
  });

  testWidgets('convert: blank lines are dropped', (tester) async {
    await pumpScreen(tester);
    await paste(tester, '\n\n2 כוסות קמח\n   \nביצים\n\n');
    await convert(tester);

    expect(find.byType(IngredientOutcomeRow), findsNWidgets(2));
  });

  testWidgets('convert: converting twice replaces', (tester) async {
    await pumpScreen(tester);
    await paste(tester, '2 כוסות קמח\nביצים\nמלטיטול');
    await convert(tester);
    expect(find.byType(IngredientOutcomeRow), findsNWidgets(3));

    await paste(tester, 'ביצים');
    await convert(tester);

    expect(find.byType(IngredientOutcomeRow), findsNWidgets(1));
    expect(find.byKey(const Key('outcome_already_keto_0')), findsOneWidget);
  });

  testWidgets('convert: an unparseable line renders as Unrecognised, no '
      'throw', (tester) async {
    await pumpScreen(tester);
    await paste(tester, 'קסמוקס בלתי ידוע לגמרי');
    await convert(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('outcome_unrecognised_0')), findsOneWidget);
  });

  testWidgets('a long recipe scrolls without overflow', (tester) async {
    await pumpScreen(tester);
    final lines = List.generate(40, (i) => 'ביצים $i').join('\n');
    await paste(tester, lines);
    await convert(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(IngredientOutcomeRow), findsWidgets);
  });

  testWidgets('the opening state has no animating widget', (tester) async {
    await pumpScreen(tester);

    // If anything here animated before a tap, this would never settle —
    // this is a tab root and `test/widget_test.dart` walks every tab
    // knowing nothing about what is on it (`design/m6_handoff.md`).
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
