import 'package:fantastic/features/keto_lens/domain/models/ingredient_verdict.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/domain/models/serving_basis.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:fantastic/features/keto_lens/presentation/widgets/scan_result_sheet.dart';
import 'package:flutter/material.dart';
import 'package:fantastic/features/keto_lens/domain/models/macro_verdict.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/pump_app.dart';

/// The serving-scale control (#257).
///
/// The defect: a label declares its macros per 100 g, the sheet prefilled them
/// verbatim, and a user who scanned a 30 g bar and tapped straight through
/// logged the whole 100 g — corrupting the day's macros, the keto ratio, the
/// streak evaluation and the phase, all from one tap.
///
/// Every test here asserts on **what the user sees in the macro strip**, which
/// is deliberately the scaled figure rather than the printed one: the number in
/// front of them at the moment they tap save is the number that gets saved.
void main() {
  final date = DateTime(2026, 9, 11);

  Future<void> pumpSheet(WidgetTester tester, ParsedLabel label) => pumpApp(
    tester,
    ScanResultSheet(
      result: ScanSucceeded(
        macroVerdict: const MacroVerdict.indeterminate(
          MacroIndeterminacy.noCarbRow,
        ),
        label: label,
        verdict: const IngredientVerdict(badge: VerdictBadge.cleanKeto),
      ),
      date: date,
    ),
  );

  /// The amount field's current text, or null when the field is not offered.
  String? amountText(WidgetTester tester) {
    final field = find.byKey(const Key('scan_amount_field'));
    if (field.evaluate().isEmpty) return null;
    return tester.widget<TextField>(field).controller?.text;
  }

  group('per-100 g label', () {
    const label = ParsedLabel(
      fatG: 20,
      netCarbsG: 6,
      proteinG: 30,
      basis: ServingBasis.per100g,
      servingGrams: 30,
    );

    testWidgets('defaults the amount to the declared serving weight', (
      tester,
    ) async {
      await pumpSheet(tester, label);

      // Not 100. The label said a serving is 30 g, so that is the honest
      // starting point — and it is the whole difference between this fix and
      // a caption asking the user to do arithmetic.
      expect(amountText(tester), '30');
    });

    testWidgets('shows macros scaled to that serving, not the printed 100 g', (
      tester,
    ) async {
      await pumpSheet(tester, label);

      // 0.3 x the printed figures.
      expect(find.text('6 ג'), findsOneWidget); // fat 20 -> 6
      expect(find.text('1.8 ג'), findsOneWidget); // carbs 6 -> 1.8
      expect(find.text('9 ג'), findsOneWidget); // protein 30 -> 9
      // The printed figure must NOT be on screen: showing both is how a user
      // saves the wrong one.
      expect(find.text('20 ג'), findsNothing);
    });

    testWidgets('rescales live as the amount is edited', (tester) async {
      await pumpSheet(tester, label);

      await tester.enterText(find.byKey(const Key('scan_amount_field')), '50');
      await tester.pump();

      expect(find.text('10 ג'), findsOneWidget); // fat 20 -> 10
      expect(find.text('15 ג'), findsOneWidget); // protein 30 -> 15
    });

    testWidgets('says what the figures are per', (tester) async {
      await pumpSheet(tester, label);

      expect(
        find.text(ScanResultSheet.basisCaption(ServingBasis.per100g)),
        findsOneWidget,
      );
    });

    testWidgets('an empty or nonsense amount does not scale to zero', (
      tester,
    ) async {
      await pumpSheet(tester, label);

      await tester.enterText(find.byKey(const Key('scan_amount_field')), '');
      await tester.pump();

      // Falls back to the printed figures rather than logging 0 g of
      // everything. A zero here would be saved without complaint by the diary
      // form, and a zero-macro meal is invisible in the day's totals — the
      // silent-wrong-number failure again, in a new place.
      expect(find.text('20 ג'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('scan_amount_field')), 'abc');
      await tester.pump();
      expect(find.text('20 ג'), findsOneWidget);
    });

    testWidgets('defaults to 100 when the label declared no serving', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        const ParsedLabel(fatG: 20, basis: ServingBasis.per100g),
      );

      // 100 is the no-op scale, so a user who ignores the field gets exactly
      // M6's behaviour rather than a surprise.
      expect(amountText(tester), '100');
      expect(find.text('20 ג'), findsOneWidget);
    });
  });

  group('per-100 ml label', () {
    testWidgets('offers a millilitre prompt and scales the same way', (
      tester,
    ) async {
      await pumpSheet(
        tester,
        const ParsedLabel(fatG: 10, basis: ServingBasis.per100ml),
      );

      expect(
        find.text(ScanResultSheet.amountLabel(ServingBasis.per100ml)),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const Key('scan_amount_field')), '250');
      await tester.pump();
      expect(find.text('25 ג'), findsOneWidget);
    });
  });

  group('per-serving label', () {
    testWidgets('is not scaled and offers no amount field', (tester) async {
      await pumpSheet(
        tester,
        const ParsedLabel(
          fatG: 18,
          proteinG: 5,
          basis: ServingBasis.perServing,
          servingGrams: 40,
        ),
      );

      // The figures already describe one serving. Offering a grams field here
      // would invite the user to divide by 100 a number that was never per
      // 100 of anything.
      expect(amountText(tester), isNull);
      expect(find.text('18 ג'), findsOneWidget);
      expect(
        find.text(ScanResultSheet.basisCaption(ServingBasis.perServing)),
        findsOneWidget,
      );
    });
  });

  group('unknown basis', () {
    testWidgets('keeps M6 behaviour and M6 copy exactly', (tester) async {
      await pumpSheet(
        tester,
        const ParsedLabel(fatG: 24, netCarbsG: 60, proteinG: 6),
      );

      // #257's Definition of Done: "this issue must not make an unreadable
      // label worse". No field, no scaling, and the original caption asking
      // the user to check the serving size themselves - which is still the
      // right answer when the app genuinely cannot tell.
      expect(amountText(tester), isNull);
      expect(find.text('24 ג'), findsOneWidget);
      expect(
        find.text('הערכים מהתווית — בדקו את גודל המנה לפני השמירה'),
        findsOneWidget,
      );
    });

    testWidgets('a two-column label lands here rather than guessing', (
      tester,
    ) async {
      // The parser resolves a two-column label to unknown; this is the UI end
      // of that decision. Nothing is scaled, and the user is asked.
      await pumpSheet(tester, const ParsedLabel(fatG: 24, servingGrams: 25));

      expect(amountText(tester), isNull);
      expect(find.text('24 ג'), findsOneWidget);
    });
  });
}
