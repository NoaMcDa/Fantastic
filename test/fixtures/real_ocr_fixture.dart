/// Genuine Tesseract output, captured from rendered Hebrew labels.
///
/// Every other fixture in this directory was written by hand, and
/// `design/m6_handoff.md` is blunt about what that is worth:
///
/// > they were written by the same person who wrote the parser, which is
/// > exactly the kind of test that passes and then fails on a real label.
///
/// These are the opposite. Nobody chose these strings: each is the verbatim
/// stdout of `tesseract <label>.png - -l heb --psm 6` against the model this
/// app actually bundles (`assets/tessdata/heb.traineddata`, tessdata_fast),
/// on an image rendered from the app's own Assistant font at the app's own
/// RTL layout. Whatever the engine got wrong is preserved, mistakes included
/// - [pointedWafer] is here precisely because it is wrong.
///
/// **Still not the real thing.** These are renders, not photographs of
/// packaging: no glare, no curve, no shop lighting, no focus error. They close
/// the gap between "a human imagined this output" and "an engine produced it",
/// which is the gap that has bitten this project; they do not close the gap to
/// a real product. `design/m6_platform_research.md` Part 7 is still the
/// outstanding work.
///
/// Regenerate with `tool/capture_ocr_fixtures.sh`. Do not hand-edit: the value
/// of this file is exactly that no hand touched it.
abstract final class RealOcrFixture {
  /// Raw tahini, cleanly printed. Every row and every number survived the engine.
  static const String tahini = """
טחינה גולמית משומשום מלא
ערכים תזונתיים ל-100 גרם
שומנים 53.8 גרם
מתוכם חומצות שומן רוויות 7.6 גרם
פחמימות 10.5 גרם
מתוכם סוכרים 0.9 גרם
סיבים תזונתיים 9.3 גרם
חלבונים 26.5 גרם
נתרן 25 מ"ג
רכיבים: 100% שומשום מלא""";

  /// A protein bar: Israeli decimal comma (22,5), ingredients printed above the table, maltitol in them.
  static const String proteinBar = """
חטיף חלבון בטעם שוקולד
רכיבים: חלבון מי גבינה, מלטיטול, שמן קוקוס, קקאו, אגוזי לוז, מלח.
ערכים תזונתיים ל-100 גרם
שומנים 22,5 גרם
מתוכם חומצות שומן רוויות 9 גרם
פחמימות 30 גרם
מתוכם רב כהליים 25 גרם
סיבים תזונתיים 8 גרם
חלבונים 33 גרם""";

  /// A pointed (niqqud) label - the one case the engine did NOT read cleanly. See the class doc.
  static const String pointedWafer = """
ופל בטעם וניל
רכיבים: קמח חיטה, סוכר, שמן קנולה, מלטודקסטרין, מלח
ערכים תזונתיים ל-100 גרם
שוּמֶן 24 גר'
פחמִימות 62 גר
סיבים תזונתיים 2 גר'
חלבונים 6 גר'""";
}
