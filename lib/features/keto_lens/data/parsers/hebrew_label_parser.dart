import 'dart:math' as math;

import 'package:fantastic/features/keto_lens/data/parsers/hebrew_text_normaliser.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
import 'package:fantastic/features/keto_lens/domain/models/serving_basis.dart';
import 'package:fantastic/features/keto_lens/domain/services/label_parser.dart';

/// Extracts macros and an ingredient list from the raw text of an Israeli
/// Hebrew nutrition label.
///
/// Pure Dart — no Flutter, no plugin, no I/O — so the whole of it is testable
/// without a camera. That matters here more than anywhere else in the app:
/// nothing in this environment can run ML Kit, so this class and
/// `IngredientClassifierImpl` are the only parts of the scan pipeline that
/// anything can actually verify.
///
/// ## Why this is not four regexes
///
/// `design/m6_preflight.md` §1.2 lists the five ways the issue's four-regex
/// sketch fails on a real label. The short version: the keyword is plural as
/// often as singular (`שומנים`), OCR drops the space before the value, the
/// decimal separator is a comma, packaging is pointed, and the saturated-fat
/// row sits directly under the total-fat row using the same word.
///
/// So matching happens **per line, per keyword occurrence**, over text that
/// [HebrewTextNormaliser] has already flattened, and every value is the
/// number *nearest* its keyword rather than the first number in the string.
class HebrewLabelParser implements LabelParser {
  const HebrewLabelParser();

  /// One Hebrew or Latin letter — what OCR inserts or substitutes when it
  /// splits a glyph or reads a table rule as a character.
  ///
  /// Deliberately not `.`: a digit or a bracket standing in the middle of a
  /// keyword is not a corruption this has ever been seen to produce, and
  /// allowing them widens every pattern below for no measured gain.
  static const String _strayLetter = '[\u0590-\u05FFA-Za-z]';

  /// Builds a pattern matching [letters] with **at most one** OCR corruption.
  ///
  /// ## Why this is needed at all
  ///
  /// Tesseract 5.3.4 reads this label's protein row as `חלבונים`. Tesseract
  /// 5.5.3, on a macOS CI runner, reads the same image as **`חזלבונים`** — a
  /// spurious `ז`. An exact `חלבו[נן]` does not match that, so on a Mac the
  /// scan succeeded with every other macro present, the basis correctly
  /// `per100g`, and **protein silently missing**: a confident-looking result
  /// with a hole in it. Raw engine output is not stable across versions, so
  /// the matcher has to absorb a little of that variation.
  ///
  /// ## Why it is this narrow, and not edit distance
  ///
  /// A general "distance ≤ 1" matcher is far too loose here, and loose is
  /// *dangerous* rather than merely untidy: a matcher that lets `שומנים` pick
  /// up the `מתוכם שומן רווי` row reports **saturated fat as total fat** — a
  /// plausible, wrong, silently-logged number, which is the failure mode this
  /// whole feature exists to prevent. A missing protein is strictly better.
  ///
  /// So three deliberate restrictions:
  ///
  /// * **One corruption, not one per gap.** The alternation spells out each
  ///   single-error form rather than making every position optional.
  /// * **The first letter is never substituted.** It is the strongest
  ///   evidence of which keyword this is; allowing `.לבו` would let an
  ///   unrelated word in.
  /// * **The last letter is never substituted either.** `שומ.` would match
  ///   `שומש` inside `משומשום` — sesame, which is an *ingredient* on the
  ///   project's own tahini fixture, not a fat row.
  ///
  /// Insertion is allowed at any interior gap, because that is the corruption
  /// actually observed, and an inserted letter cannot turn one keyword into
  /// another — every original letter is still required, in order.
  ///
  /// Words shorter than four letters get **no** tolerance: one error in three
  /// letters is not a corrupted word, it is a different word.
  static String _tolerant(List<String> letters) {
    final forms = <String>[letters.join()];

    if (letters.length >= 4) {
      // One inserted letter, at each interior gap.
      for (var i = 1; i < letters.length; i++) {
        forms.add(
          letters.sublist(0, i).join() +
              _strayLetter +
              letters.sublist(i).join(),
        );
      }
      // One substituted letter, interior positions only.
      for (var i = 1; i < letters.length - 1; i++) {
        forms.add(
          letters.sublist(0, i).join() +
              _strayLetter +
              letters.sublist(i + 1).join(),
        );
      }
    }

    // Exact first: the engine tries alternatives left to right, so an
    // uncorrupted keyword never pays for the tolerance.
    return '(?:${forms.join('|')})';
  }

