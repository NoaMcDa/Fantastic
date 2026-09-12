import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:fantastic/features/menu/presentation/widgets/dish_verdict_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

void main() {
  Chip chipOf(WidgetTester tester) => tester.widget<Chip>(find.byType(Chip));

  group('DishVerdictBadge variants', () {
    testWidgets('orderAsIs renders green with its own label', (tester) async {
      await pumpApp(
        tester,
        const DishVerdictBadge(verdict: DishVerdict.orderAsIs),
      );

      expect(find.text('אפשר להזמין'), findsOneWidget);
      expect(chipOf(tester).backgroundColor, AppTheme.success);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('modifiable renders amber with its own label', (tester) async {
      await pumpApp(
        tester,
        const DishVerdictBadge(verdict: DishVerdict.modifiable),
      );

      expect(find.text('אפשר עם שינוי'), findsOneWidget);
      expect(chipOf(tester).backgroundColor, AppTheme.caution);
      expect(find.byIcon(Icons.edit), findsOneWidget);
      // Not Keto Lens's copy for the same colour.
      expect(find.text('זהירות — תלוי כמות'), findsNothing);
    });

    testWidgets('nonKeto renders red with its own label', (tester) async {
      await pumpApp(
        tester,
        const DishVerdictBadge(verdict: DishVerdict.nonKeto),
      );

      expect(find.text('לא מתאים לקטו'), findsOneWidget);
      expect(chipOf(tester).backgroundColor, AppTheme.danger);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('every verdict renders', (tester) async {
      for (final verdict in DishVerdict.values) {
        await pumpApp(tester, DishVerdictBadge(verdict: verdict));

        expect(find.byType(Chip), findsOneWidget, reason: '$verdict');
      }
    });
  });

  group('DishVerdictBadge colour and icon choices', () {
    test('every colour comes from AppTheme, not a raw hex', () {
      // Not `const`: Color overrides == without a primitive equality, so a
      // const Set of them does not compile.
      final palette = <Color>{
        AppTheme.success,
        AppTheme.caution,
        AppTheme.danger,
      };

      for (final verdict in DishVerdict.values) {
        expect(palette, contains(DishVerdictBadge.colourFor(verdict)));
      }
    });

    test('no two verdicts share a colour', () {
      final colours = DishVerdict.values
          .map(DishVerdictBadge.colourFor)
          .toSet();

      expect(colours, hasLength(DishVerdict.values.length));
    });

    test('no two verdicts share an icon', () {
      // Colour alone must never carry the verdict.
      final icons = DishVerdict.values.map(DishVerdictBadge.iconFor).toSet();

      expect(icons, hasLength(DishVerdict.values.length));
    });

    test('the ink on the yellow caution fill is dark, not white', () {
      // #FFD60A with white text is unreadable.
      expect(DishVerdictBadge.inkFor(DishVerdict.modifiable), AppTheme.primary);
    });

    test('the ink on the red fill is white', () {
      expect(DishVerdictBadge.inkFor(DishVerdict.nonKeto), Colors.white);
    });

    test('every label is non-empty and in Hebrew', () {
      final hebrew = RegExp(r'[֐-׿]');

      for (final verdict in DishVerdict.values) {
        final label = DishVerdictBadge.labelFor(verdict);

        expect(label, isNotEmpty);
        expect(hebrew.hasMatch(label), isTrue, reason: label);
      }
    });

    test('no two verdicts share a label', () {
      final labels = DishVerdict.values.map(DishVerdictBadge.labelFor).toSet();

      expect(labels, hasLength(DishVerdict.values.length));
    });
  });
}
