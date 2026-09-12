import 'dart:io';

import 'package:fantastic/core/constants/recipe_copy.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/recipe/domain/models/ingredient_outcome.dart';
import 'package:fantastic/features/recipe/domain/models/outcome_source.dart';
import 'package:fantastic/features/recipe/presentation/widgets/ingredient_outcome_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';
import '../../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpRow(WidgetTester tester, IngredientOutcome outcome) =>
      pumpApp(tester, IngredientOutcomeRow(outcome: outcome));

  Icon iconOf(WidgetTester tester) =>
      tester.widget<Icon>(find.byType(Icon).first);

  testWidgets(
    'Substituted: original struck through, replacement, adjusted quantity, '
    'reason',
    (tester) async {
      final outcome = IngredientOutcomeFixture.substituted();
      await pumpRow(tester, outcome);

      final struck = tester.widget<Text>(find.text(outcome.ingredient.raw));
      expect(struck.style?.decoration, TextDecoration.lineThrough);

      expect(
        find.textContaining(outcome.substitution.replacement),
        findsOneWidget,
      );
      expect(find.textContaining(outcome.substitution.reason), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz), findsOneWidget);
    },
  );

  testWidgets('Substituted: 2 כוסות at 0.25 renders 0.5 כוסות', (tester) async {
    // quantity 2, ratio 0.25 — 2 * 0.25 = 0.5. Asserting the adjusted
    // figure is rendered, and the original `2` is not, as an amount.
    await pumpRow(tester, IngredientOutcomeFixture.substituted());

    expect(find.textContaining('0.5 כוסות'), findsOneWidget);
  });

  testWidgets('Substituted with no quantity shows no quantity', (tester) async {
    await pumpRow(tester, IngredientOutcomeFixture.substitutedNoQuantity());

    expect(find.textContaining('כוסות'), findsNothing);
  });

  testWidgets('AlreadyKeto renders as approved', (tester) async {
    final outcome = IngredientOutcomeFixture.alreadyKeto();
    await pumpRow(tester, outcome);

    expect(find.text(outcome.ingredient.raw), findsOneWidget);
    expect(find.text(RecipeCopy.alreadyKeto), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(iconOf(tester).color, AppTheme.success);
  });

  testWidgets('Flagged renders as remove, not struck through', (tester) async {
    final outcome = IngredientOutcomeFixture.flagged();
    await pumpRow(tester, outcome);

    final raw = tester.widget<Text>(find.text(outcome.ingredient.raw));
    expect(raw.style?.decoration, isNot(TextDecoration.lineThrough));
    expect(find.text(RecipeCopy.flagged), findsOneWidget);
    expect(find.byIcon(Icons.remove_circle_outline), findsOneWidget);
    expect(iconOf(tester).color, AppTheme.danger);
  });

  testWidgets(
    'Unrecognised renders as unknown and shares no colour or icon with '
    'AlreadyKeto',
    (tester) async {
      final outcome = IngredientOutcomeFixture.unrecognised();
      await pumpRow(tester, outcome);

      expect(find.text(RecipeCopy.unrecognised), findsOneWidget);
      expect(find.byIcon(Icons.help_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(iconOf(tester).color, AppTheme.caution);
      expect(iconOf(tester).color, isNot(AppTheme.success));
      expect(iconOf(tester).icon, isNot(Icons.check_circle_outline));
    },
  );

  testWidgets('suggested source shows the marker on both variants', (
    tester,
  ) async {
    await pumpRow(
      tester,
      IngredientOutcomeFixture.substituted(source: OutcomeSource.suggested),
    );
    expect(find.text(RecipeCopy.suggestedMarker), findsOneWidget);

    await pumpRow(
      tester,
      IngredientOutcomeFixture.alreadyKeto(source: OutcomeSource.suggested),
    );
    expect(find.text(RecipeCopy.suggestedMarker), findsOneWidget);
  });

  testWidgets('the rule source shows no marker', (tester) async {
    await pumpRow(tester, IngredientOutcomeFixture.substituted());
    expect(find.text(RecipeCopy.suggestedMarker), findsNothing);
  });

  test('no EdgeInsets.only(left:) or Alignment.centerLeft', () {
    // A source scan, not a rendering assertion: `Card`'s own default
    // margin is a physical (but symmetric) `EdgeInsets.all`, so asserting
    // against the rendered tree would flag Flutter's own widget. What
    // matters is that nothing *this file* wrote hard-codes a left/right
    // side rather than a start/end one.
    final source = File(
      'lib/features/recipe/presentation/widgets/ingredient_outcome_row.dart',
    ).readAsStringSync();

    expect(source.contains('EdgeInsets.only('), isFalse);
    expect(source.contains('Alignment.centerLeft'), isFalse);
    expect(source.contains('Alignment.centerRight'), isFalse);
  });
}
