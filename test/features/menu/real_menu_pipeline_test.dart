import 'package:fantastic/core/utils/hebrew_text_normaliser.dart';
import 'package:fantastic/features/keto_lens/application/scan_orchestrator.dart';
import 'package:fantastic/features/keto_lens/data/classifiers/ingredient_classifier_impl.dart';
import 'package:fantastic/features/keto_lens/data/classifiers/macro_classifier_impl.dart';
import 'package:fantastic/features/keto_lens/data/parsers/hebrew_label_parser.dart';
import 'package:fantastic/features/keto_lens/domain/models/scan_result.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fixtures/fixtures.dart';

/// What the shipped pipeline does with a **photographed restaurant menu**.
///
/// The menu counterpart of `real_ocr_pipeline_test.dart`, and it exists for the
/// same reason: every other thing M16 will be tested against is text somebody
/// typed, and `design/m6_handoff.md` is blunt about what that is worth.
/// [PhotographedMenuOcrFixture] is verbatim Tesseract output from a real
/// Israeli menu photographed off a table, and these tests assert what happens
/// to it.
///
/// ## This is not yet the test issue #373 asks for, and says so
///
/// #373 Step 3 asks for assertions against `MenuResponseParser`'s provenance
/// rule. **`MenuResponseParser` does not exist** — it is #357, and no file
/// under `lib/features/menu/` has been written. Writing it here to give this
/// test something to call would be implementing another issue inside this one.
///
/// So this file asserts the two things that *can* be asserted against shipped
/// code today, and both are worth having on their own:
///
///  1. **A menu must never be read as a nutrition label.** That is a live
///     safety property of code that ships right now, and nothing tested it
///     before — Keto Lens has only ever been fed labels.
///  2. **The structural facts M16 has to design around**, measured rather than
///     assumed: which parts of a menu survive the engine and which do not.
///
/// Neither asserts raw OCR text, per `CLAUDE.md` § Testing — the transcript is
/// reduced to properties (how many rows kept a price, how close a dish name
/// came) before anything is compared, because Tesseract 5.3.4 and 5.5.3 do not
/// agree character-for-character and a `contains` here would pass locally and
/// fail on a macOS runner.
void main() {
  /// The real pipeline with only the recogniser stubbed, exactly as
  /// `real_ocr_pipeline_test.dart` builds it.
  ScanOrchestrator orchestratorReturning(String ocrText) => ScanOrchestrator(
    macroClassifier: const MacroClassifierImpl(),
    recognizer: _CannedRecognizer(ocrText),
    parser: const HebrewLabelParser(),
    classifier: const IngredientClassifierImpl(),
  );

  group('a menu is not a nutrition label', () {
    // Keto Lens has been handed nothing but nutrition panels for its whole
    // life. A menu is the most likely wrong thing for a user to point it at
    // once M16 puts a second scanner in the app — same camera, same tab
    // shell, two meanings — and until this test there was no evidence at all
    // about what it would do.
    //
    // The requirement is #83's, unchanged: a scan that did not find a label
    // reports that it did not. It does not produce a verdict, because a
    // verdict is what a user in a shop acts on.

    test(
      'the shipped scanner refuses it rather than inventing a verdict',
      () async {
        final result = await orchestratorReturning(
          PhotographedMenuOcrFixture.vivie,
        ).scan('');

        // Not `isNot(ScanSucceeded)` — the reason carries the user-facing
        // message, and `notALabel` is the one that says "turn the product
        // over" rather than "retry" or "hold steady".
        final failure = result as ScanFailed;
        expect(failure.reason, ScanFailureReason.notALabel);
      },
    );

    test('the text it could not use is kept for the user to see', () async {
      // `notALabel` is the one failure that carries `rawText`, and a menu is
      // precisely the case where the user should be shown that the camera
      // worked and the app simply did not find a panel. Losing it here would
      // render as "nothing was read" over a photograph full of Hebrew.
      final result = await orchestratorReturning(
        PhotographedMenuOcrFixture.vivie,
      ).scan('');

      final failure = result as ScanFailed;
      expect(failure.rawText, isNotNull);
      expect(failure.rawText, isNotEmpty);
    });

    test('no macro is parsed out of a menu', () {
      // The failure above is only safe while the parser genuinely finds
      // nothing. If a future keyword change made `שמן זית` in a dish
      // description parse as a fat row, the orchestrator would start
      // succeeding on menus and the test above would keep passing right up
      // until it did.
      const parser = HebrewLabelParser();
      final label = parser.parse(PhotographedMenuOcrFixture.vivie);

      expect(label.hasMacros, isFalse);
      expect(label.fatG, isNull);
      expect(label.netCarbsG, isNull);
      expect(label.proteinG, isNull);
      expect(label.energyKcal, isNull);
    });
  });

  group('what the engine keeps, and what it loses', () {
    // The measurements behind `design/m16_menu_scanner_research.md` §10.
    // They are here, rather than only in prose, so that an engine upgrade or
    // a settings change has to come past them — including an improvement.
    // A failure in this group is not automatically a regression; it means the
    // finding moved and §10 has to be rewritten, and the expectations say so
    // individually.

    final lines = PhotographedMenuOcrFixture.vivie
        .split('\n')
        .map(HebrewTextNormaliser.normalise)
        .where((line) => line.trim().isNotEmpty)
        .toList();

    test('the dish names come back readable', () {
      // The half of the finding M16 depends on: a keto classifier reads
      // ingredients, so what matters is whether a dish name survives well
      // enough to be recognised — not whether it survives exactly.
      //
      // Scored with edit distance rather than equality for the same reason
      // #357's provenance rule is specified "loose enough to survive one
      // OCR-corrupted letter in a three-word name". This is the measurement
      // that rule will need, taken on real output rather than reasoned about.
      final recognisable = _printedDishes
          .where((dish) => _bestSimilarity(dish, lines) >= 0.75)
          .length;

      // 17 of 23 scored at or above 0.75 on tesseract 5.3.4. The bar is set
      // well below that so ordinary engine drift does not fail the suite;
      // dropping under half would mean the dish names stopped surviving,
      // which is the premise M16's whole design rests on.
      expect(
        recognisable,
        greaterThan(_printedDishes.length ~/ 2),
        reason:
            'dish names stopped surviving the engine — '
            'M16 assumes they do; rewrite research §10 before relaxing this',
      );
    });

    test('the prices do not, and they fail in the dangerous direction', () {
      // The other half, and the uncomfortable one.
      //
      // The menu prints 23 prices, 19 distinct. The engine returned 12
      // numbers; 2 were right and 10 match nothing printed anywhere on it.
      // They are wrong in one consistent way — the left-hand digit is lost
      // and the right-hand one survives, so 28 arrives as 8 and 74 as 4.
      //
      // That is a *plausible wrong number*, which is the failure #257 was and
      // the one this project keeps having to re-learn. A price that comes
      // back as nothing is safe; a price that comes back as 8 is not.
      final returned = _numbersIn(PhotographedMenuOcrFixture.vivie);
      final printed = _printedPrices.toSet();

      final correct = returned.toSet().intersection(printed);
      final spurious = returned.where((n) => !printed.contains(n));

      // Pinned as the measured deficiency it is, exactly as
      // `real_ocr_pipeline_test.dart` pins the lost carbohydrate row of the
      // pointed wafer. **If this fails because `correct` grew, that is good
      // news and the fix is to update §10 and this expectation — not to
      // loosen it.**
      expect(
        correct.length,
        lessThan(printed.length ~/ 2),
        reason:
            'the engine started reading menu prices — '
            'update research §10, this is a finding changing',
      );
      expect(
        spurious,
        isNotEmpty,
        reason:
            'the spurious-number hazard is the reason M16 must not '
            'surface a scanned price as fact',
      );
    });

    test('psm 4 kept each dish on its own row', () {
      // #372 asks whether the inherited `psm 4` reads across a menu's columns
      // and interleaves them, or keeps each dish with its price. On this
      // photograph it kept the rows: dish text and price land on one line,
      // and no line is a run of bare prices with the dishes elsewhere.
      //
      // So the column risk research §5 raised is not what went wrong here.
      // The layout held and the digits did not, which points M16 at the
      // engine rather than at the prompt's "columns may be interleaved"
      // instruction.
      final bareNumberLines = lines
          .where((line) => RegExp(r'^[\d\s.,₪]+$').hasMatch(line))
          .length;

      expect(
        bareNumberLines,
        isZero,
        reason:
            'a line of prices with no dish on it means the columns were '
            'read separately — research §5 column risk, now live',
      );
      expect(lines.where(_hasHebrew).length, greaterThan(15));
    });
  });
}

