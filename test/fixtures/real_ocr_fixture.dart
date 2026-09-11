/// Genuine Tesseract output, captured from real Hebrew labels.
///
/// Every other fixture in this directory was written by hand, and
/// `design/m6_handoff.md` is blunt about what that is worth:
///
/// > they were written by the same person who wrote the parser, which is
/// > exactly the kind of test that passes and then fails on a real label.
///
/// These are the opposite. Nobody chose these strings: each is the verbatim
/// stdout of Tesseract against the models this app bundles
/// (`assets/tessdata/heb.traineddata` + `eng.traineddata`, tessdata_fast) at
/// the settings the app actually runs — `-l heb+eng --psm 4
/// -c user_defined_dpi=300`, over an image put through the same
/// `OcrImagePrep` scaling step the app applies before a scan. Whatever the
/// engine got wrong is preserved, mistakes included.
///
/// **Generated, not written. Do not hand-edit.** Regenerate with
/// `tool/capture_ocr_fixtures.sh`; the value of this file is exactly that no
/// hand touched it. Re-read the assertions afterwards — a changed model, a
/// changed setting or a changed renderer can legitimately change what comes
/// back.
///
/// ## Two kinds of source, and the difference matters
///
/// [tahini], [proteinBar] and [pointedWafer] are **rendered**: the app's own
/// Assistant font at the app's own RTL layout, via `tool/render_labels.py`.
/// No camera, no glare, no curve, no shop lighting.
///
/// [wholeWheatRyeBread] is **photographed** — an actual Israeli product label,
/// supplied by the user whose failed scan prompted the fix that this fixture
/// guards. It is a bordered two-column table, which is the layout that broke:
/// numbers in the left column, Hebrew labels in the right. It closes the gap
/// between "a human imagined this OCR output" and "an engine produced it on a
/// real label".
///
/// **It does not close the gap to a shop.** It is screenshot quality — a clean,
/// flat, well-lit crop, not a photograph taken at arm's length off a curved
/// bread bag under supermarket lighting. There is still no camera in this
/// repository, no accuracy figure is claimed, and issue #256 and Epic #10 stay
/// open.
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

  /// A pointed (niqqud) label. The English model wins a word it should not here and the carbohydrate row is lost - the measured, accepted cost of loading `eng` for digits. See `TessdataBundle`.
  static const String pointedWafer = """
ופל בטעם וניל

רכיבים: קמח חיטה, סוכר, שמן קנולה, מלטודקסטרין, מלח
ערכים תזונתיים ל-100 גרם

שוּמֶן 24 גר'

‎Nin nnd‏ 62 גר

‏סיבים תזונתיים 2 גר'

‏חלבונים 6 גר'""";

  /// A real photographed Israeli label: whole wheat + rye bread, a bordered two-column table with the numbers in the left column. This is the label that could not be scanned at all before `psm 4` + `heb+eng` + `user_defined_dpi`; under the old settings six of its nine rows came back as punctuation.
  static const String wholeWheatRyeBread = """
@ שיפון

‎Wy‏ תזונתי ל-100 גר' מוצר
אנרגיה (קלוריות ) 238
חלבונים (גרם) 10.9

‏פחמימות (גרם) 41.2

‏כלל סיבים תזונתיים (גרם) ] 7

‏שומנים (גרם) 3.3

‏מתוכם שומן רווי (גרם) 0.9

‏מתוכם שומן טראנס (גרם) ן] פחות מ-0.5
מתוכם כולסטרול (מ"ג) פחות מ-2.5
נתרן (מ"ג) 368""";
}