  /// `שומן` (singular, final nun) and `שומנים` (plural, medial nun).
  ///
  /// Unanchored, so the definite article and the conjunction — `השומן`,
  /// `ושומנים` — match without a prefix rule.
  static final RegExp _fat = RegExp(_tolerant(['ש', 'ו', 'מ', '[נן]']));

  /// `פחמימה` / `פחמימות`.
  static final RegExp _carbs = RegExp(_tolerant(['פ', 'ח', 'מ', 'י', 'מ']));

  /// `סיבים` / `סיבים תזונתיים` / `סיבי`.
  ///
  /// Three letters, so no tolerance — see [_tolerant].
  static final RegExp _fibre = RegExp(_tolerant(['ס', 'י', 'ב']));

  /// `חלבון` (final nun) and `חלבונים` (medial nun).
  static final RegExp _protein = RegExp(
    _tolerant(['ח', 'ל', 'ב', 'ו', '[נן]']),
  );

  /// `ל-100 גרם`, `ל100 גרם`, `100 גר'`, `100 ג'`, `per 100 g`.
  ///
  /// Anchored on the number rather than the `ל` prefix: OCR drops the hyphen
  /// and sometimes the prefix, and `100` immediately before a gram word is not
  /// something a label says for any other reason.
  static final RegExp _basisPer100g = RegExp(
    "100\\s*(?:גרם|גר'|ג'|gr\\b|g\\b)",
  );

  /// `ל-100 מ"ל`, `100 מל`, `100 ml`.
  static final RegExp _basisPer100ml = RegExp('100\\s*(?:מ"ל|מל|ml\\b)');

  /// `למנה`, `למנת`, `לכל מנה` — the figures already describe one serving.
  ///
  /// The `ל` must be attached. `גודל מנה` contains the letters `ל מנה` with a
  /// space, and matching that would read every label that declares a serving
  /// *weight* as though its macros were per serving — turning the most useful
  /// label into the most dangerous one.
  static final RegExp _basisPerServing = RegExp('למנה|למנת|לכל מנה');

  /// `גודל מנה` / `משקל מנה` — the declared serving weight.
  ///
  /// Widened for condiments (#306): a spice or sauce jar is the product that
  /// most needs a declared portion, and it prints one in more shapes than the
  /// two rows a nutrition table uses.
  static final RegExp _servingSize = RegExp(
    'גודל מנה|גודל המנה|משקל מנה|מנה \\(|יחידה \\(|לכל יחידה|מנה בת',
  );

  /// A number immediately followed by a gram unit.
  ///
  /// `גודל מנה 2 יחידות (30 גרם)` declares a 30 g serving, not a 2 g one, so
  /// the weighed number wins over the first number after the keyword.
  static final RegExp _gramsValue = RegExp(
    r"(\d+(?:\.\d+)?|\.\d+)\s*(?:גרם|גר'?|ג'?|g\b|gr\b)",
  );

  /// `אנרגיה` / `קלוריות` — the panel's own check on itself (#306).
  static final RegExp _energy = RegExp(
    '${_tolerant(['א', 'נ', 'ר', 'ג', 'י', 'ה'])}|'
    '${_tolerant(['ק', 'ל', 'ו', 'ר', 'י', 'ו', 'ת'])}|kcal',
  );

  /// `מתוכם סוכרים`. The plural is deliberate — see [_ofWhich].
  static final RegExp _sugars = RegExp(
    _tolerant(['ס', 'ו', 'כ', 'ר', 'י', 'ם']),
  );