/// The dishes the menu prints, transcribed from the photograph by eye.
///
/// Ground truth has to be supplied by a human — a fixture that generated its
/// own answer key would score the engine against itself. It lives in the test
/// rather than in `photographed_menu_ocr_fixture.dart` so that the generated
/// file stays entirely generated and "do not hand-edit" stays true of every
/// line in it.
const List<String> _printedDishes = [
  'בייגלה ירושלמי, חמאה מלוחה ווינגרט מני',
  'צלחת חריפים',
  'ברוסקטה סרדינים כבושים',
  'אויסטר, חומץ שאלוט, שמן צילי',
  'טרטר דג ים, איולי חמאה חומה, בריוש',
  'סביצה דג ים, חלפיניו כוסברה וליים',
  'קרפצו דג ים, שרי, עלי ריחן, פרחי שומר',
  'טרטר בקר, רוטב קיסר, שאלוט על הגריל, בריוש',
  'חסות, אגוזי לוז, בושה על פחם, פרי העונה',
  'עגבניות מגי, עגבניות לב השור, גבינת סטרצלה, שמן זית וקרוטונים',
  'פטריית מלך היער, ציר פורציני, קרם קשיו',
  'תירס גמדי על הגריל, רליש שיפקה ובצל ירוק, פרמזן, חמאה חומה',
  'ניוקי צרוב, בר בלאן, פירורי בריוש',
  'ריזוטו, פטריות בלו אויסטר',
  'שיפוד דג ים, עגבניות מגי ושאלוט על הגריל, יוגורט באפלו',
  'פילה דג ים, אורז אסור, ביסק סרטנים',
  'מול מרינייר וציפס',
  'לברק שלם על פחמים, שעועית תאילנדית ופירה, מרינייר',
  'שניצל דג, רוטב טרטר, פירה',
  'ציז בורגר, רוטב טרטר, ציפס',
  'שיפוד שקדי עגל, קרם תירס, צר עוף חום',
  'סינטה פרהוס, פירה, פלפלת',
  'ניו יורק קאט, פלפלת ופירה',
];

