import 'package:fantastic/features/keto_lens/application/scan_orchestrator.dart';
import 'package:fantastic/features/keto_lens/data/classifiers/ingredient_classifier_impl.dart';
import 'package:fantastic/features/keto_lens/data/parsers/hebrew_label_parser.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/domain/models/serving_basis.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fixtures.dart';

/// The pure-Dart pipeline, driven by text a real OCR engine really produced.
///
/// Every other parser and classifier test in this suite runs on strings a
/// person wrote. That is the failure mode `design/m6_handoff.md` warned about,
/// and this file is the answer to it: [RealOcrFixture] is verbatim Tesseract
/// output, mistakes and all, and these tests assert what the shipped pipeline
/// does with it.
///
/// No engine runs here — the fixtures are captured, so this is a fast unit
/// test that works on any machine and in CI, where Tesseract is not installed.
/// `tesseract_ffi_recognizer_test.dart` is the one that needs a real engine.
void main() {
  /// The real pipeline, with only the recogniser stubbed — the parser and
  /// classifier are the shipped implementations, not fakes. Stubbing the
  /// recogniser is what lets captured output stand in for a live engine.
  ScanOrchestrator orchestratorReturning(String ocrText) => ScanOrchestrator(
    recognizer: _CannedRecognizer(ocrText),
    parser: const HebrewLabelParser(),
    classifier: const IngredientClassifierImpl(),
  );

  group('real OCR output', () {
    test('a cleanly-read tahini label parses every macro', () async {
      final result = await orchestratorReturning(RealOcrFixture.tahini)
          .scan('');

      final success = result as ScanSucceeded;
      // The saturated-fat sub-row uses the same word as the total-fat row,
      // one line below, with its own number. A parser taking the first match
      // reports 7.6 here. That trap survived the round trip through a real
      // engine, which is the point of asserting it again on captured text.
      expect(success.label.fatG, 53.8);
      expect(success.label.netCarbsG, closeTo(10.5 - 9.3, 0.001));
      expect(success.label.proteinG, 26.5);
      expect(success.verdict.badge, VerdictBadge.cleanKeto);
    });

    test('an Israeli decimal comma survives the engine and parses', () async {
      final result = await orchestratorReturning(RealOcrFixture.proteinBar)
          .scan('');

      final success = result as ScanSucceeded;
      // Tesseract returned "22,5" — it did not helpfully normalise the comma,
      // so the parser still has to. `double.tryParse` rejects it outright.
      expect(success.label.fatG, 22.5);
      // Maltitol is in the ingredient line, printed above the table. It is an
      // insulin-spiking sweetener, which `IngredientClassifierImpl` rates
      // amber rather than red — a seed oil is what earns `nonKeto`. That is
      // the shipped severity ladder, not an accident of this fixture.
      expect(success.verdict.badge, VerdictBadge.cautionQuantityDependent);
      expect(success.verdict.flaggedIngredients, isNotEmpty);
    });

    test('a canola wafer is flagged from genuinely recognised text', () async {
      final result = await orchestratorReturning(RealOcrFixture.pointedWafer)
          .scan('');

      final success = result as ScanSucceeded;
      expect(success.verdict.badge, VerdictBadge.nonKeto);
    });

    test('niqqud survives the engine and the normaliser strips it', () async {
      final result = await orchestratorReturning(RealOcrFixture.pointedWafer)
          .scan('');

      // Tesseract returns the vowel points rather than dropping them —
      // `שוּמֶן` — so `HebrewTextNormaliser` is still doing real work on real
      // output, not only on hand-written fixtures. It strips U+0591–U+05C7
      // and the keywords then match.
      final success = result as ScanSucceeded;
      expect(success.label.fatG, 24);
      expect(success.label.proteinG, 6);
    });

    test('the carbohydrate row of a pointed label is lost, not guessed', () {
      // **This is a deliberate, measured regression, recorded rather than
      // hidden.** Loading `eng` beside `heb` is what makes the digit column
      // of a real bordered nutrition table readable at all — see
      // `wholeWheatRyeBread` below and `TessdataBundle` for the numbers. On
      // *pointed* Hebrew it costs: the English model wins `פחמִימות` and
      // returns `Nin nnd`, so the carbohydrate keyword is not there to match.
      //
      // What matters is the shape of the failure. The value is **null** —
      // `ParsedLabel` documents null as "not found" — so `ScanResultSheet`
      // asks the user instead of stating a figure. It is never 0, which would
      // save silently and vanish from the day's totals.
      //
      // A second `heb`-only pass to fill the gap was considered and rejected:
      // it would fill a safe null from a pass measured to be unreliable on
      // digits, turning "the app asks" into "the app guesses". #257 is why
      // that direction is closed. Do not "fix" this by reintroducing it.
      expect(RealOcrFixture.pointedWafer, contains('Nin nnd'));

      const parser = HebrewLabelParser();
      expect(parser.parse(RealOcrFixture.pointedWafer).netCarbsG, isNull);
    });

    group('the whole wheat + rye bread label — issue regression', () {
      // The label a user actually scanned, and the reason this fix exists.
      //
      // A bordered two-column table: numbers in the left column, Hebrew
      // labels in the right, header `ערך תזונתי ל-100 גר' מוצר`. Under the
      // settings that shipped before this change — `-l heb --psm 6`, no
      // declared DPI, no pre-scaling — Tesseract returned six of its nine
      // rows as punctuation rubble (`%- |`, `|`, `היווה`), every macro parsed
      // to null, and `ScanOrchestrator` correctly reported
      // `ScanFailed(notALabel)`. The pipeline was not at fault; the engine
      // configuration was.
      //
      // Three independent causes, each measured on tesseract 5.3.4 against
      // the models this app bundles:
      //
      //  * `psm 6` flattens a bordered table. `psm 4` keeps each row whole.
      //  * `heb` alone cannot read an isolated column of Latin digits — it
      //    returned 218/9/2/43/9/308 for 238/10.9/41.2/7/3.3/368, and was no
      //    better at 4x or 6x the resolution.
      //  * With no DPI in the file Tesseract *estimated* 631 and downscaled
      //    internally on the strength of it.
      //
      // Fixing any two of the three still fails. This group is the test that
      // would have caught the bug.

      // The same label, read by two different Tesseract versions. 5.3.4 is
      // what this repository's container has; 5.5.3 is what the macOS CI
      // runner installs from brew, and the two do **not** agree on the
      // pixels:
      //
      //   5.3.4 -> חלבונים (גרם) 10.9
      //   5.5.3 -> חזלבונים (גרם) 10.9
      //
      // That one spurious `ז` made protein vanish on a Mac while every other
      // macro and the basis came through — a confident-looking scan with a
      // hole in it. Asserting both captures is what keeps the parser honest
      // about engine drift; asserting only the local one is how this reached
      // CI in the first place.
      final captures = {
        'tesseract 5.3.4 (local)': RealOcrFixture.wholeWheatRyeBread,
        'tesseract 5.5.3 (macOS CI)': CiOcrFixture.wholeWheatRyeBread553,
      };

      for (final capture in captures.entries) {
        test('every macro parses on ${capture.key}', () async {
          final result = await orchestratorReturning(capture.value).scan('');

          final success = result as ScanSucceeded;
          // The label prints fat 3.3 g, carbs 41.2 g, fibre 7 g, protein
          // 10.9 g. `ParsedLabel` carries net carbs rather than the two
          // figures it is derived from, so 34.2 covers both.
          expect(success.label.fatG, 3.3);
          expect(success.label.netCarbsG, closeTo(41.2 - 7, 0.001));
          expect(success.label.proteinG, 10.9);

          // Without this the sheet would log per-100 g figures as if they
          // were one serving, which is what #257 was.
          expect(success.label.basis, ServingBasis.per100g);
        });
      }

      test('the 5.5.3 capture really does carry the corruption', () {
        // Guards the premise of the loop above. If someone "tidies" the
        // fixture, the cross-version assertion silently stops testing
        // anything - it would assert the same clean text twice.
        expect(CiOcrFixture.wholeWheatRyeBread553, contains('חזלבונים'));
        expect(RealOcrFixture.wholeWheatRyeBread, isNot(contains('חזלבונים')));
      });

      test('the noisier 5.5.3 rows are read, not merely tolerated', () {
        // Three other differences in that capture, verified rather than
        // assumed benign: `§` standing in for the fibre separator, `(Da)`
        // where the fat unit should be, and the fat row printing its number
        // *before* its keyword.
        const parser = HebrewLabelParser();
        final label = parser.parse(CiOcrFixture.wholeWheatRyeBread553);

        // `כלל סיבים תזונתיים (גרם) § 7` - the § is skipped, 7 is the fibre.
        expect(label.netCarbsG, closeTo(41.2 - 7, 0.001));
        // `3.3 (Da) שומנים` - number first, unit corrupted, still 3.3 and not
        // 0.9 from the saturated row below it.
        expect(label.fatG, 3.3);
      });

      test('the saturated-fat sub-row is not mistaken for total fat', () {
        // `מתוכם שומן רווי (גרם) 0.9` sits directly below
        // `שומנים (גרם) 3.3` and uses the same word. A parser taking the
        // first or the nearest match without the `_fatSubRow` guard reports
        // 0.9 — a plausible wrong number, which is the worst kind.
        const parser = HebrewLabelParser();
        expect(parser.parse(RealOcrFixture.wholeWheatRyeBread).fatG, 3.3);
      });

      test(
        'a panel with no ingredient list still succeeds on macros',
        () async {
          // This crop is the nutrition panel only — there is no `רכיבים`
          // heading anywhere in it. `hasMacros` is what carries the scan, and
          // an empty ingredient list must not be read as "nothing bad here".
          final result = await orchestratorReturning(
            RealOcrFixture.wholeWheatRyeBread,
          ).scan('');

          final success = result as ScanSucceeded;
          expect(success.label.ingredients, isEmpty);
          // Nothing was readable, so nothing may be approved. The verdict
          // records that it recognised nothing rather than showing a green
          // tick — the distinction `IngredientVerdict.recognisedNothing`
          // exists for.
          expect(success.verdict.recognisedNothing, isTrue);
        },
      );
    });
  });
}

/// A recogniser that returns one captured string.
///
/// Not a mock: there is nothing to verify about the call, only about what the
/// pipeline does with what comes back.
class _CannedRecognizer implements TextRecognitionService {
  const _CannedRecognizer(this.text);

  final String text;

  @override
  bool get isAvailable => true;

  @override
  Future<String> recognise(String imagePath) async => text;
}