  /// `מתוכם רב כהליים` / `פוליאולים`.
  static final RegExp _polyols = RegExp(
    'רב[\\s-]?${_tolerant(['כ', 'ה', 'ל'])}|'
    '${_tolerant(['פ', 'ו', 'ל', 'י', 'א', 'ו', 'ל'])}|polyol',
  );

  /// A *positive* qualifier — the mirror of [_fatSubRow]'s disqualifier.
  ///
  /// Without it, the plain lookup's next-line fallback can pair an
  /// **ingredient** line containing `סוכר` with an unrelated bare number:
  /// `HebrewLabelFixture.pointedWafer` reads `רכיבים: קמח חיטה, סוכר, …`,
  /// which is exactly that trap. Matching the plural `סוכרים` is a second,
  /// independent guard; both are kept.
  static final RegExp _ofWhich = RegExp('מתוכם|מתוכן');

  /// Words that mark a *sub*-row of the fat block rather than total fat.
  ///
  /// An Israeli label reads
  /// `שומנים 12 גרם` / `מתוכם חומצות שומן רוויות 5 גרם` — the same word,
  /// one row down, with a number beside it. Without this the parser reports
  /// saturated fat as total fat, which is a plausible-looking wrong answer
  /// and therefore the worst kind.
  ///
  /// Deliberately *not* including `מתוכם`: fibre is legitimately reported as
  /// `מתוכם סיבים תזונתיים`, and excluding the qualifier would lose it.
  ///
  /// ## These are tolerant too, and that asymmetry is the point
  ///
  /// Making the *keywords* absorb an OCR error without doing the same here
  /// would be the worst possible half-measure: a corrupted `רווי` would stop
  /// disqualifying, the tolerant `שומ[נן]` would still match its row, and the
  /// saturated-fat figure would be reported as total fat. The two sides of
  /// this comparison have opposite risk profiles and must be tuned in
  /// opposite directions —
  ///
  /// * over-disqualifying loses the fat row: the value is `null`, the sheet
  ///   asks, nothing is logged wrong;
  /// * under-disqualifying logs a plausible wrong number.
  ///
  /// So when in doubt this side is the one that should fire. It already pays
  /// for itself: the real label prints `טראנס`, which the old exact `טרנס`
  /// **did not match at all** — the trans-fat row was never being disqualified
  /// on that label, and only line order was keeping it out of the fat field.
  static final RegExp _fatSubRow = RegExp(
    [
      ['ר', 'ו', 'ו', 'י'],
      ['ט', 'ר', 'נ', 'ס'],
      ['ב', 'ל', 'ת', 'י'],
      ['ח', 'ו', 'מ', 'צ', 'ו', 'ת'],
      ['כ', 'ו', 'ל', 'ס', 'ט', 'ר', 'ו', 'ל'],
    ].map(_tolerant).join('|'),
  );

  /// How far either side of a keyword a disqualifying word can sit.
  ///
  /// Windowed rather than whole-line because OCR sometimes returns the entire
  /// nutrition table as one line, and excluding that line would lose every
  /// macro on it.
  static const int _qualifierWindow = 14;

  /// A decimal number. The comma form is already `.` by the time this runs.
  static final RegExp _number = RegExp(r'\d+(?:\.\d+)?|\.\d+');

  /// A line holding nothing but a value and perhaps its unit — the shape a
  /// two-column table takes when OCR splits the columns into separate lines.
  static final RegExp _standaloneValue = RegExp(
    r"^(\d+(?:\.\d+)?|\.\d+)\s*(?:גרם|גר'?|ג'?|mg|g|gr)?$",
  );

  /// Where the ingredient list starts.
  ///
  /// `רכיבים` is the standard heading; `מרכיבים` and `הרכב` both occur.
  static final RegExp _ingredientsHeading = RegExp('מרכיבים|רכיבים|הרכב');

