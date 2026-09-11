import 'package:fantastic/features/keto_lens/data/parsers/hebrew_label_parser.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  const parser = HebrewLabelParser();

  group('HebrewLabelParser against real label fixtures', () {
    test('tahini: takes total fat, not the saturated sub-row below it', () {
      final label = parser.parse(HebrewLabelFixture.tahini);

      // 7.6 is the "of which saturated fatty acids" row, one line down,
      // using the same Hebrew word. Reporting it is the plausible wrong
      // answer this parser exists to avoid.
      expect(label.fatG, 53.8);
      expect(label.proteinG, 26.5);
    });

    test('tahini: net carbs is total minus fibre', () {
      final label = parser.parse(HebrewLabelFixture.tahini);

      expect(label.netCarbsG, closeTo(1.2, 0.0001));
    });

    test('tahini: reads an ingredient list printed after the table', () {
      final label = parser.parse(HebrewLabelFixture.tahini);

      expect(label.ingredients, ['100% שומשום מלא']);
    });

    test('protein bar: parses a decimal comma', () {
      final label = parser.parse(HebrewLabelFixture.proteinBar);

      expect(label.fatG, 22.5);
    });

    test('protein bar: the ingredient line holding "protein" is skipped', () {
      final label = parser.parse(HebrewLabelFixture.proteinBar);

      // "whey protein" is the first line carrying the protein keyword and
      // has no number on it. The value is two rows further down.
      expect(label.proteinG, 33);
    });

    test('protein bar: net carbs subtracts the fibre row', () {
      final label = parser.parse(HebrewLabelFixture.proteinBar);

      expect(label.netCarbsG, 22);
    });

    test('protein bar: splits an ingredient list printed before the table', () {
      final label = parser.parse(HebrewLabelFixture.proteinBar);

      expect(label.ingredients, [
        'חלבון מי גבינה',
        'מלטיטול',
        'שמן קוקוס',
        'קקאו',
        'אגוזי לוז',
        'מלח',
      ]);
    });

    test('protein bar: the nutrition table is not read as ingredients', () {
      final label = parser.parse(HebrewLabelFixture.proteinBar);

      // The issue's `dotAll: true` capture ran to the end of the OCR text,
      // so every macro row became an ingredient and was classified.
      expect(label.ingredients.any((i) => i.contains('ערכים')), isFalse);
      expect(label.ingredients, hasLength(6));
    });

    test('pointed wafer: niqqud on the keywords does not hide them', () {
      final label = parser.parse(HebrewLabelFixture.pointedWafer);

      expect(label.fatG, 24);
      expect(label.netCarbsG, 60);
    });

    test('pointed wafer: a geresh gram abbreviation is not a value', () {
      final label = parser.parse(HebrewLabelFixture.pointedWafer);

      expect(label.proteinG, 6);
    });

    test('pointed wafer: keeps the forbidden oil in the ingredient list', () {
      final label = parser.parse(HebrewLabelFixture.pointedWafer);

      expect(label.ingredients, contains('שמן קנולה'));
    });

    test('two-column: finds a value OCR put on its own line', () {
      final label = parser.parse(HebrewLabelFixture.twoColumn);

      expect(label.fatG, 40);
      expect(label.proteinG, 20);
      expect(label.netCarbsG, 4);
    });

    test('two-column: the column header is not mistaken for a value', () {
      final label = parser.parse(HebrewLabelFixture.twoColumn);

      // "per 100 g" sits between the heading and the first nutrient.
      expect(label.fatG, isNot(100));
    });

    test('imported: no fibre row means net carbs is total carbs', () {
      final label = parser.parse(HebrewLabelFixture.importedOliveOil);

      expect(label.fatG, 100);
      expect(label.netCarbsG, 0);
    });

    test('imported: a macro of zero is found, not missing', () {
      final label = parser.parse(HebrewLabelFixture.importedOliveOil);

      expect(label.proteinG, 0);
      expect(label.hasMacros, isTrue);
    });

    test('imported: the importer line does not become an ingredient', () {
      final label = parser.parse(HebrewLabelFixture.importedOliveOil);

      expect(label.ingredients, ['שמן זית כתית מעולה']);
    });

    test('unreadable: every macro is null and nothing throws', () {
      final label = parser.parse(HebrewLabelFixture.unreadable);

      expect(label.fatG, isNull);
      expect(label.netCarbsG, isNull);
      expect(label.proteinG, isNull);
      expect(label.ingredients, isEmpty);
      expect(label.hasMacros, isFalse);
    });

    test('every fixture keeps its raw text verbatim', () {
      for (final raw in [
        HebrewLabelFixture.tahini,
        HebrewLabelFixture.proteinBar,
        HebrewLabelFixture.pointedWafer,
        HebrewLabelFixture.twoColumn,
        HebrewLabelFixture.importedOliveOil,
        HebrewLabelFixture.unreadable,
      ]) {
        expect(parser.parse(raw).rawText, raw);
      }
    });
  });

  group('HebrewLabelParser edge cases', () {
    test('an empty string yields an all-null label', () {
      final label = parser.parse('');

      expect(label.hasMacros, isFalse);
      expect(label.ingredients, isEmpty);
      expect(label.rawText, '');
    });

    test('fibre greater than carbs floors net carbs at zero', () {
      // A high-fibre bran product, where the declared fibre exceeds the
      // declared carbohydrate. Negative net carbs is not a number a
      // dashboard can do anything with.
      final label = parser.parse(
        'פחמימות 3 גרם\n'
        'סיבים תזונתיים 8 גרם',
      );

      expect(label.netCarbsG, 0);
    });

    test('a missing carbohydrate row leaves net carbs null, not zero', () {
      // Null means "not found". Zero would claim the product has no carbs.
      final label = parser.parse('שומנים 10 גרם');

      expect(label.netCarbsG, isNull);
      expect(label.fatG, 10);
    });

    test('a fibre row with no carbohydrate row does not invent net carbs', () {
      final label = parser.parse('סיבים תזונתיים 4 גרם');

      expect(label.netCarbsG, isNull);
    });

    test('matches when OCR drops the space before the value', () {
      // A tight two-column table runs the label into its number.
      final label = parser.parse('שומן12גר');

      expect(label.fatG, 12);
    });

    test('matches the singular spelling as well as the plural', () {
      expect(parser.parse('שומן 5 גרם').fatG, 5);
      expect(parser.parse('שומנים 5 גרם').fatG, 5);
    });

    test('matches a keyword carrying a definite article', () {
      expect(parser.parse('החלבון 9 גרם').proteinG, 9);
    });

    test('reads a whole table returned as a single line', () {
      // ML Kit sometimes flattens the table. Excluding a *line* that
      // mentions saturated fat would lose every macro on it, so the
      // sub-row check is windowed around each keyword instead.
      final label = parser.parse(
        'שומנים 12 גרם '
        'מתוכם חומצות '
        'שומן רוויות 5 '
        'גרם חלבון 8',
      );

      expect(label.fatG, 12);
      expect(label.proteinG, 8);
    });

    test('a value printed before its keyword is still found', () {
      // Reordered OCR output puts the number first.
      final label = parser.parse('12 שומן');

      expect(label.fatG, 12);
    });

    test('an ingredient list with no heading yields no ingredients', () {
      final label = parser.parse('שמן זית, מלח');

      expect(label.ingredients, isEmpty);
    });

    test('accepts the alternative headings for an ingredient list', () {
      const olive = 'שמן זית';

      for (final heading in ['רכיבים', 'מרכיבים', 'הרכב']) {
        expect(parser.parse('$heading: $olive').ingredients, [
          olive,
        ], reason: 'heading $heading not recognised');
      }
    });

    test('drops a token with no letters in it', () {
      final label = parser.parse(
        'רכיבים: '
        'מלח, 100%, , מים',
      );

      expect(label.ingredients, ['מלח', 'מים']);
    });

    test('preserves the casing of a Latin ingredient', () {
      // The classifier lowercases for matching; these strings are also what
      // the result sheet shows the user.
      final label = parser.parse('רכיבים: Canola Oil, Salt');

      expect(label.ingredients, ['Canola Oil', 'Salt']);
    });

    test('stops the ingredient list at an allergen statement', () {
      final label = parser.parse(
        'רכיבים: מלח\n'
        'עשוי להכיל '
        'אגוזים',
      );

      expect(label.ingredients, ['מלח']);
    });

    test('never throws, whatever it is handed', () {
      for (final input in [
        '',
        ' ',
        '\n\n\n',
        'רכיבים:',
        '999999999999999999999999999999',
        'שומן שומן שומן',
        String.fromCharCodes(List.generate(200, (i) => 0x0590 + i % 64)),
      ]) {
        expect(() => parser.parse(input), returnsNormally);
      }
    });
  });
}
