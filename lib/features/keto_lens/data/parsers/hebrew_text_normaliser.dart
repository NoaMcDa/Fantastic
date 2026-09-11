/// Turns raw ML Kit output into a form Hebrew keyword matching can rely on.
///
/// Pure Dart, no Flutter, no plugin types - it is a string function. It is
/// separated from `HebrewLabelParser` because every rule here is about the
/// Hebrew script rather than about nutrition labels, and each one has its own
/// test.
///
/// Nothing here is cosmetic. A parser that skips normalisation matches the
/// fixtures written alongside it and fails on real packaging:
///
/// * **Niqqud.** Religious-market and children's packaging is pointed. A
///   pointed spelling of "fat" shares no code-point sequence with the plain
///   one, so a literal match never fires. The vowel and cantillation marks
///   are combining characters in U+0591-U+05C7 and carry no lexical meaning
///   here.
/// * **Geresh.** The gram abbreviation is written with U+05F3 HEBREW
///   PUNCTUATION GERESH, U+0027 APOSTROPHE or U+2019 RIGHT SINGLE QUOTATION
///   MARK depending on the font the label was set in, and OCR reports
///   whichever it saw.
/// * **Bidi controls.** ML Kit emits U+200E/U+200F around digit runs in
///   right-to-left text. They are invisible and they break adjacency.
/// * **The decimal comma.** "12,5" is an ordinary weight on an Israeli label,
///   and `double.tryParse('12,5')` returns null.
///
/// Every pattern below is spelled with `\u` escapes rather than the
/// characters themselves. Several of them are invisible or bidirectional, and
/// pasting them into source is how a file comes to read differently from how
/// it compiles - the analyzer's `text_direction_code_point_in_literal`
/// warning exists for exactly that.
abstract final class HebrewTextNormaliser {
  /// Combining vowel points and cantillation marks.
  ///
  /// The block U+0591-U+05C7 also holds four *non*-combining characters,
  /// which are excluded here and handled below: U+05BE MAQAF (a hyphen),
  /// U+05C0 PASEQ, U+05C3 SOF PASUQ and U+05C6 NUN HAFUKHA.
  static final RegExp _diacritics = RegExp(
    '[\\u0591-\\u05BD\\u05BF\\u05C1\\u05C2\\u05C4\\u05C5\\u05C7]',
  );

  /// Maqaf, paseq and sof pasuq - punctuation, replaced by a space rather
  /// than deleted so a maqaf-joined compound does not collapse into one word.
  static final RegExp _hebrewPunctuation = RegExp('[\\u05BE\\u05C0\\u05C3]');

  /// Bidi embedding, override and isolate controls, plus the zero-width
  /// marks ML Kit wraps around digit runs.
  static final RegExp _bidiControls = RegExp(
    '[\\u200B-\\u200F\\u202A-\\u202E\\u2066-\\u2069]',
  );

  /// Every apostrophe-shaped character that can stand in for a geresh.
  static final RegExp _gereshVariants = RegExp(
    '[\\u05F3\\u2018\\u2019\\u02BC]',
  );

  /// Every quote-shaped character that can stand in for a gershayim.
  static final RegExp _gershayimVariants = RegExp('[\\u05F4\\u201C\\u201D]');

  /// A comma used as a decimal separator - between two digits, rather than
  /// between two ingredients.
  static final RegExp _decimalComma = RegExp(r'(?<=\d),(?=\d)');

  /// Runs of spaces and tabs, but **not** newlines.
  ///
  /// Line structure is load-bearing: `HebrewLabelParser` uses it to tell a
  /// total-fat row from the saturated-fat row beneath it, and to find a value
  /// that OCR put in the next line of a two-column table.
  static final RegExp _horizontalWhitespace = RegExp(r'[^\S\n]+');

  /// Any line separator OCR might emit, collapsed to a newline.
  static final RegExp _lineBreaks = RegExp('\\r\\n|\\r|\\u2028|\\u2029');

  /// A no-break space, which OCR produces from a justified line.
  static const String _noBreakSpace = ' ';

  /// Normalises [text] for keyword matching.
  ///
  /// Idempotent: normalising an already-normalised string returns it
  /// unchanged, which is what lets the parser normalise once at the top and
  /// pass the result down.
  static String normalise(String text) => text
      .replaceAll(_lineBreaks, '\n')
      .replaceAll(_diacritics, '')
      .replaceAll(_bidiControls, '')
      .replaceAll(_hebrewPunctuation, ' ')
      .replaceAll(_gereshVariants, "'")
      .replaceAll(_gershayimVariants, '"')
      .replaceAll(_noBreakSpace, ' ')
      .replaceAll(_decimalComma, '.')
      .replaceAll(_horizontalWhitespace, ' ')
      .split('\n')
      .map((line) => line.trim())
      .join('\n')
      .trim();

  /// Strips the inseparable one-letter prefix Hebrew attaches to a noun.
  ///
  /// An ingredient list reads "oil canola and-oil soya" as one run, and the
  /// conjunction is glued to the next word. Rule matching is `contains`
  /// based, so a prefix on the *first* letter of a token is the only place a
  /// rule word can hide - and it hides it completely.
  ///
  /// Only the seven inseparable prefixes are stripped, only one of them, and
  /// only when at least three letters remain, so that short words are not
  /// eaten. This is a heuristic, not morphology: the classifier matches the
  /// stripped form *in addition to* the original, never instead of it, so a
  /// wrong strip cannot lose a match.
  static String stripPrefix(String token) {
    if (token.length < 4) {
      return token;
    }
    if (!prefixLetters.contains(token[0])) {
      return token;
    }
    return token.substring(1);
  }

  /// Vav, he, bet, lamed, mem, shin, kaf - the inseparable prefixes.
  static const Set<String> prefixLetters = {'ו', 'ה', 'ב', 'ל', 'מ', 'ש', 'כ'};
}