  /// Where the ingredient list stops.
  ///
  /// The issue's `dotAll: true` capture ran to the end of the OCR output, so
  /// on the common layout — ingredients printed above the table — every macro
  /// row became an "ingredient" and was handed to the classifier.
  static final RegExp _ingredientsTerminator = RegExp(
    'ערכים תזונתיים|מידע תזונתי|סימון תזונתי|עשוי להכיל|מכיל|אלרגנ|'
    'לשמור|אחסון|בקירור|יצרן|יבואן|תוצרת|משקל נטו|תאריך|כשר|בהשגחת',
  );

  /// Splits an ingredient run into tokens.
  ///
  /// `،` is the Arabic comma — bilingual packaging is common, and OCR reports
  /// the glyph it saw.
  static final RegExp _ingredientSeparators = RegExp('[,;،]');

  /// Characters to shave off a token's ends once it is split out.
  static final RegExp _tokenEdges = RegExp(
    r'''^[\s.:*()\[\]"'\-–—]+|[\s.:*()\[\]"'\-–—]+$''',
  );

  /// At least one letter in any script — drops `%`, `100`, and OCR crumbs.
  static final RegExp _hasLetter = RegExp(r'[֐-׿a-zA-Z]');

  @override
  ParsedLabel parse(String ocrText) {
    try {
      final lines = HebrewTextNormaliser.normalise(ocrText).split('\n');

      final fat = _valueFor(lines, _fat, disqualifier: _fatSubRow);
      final carbs = _valueFor(lines, _carbs);
      final fibre = _valueFor(lines, _fibre);
      final protein = _valueFor(lines, _protein);
      final basis = _basisFor(lines);

      return ParsedLabel(
        fatG: fat,
        // Net carbs = total − fibre, floored at zero. Null stays null: a
        // carbohydrate figure that was never found is not the same as zero,
        // and `ParsedLabel` documents null as "not found".
        netCarbsG: carbs == null
            ? null
            : math.max(0, carbs - (fibre ?? 0)).toDouble(),
        proteinG: protein,
        ingredients: _ingredients(lines),
        rawText: ocrText,
        basis: basis,
        // Read even when the basis is unknown: a two-column label is exactly
        // the case where the declared serving weight is most useful to show,
        // and it costs nothing to carry.
        servingGrams: _valueFor(lines, _servingSize, preferring: _gramsValue),
        // Carried rather than discarded (#306): a polyol subtraction has to be
        // checked against them, and the energy cross-check needs *total*
        // carbohydrate rather than net.
        totalCarbsG: carbs,
        fibreG: fibre,
        // Gated on `מתוכם`, so an ingredient list naming sugar cannot supply
        // the sugars row.
        sugarsG: _valueFor(lines, _sugars, requirement: _ofWhich),
        polyolsG: _valueFor(lines, _polyols, requirement: _ofWhich),
        energyKcal: _valueFor(lines, _energy),
      );
    } on Object {
      // The interface promises `parse` never throws: garbled input is a
      // failed scan for the caller to render, not an error to propagate.
      // Catching `Object` rather than `Exception` for the reason
      // `guardPersistence` does — a bad index or cast throws an `Error`.
      return ParsedLabel(rawText: ocrText);
    }
  }

  /// The number belonging to the first qualifying occurrence of [keyword].
  ///
  /// Walks lines in order. A line whose keyword occurrence is disqualified is
  /// not abandoned — the next occurrence *on the same line* is tried, because
  /// a single-line OCR dump holds the whole table.
  /// Which basis the label's figures are printed against.
  ///
  /// Deliberately refuses to guess. Exactly one marker in the text resolves to
  /// that basis; **zero or more than one resolves to [ServingBasis.unknown]**
  /// — and more-than-one is the common, dangerous case, because a great many
  /// Israeli labels print two columns, per 100 g *and* per serving, with no
  /// reliable way to tell from flattened OCR text which column a number came
  /// from.
  ///
  /// Picking a column there would produce a plausible, wrong, silently-logged
  /// number. `unknown` produces a question instead. #257 exists because the
  /// first of those shipped.
  static ServingBasis _basisFor(List<String> lines) {
    final text = lines.join('\n');
    final found = <ServingBasis>{
      if (_basisPer100g.hasMatch(text)) ServingBasis.per100g,
      if (_basisPer100ml.hasMatch(text)) ServingBasis.per100ml,
      if (_basisPerServing.hasMatch(text)) ServingBasis.perServing,
    };
    return found.length == 1 ? found.single : ServingBasis.unknown;
  }

