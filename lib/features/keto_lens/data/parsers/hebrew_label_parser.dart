import 'dart:math' as math;

import 'package:fantastic/features/keto_lens/data/parsers/hebrew_text_normaliser.dart';
import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
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

  /// `שומן` (singular, final nun) and `שומנים` (plural, medial nun).
  ///
  /// Unanchored, so the definite article and the conjunction — `השומן`,
  /// `ושומנים` — match without a prefix rule.
  static final RegExp _fat = RegExp('שומ[נן]');

  /// `פחמימה` / `פחמימות`.
  static final RegExp _carbs = RegExp('פחמימ');

  /// `סיבים` / `סיבים תזונתיים` / `סיבי`.
  static final RegExp _fibre = RegExp('סיב');

  /// `חלבון` (final nun) and `חלבונים` (medial nun).
  static final RegExp _protein = RegExp('חלבו[נן]');

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
  static final RegExp _fatSubRow = RegExp('רווי|טרנס|בלתי|חומצות|כולסטרול');

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
  static double? _valueFor(
    List<String> lines,
    RegExp keyword, {
    RegExp? disqualifier,
  }) {
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      for (final match in keyword.allMatches(line)) {
        if (disqualifier != null && _nearMatch(line, match, disqualifier)) {
          continue;
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
