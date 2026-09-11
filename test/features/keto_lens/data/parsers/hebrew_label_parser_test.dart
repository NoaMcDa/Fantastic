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

    group('tolerating one OCR corruption in a keyword', () {
      // Tesseract 5.3.4 and 5.5.3 disagree on this label: the newer engine
      // inserts a `ז` into `חלבונים`. The parser absorbs one such error. These
      // tests are mostly about what it must *not* absorb — a matcher loose
      // enough to put the saturated-fat number in the fat field would be far
      // worse than the missing protein it was built to fix.

      test('a spurious letter inside a keyword still matches', () {
        final label = parser.parse('חזלבונים (גרם) 10.9');

        expect(label.proteinG, 10.9);
      });

      test('a substituted interior letter still matches', () {
        final label = parser.parse('פחסימות (גרם) 41.2');

        expect(label.netCarbsG, 41.2);
      });

      test('two corruptions are one too many', () {
        // The tolerance is exactly one error. Two is no longer a corrupted
        // keyword, it is a guess.
        final label = parser.parse('חזלבזנים (גרם) 10.9');

        expect(label.proteinG, isNull);
      });

      test('a three-letter keyword gets no tolerance at all', () {
        // `סיב`. One error in three letters is a different word.
        final label = parser.parse('סזבים תזונתיים (גרם) 7');

        expect(label.netCarbsG, isNull);
      });

      group('keywords still cannot claim each others rows', () {
        // The whole risk of a tolerant matcher, stated as assertions.
        const rows = {
          'חלבונים (גרם) 10.9': 'protein',
          'פחמימות (גרם) 41.2': 'carbs',
          'שומנים (גרם) 3.3': 'fat',
        };

        for (final row in rows.entries) {
          test('${row.value} row feeds only the ${row.value} field', () {
            final label = parser.parse(row.key);

            expect(label.proteinG, row.value == 'protein' ? 10.9 : isNull);
            expect(label.fatG, row.value == 'fat' ? 3.3 : isNull);
            expect(label.netCarbsG, row.value == 'carbs' ? 41.2 : isNull);
          });
        }
      });

      test('sesame is not a fat row', () {
        // `משומשום` contains `שומש`. Allowing the final letter of `שומ[נן]`
        // to be substituted would match it, and this line is an *ingredient*
        // on the project's own tahini fixture.
        final label = parser.parse('טחינה גולמית משומשום מלא 100');

        expect(label.fatG, isNull);
      });

      test('the saturated sub-row is still disqualified from total fat', () {
        // The catastrophic case. A tolerant keyword with an exact
        // disqualifier would report 0.9 as total fat.
        final label = parser.parse('מתוכם שומן רווי (גרם) 0.9');

        expect(label.fatG, isNull);
      });

      test('a corrupted disqualifier still disqualifies', () {
        // The disqualifier is tolerant for the same reason the keyword is,
        // but the risk runs the other way: over-disqualifying loses a value,
        // under-disqualifying invents one.
        final label = parser.parse('מתוכם שומן רוויי (גרם) 0.9');

        expect(label.fatG, isNull);
      });

      test('the real labels spell it טראנס, which now disqualifies', () {
        // The old exact `טרנס` did not match `טראנס` at all, so the trans-fat
        // row was never disqualified on a real label — only line order kept
        // it out of the fat field.
        final label = parser.parse('מתוכם שומן טראנס (גרם) 0.5');

        expect(label.fatG, isNull);
      });

      test('total fat still wins when it precedes its sub-rows', () {
        final label = parser.parse(
          'שומנים (גרם) 3.3\n'
          'מתוכם שומן רווי (גרם) 0.9\n'
          'מתוכם שומן טראנס (גרם) 0.5',
        );

        expect(label.fatG, 3.3);
      });
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