/// The prices the menu prints, in printed order. Transcribed by eye, as above.
///
/// 23 of them, 19 distinct — 72 and 79 each appear twice, which is why the
/// scoring above works on sets and not on the sequence.
const List<int> _printedPrices = [
  28,
  18,
  52,
  24,
  74,
  73,
  78,
  72,
  63,
  64,
  58,
  62,
  79,
  83,
  109,
  132,
  89,
  148,
  89,
  79,
  83,
  159,
  72,
];

bool _hasHebrew(String s) => s.runes.any((r) => r >= 0x0590 && r <= 0x05FF);

List<int> _numbersIn(String text) =>
    RegExp(r'\d+').allMatches(text).map((m) => int.parse(m.group(0)!)).toList();

/// The best similarity [dish] reaches against any line of the transcript.
double _bestSimilarity(String dish, List<String> lines) => lines
    .map((line) => _similarity(_letters(dish), _letters(line)))
    .fold(0, (best, score) => score > best ? score : best);

/// Hebrew letters only — punctuation and spacing are exactly what a menu's
/// typography and the engine disagree about, and neither carries meaning for
/// "is this dish recognisable".
String _letters(String s) => s.runes
    .where((r) => r >= 0x05D0 && r <= 0x05EA)
    .map(String.fromCharCode)
    .join();

/// 1 minus the normalised Levenshtein distance, clamped at 0.
///
/// A transcript line is usually longer than the dish it carries (it has the
/// price on the end), so the distance is normalised by the *dish* length and
/// insertions past the end of the dish are not charged — the question is
/// whether the dish is in the line, not whether the line is only the dish.
double _similarity(String dish, String line) {
  if (dish.isEmpty) {
    return 0;
  }
  final distance = _prefixEditDistance(dish, line);
  final score = 1 - distance / dish.length;
  return score < 0 ? 0 : score;
}

/// Edit distance from [needle] to its best-matching substring of [haystack].
///
/// The standard Levenshtein table with the first row zeroed, so a match may
/// start anywhere in [haystack], and the answer taken as the minimum of the
/// last row, so it may end anywhere.
int _prefixEditDistance(String needle, String haystack) {
  var previous = List<int>.filled(haystack.length + 1, 0);
  for (var i = 1; i <= needle.length; i++) {
    final current = List<int>.filled(haystack.length + 1, 0);
    current[0] = i;
    for (var j = 1; j <= haystack.length; j++) {
      final substitution =
          previous[j - 1] + (needle[i - 1] == haystack[j - 1] ? 0 : 1);
      final deletion = previous[j] + 1;
      final insertion = current[j - 1] + 1;
      current[j] = substitution < deletion ? substitution : deletion;
      if (insertion < current[j]) {
        current[j] = insertion;
      }
    }
    previous = current;
  }
  return previous.reduce((a, b) => a < b ? a : b);
}

/// A recogniser that returns one captured string.
class _CannedRecognizer implements TextRecognitionService {
  const _CannedRecognizer(this.text);

  final String text;

  @override
  bool get isAvailable => true;

  @override
  Future<String> recognise(String imagePath) async => text;
}