  static double? _valueFor(
    List<String> lines,
    RegExp keyword, {
    RegExp? disqualifier,
    RegExp? requirement,
    RegExp? preferring,
  }) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final match in keyword.allMatches(line)) {
        if (disqualifier != null && _nearMatch(line, match, disqualifier)) {
          continue;
        }
        // The same window, polarity inverted: a sub-row is only a sub-row if
        // the qualifier that makes it one is actually beside it.
        if (requirement != null && !_nearMatch(line, match, requirement)) {
          continue;
        }
        if (preferring != null) {
          final preferred = preferring.firstMatch(line);
          if (preferred != null) {
            return double.tryParse(preferred.group(1)!);
          }
        }
        final onLine = _numberNear(line, match);
        if (onLine != null) {
          return onLine;
        }
        // Nothing on this line: a two-column table whose value column OCR
        // reported as its own line.
        if (i + 1 < lines.length) {
          final next = _standaloneValue.firstMatch(lines[i + 1]);
          if (next != null) {
            return double.tryParse(next.group(1)!);
          }
        }
      }
    }
    return null;
  }

  /// Whether [disqualifier] appears within [_qualifierWindow] characters of
  /// [match] on either side.
  static bool _nearMatch(String line, Match match, RegExp disqualifier) {
    final start = math.max(0, match.start - _qualifierWindow);
    final end = math.min(line.length, match.end + _qualifierWindow);
    return disqualifier.hasMatch(line.substring(start, end));
  }

  /// The number closest to [keyword] on its own line.
  ///
  /// After the keyword first — that is where a label puts the value — then
  /// before it, which is where a reordered OCR line puts it.
  static double? _numberNear(String line, Match keyword) {
    final numbers = _number.allMatches(line).toList();
    for (final n in numbers) {
      if (n.start >= keyword.end) {
        return double.tryParse(n.group(0)!);
      }
    }
    for (final n in numbers.reversed) {
      if (n.end <= keyword.start) {
        return double.tryParse(n.group(0)!);
      }
    }
    return null;
  }

  /// The ingredient tokens, in label order.
  ///
  /// Casing is preserved. The issue lowercased here; matching is the
  /// classifier's job and it lowercases for itself, while these strings are
  /// also what `ScanResultSheet` shows the user as the flagged list.
  static List<String> _ingredients(List<String> lines) {
    final run = <String>[];
    var started = false;

    for (final line in lines) {
      if (!started) {
        final heading = _ingredientsHeading.firstMatch(line);
        if (heading == null) {
          continue;
        }
        started = true;
        final tail = line.substring(heading.end);
        if (tail.trim().isNotEmpty) {
          run.add(tail);
        }
        continue;
      }
      if (line.isEmpty ||
          _ingredientsTerminator.hasMatch(line) ||
          _looksLikeMacroRow(line)) {
        break;
      }
      run.add(line);
    }

    if (!started) {
      return const [];
    }

    return run
        .join(' ')
        .split(_ingredientSeparators)
        .map((token) => token.replaceAll(_tokenEdges, ''))
        .where((token) => token.isNotEmpty && _hasLetter.hasMatch(token))
        .toList(growable: false);
  }

  /// Whether [line] is a row of the nutrition table rather than ingredients.
  ///
  /// A macro keyword *and* a digit: `שומן זית` is an ingredient, `שומנים 12`
  /// is where the ingredient list ended.
  static bool _looksLikeMacroRow(String line) =>
      _number.hasMatch(line) &&
      (_fat.hasMatch(line) ||
          _carbs.hasMatch(line) ||
          _fibre.hasMatch(line) ||
          _protein.hasMatch(line));
}
