/// Realistic raw OCR output from Israeli Hebrew nutrition labels.
///
/// Epic #10's architectural invariants require the pipeline to be tested
/// "against real Hebrew label OCR fixtures (min. 5)", and no child issue
/// created any. These are that set.
///
/// They are deliberately *not* the clean, singular, ASCII-digit strings the
/// issue text used. `design/m6_preflight.md` §1.2 lists what a real label
/// does that a toy fixture does not, and each fixture here carries at least
/// one of it:
///
/// | Fixture | What it exercises |
/// |---|---|
/// | [tahini] | plural keyword, a saturated-fat sub-row using the same word, ingredients printed *after* the table |
/// | [proteinBar] | decimal comma, ingredients printed *before* the table, a sweetener, an ingredient line containing the word "protein" |
/// | [pointedWafer] | niqqud on the keywords, a geresh gram abbreviation, a forbidden seed oil |
/// | [twoColumn] | the value column split onto its own lines, which is what OCR does to a table |
/// | [importedOliveOil] | Latin product name, a zero macro, no fibre row at all |
/// | [unreadable] | OCR noise with no label in it |
///
/// Per `design/tests.md`, fixtures live here and are never inlined in a test.
abstract final class HebrewLabelFixture {
  /// Raw tahini. Clean: one ingredient, no oils, no sweeteners.
  ///
  /// The interesting part is the second fat row. "Of which saturated fatty
  /// acids" repeats the word the total-fat row used, one line down, with its
  /// own number beside it - so a parser that takes the first match reports
  /// 7.6 g of fat for a product that has 53.8.
  static const String tahini = '''
טחינה גולמית משומשום מלא
ערכים תזונתיים ל-100 גרם
שומנים 53.8 גרם
מתוכם חומצות שומן רוויות 7.6 גרם
פחמימות 10.5 גרם
מתוכם סוכרים 0.9 גרם
סיבים תזונתיים 9.3 גרם
חלבונים 26.5 גרם
נתרן 25 מ"ג
רכיבים: 100% שומשום מלא''';

  /// A protein bar sweetened with maltitol.
  ///
  /// Two traps. The weight is written "22,5" - an Israeli decimal comma,
  /// which `double.tryParse` rejects outright. And the ingredient list, which
  /// is printed above the table, opens with "whey protein" - the protein
  /// keyword, on a line with no number on it.
  static const String proteinBar = '''
חטיף חלבון בטעם שוקולד
רכיבים: חלבון מי גבינה, מלטיטול, שמן קוקוס, קקאו, אגוזי לוז, מלח.
ערכים תזונתיים ל-100 גרם
שומנים 22,5 גרם
מתוכם חומצות שומן רוויות 9 גרם
פחמימות 30 גרם
מתוכם רב כהליים 25 גרם
סיבים תזונתיים 8 גרם
חלבונים 33 גרם''';

  /// A pointed label - niqqud on the nutrition keywords - fried in canola.
  ///
  /// Vowel points are ordinary on religious-market and children's packaging.
  /// They are combining characters, so the pointed spelling shares no
  /// code-point sequence with the plain one and no literal match fires until
  /// `HebrewTextNormaliser` has stripped them. The gram abbreviation uses a
  /// geresh rather than a spelled-out word.
  static const String pointedWafer = '''
ופל בטעם וניל
רכיבים: קמח חיטה, סוכר, שמן קנולה, מלטודקסטרין, מלח
ערכים תזונתיים ל-100 גרם
שׁוּמָן 24 גר׳
פַחמִימוֹת 62 גר׳
סיבים תזונתיים 2 גר׳
חלבונים 6 גר׳''';

  /// A two-column table whose columns OCR reported as separate lines.
  ///
  /// ML Kit groups text spatially, so a narrow label with the nutrient names
  /// in one column and the values in another comes back as the names, then
  /// the values - never interleaved. Every keyword line here has no number
  /// on it at all.
  static const String twoColumn = '''
ערכים תזונתיים
ל-100 גרם
שומנים
40
פחמימות
6
סיבים תזונתיים
2
חלבונים
20
רכיבים: שמן זית, אגוזי מלך, מלח ים''';

  /// An imported bottle: Latin product name, Hebrew importer sticker.
  ///
  /// No fibre row at all - net carbs must fall back to total carbs rather
  /// than to null - and two macros that are genuinely zero, which is a found
  /// value and not a missing one.
  static const String importedOliveOil = '''
Extra Virgin Olive Oil
רכיבים: שמן זית כתית מעולה
ערכים תזונתיים ל-100 מ"ל
שומנים 100 גרם
פחמימות 0 גרם
חלבונים 0 גרם
יבואן: כרמל בע"מ''';

  /// What ML Kit returns when it is pointed at a crumpled wrapper.
  ///
  /// There is no label in this. Every macro must come back null and `parse`
  /// must not throw.
  static const String unreadable = '''
Ilil |I| l1
~~~ ### ~~~
0O0 |||''';

  /// A two-column label: per 100 g **and** per serving, side by side.
  ///
  /// The case #257 exists to make safe. OCR flattens the columns, so there is
  /// no reliable way to tell which column a given number came from — and
  /// picking one produces a plausible, wrong, silently-logged figure. The
  /// parser must resolve this to [ServingBasis.unknown].
  static const String twoColumnBasis = '''
עוגיות שוקולד צ'יפס
ערכים תזונתיים ל-100 גרם ולמנה
גודל מנה 25 גרם
שומנים 24 גרם
פחמימות 60 גרם
סיבים תזונתיים 3 גרם
חלבונים 7 גרם''';

  /// A label whose figures are per serving only, with a declared weight.
  ///
  /// Must NOT be scaled: the numbers already describe one serving.
  static const String perServingOnly = '''
חטיף אגוזים
ערכים תזונתיים למנה
גודל מנה 40 גרם
שומנים 18 גרם
פחמימות 6 גרם
סיבים תזונתיים 2 גרם
חלבונים 5 גרם''';

  /// A drink, declared per 100 ml.
  static const String per100ml = '''
משקה שקדים ללא סוכר
ערכים תזונתיים ל-100 מ"ל
שומנים 1.1 גרם
פחמימות 0.4 גרם
חלבונים 0.5 גרם''';

  /// A per-100 g label that also declares its serving weight.
  ///
  /// The best case: the basis is unambiguous AND the amount field can be
  /// prefilled with what the package calls a serving.
  static const String per100gWithServing = '''
חטיף חלבון
ערכים תזונתיים ל-100 גרם
גודל מנה 30 גרם
שומנים 20 גרם
פחמימות 10 גרם
סיבים תזונתיים 4 גרם
חלבונים 30 גרם''';
}
