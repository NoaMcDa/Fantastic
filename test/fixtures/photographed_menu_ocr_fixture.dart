/// Genuine Tesseract output, captured from a **photographed** restaurant menu.
///
/// The third tier of M16's corpus and the only one that could not be
/// manufactured here. Tier one is menu text somebody typed; tier two is a menu
/// rendered in the app's own font, flat and evenly lit. This is neither: it is
/// a real Israeli restaurant menu, photographed off the table, at the angle
/// and the distance and the lighting a user actually gets.
///
/// Verbatim stdout of Tesseract against the models this app bundles
/// (`assets/tessdata/heb.traineddata` + `eng.traineddata`, tessdata_fast) at
/// the settings the app actually runs — `-l heb+eng --psm 4
/// -c user_defined_dpi=300` — over an image put through the app's own
/// `ScalingTextRecognizer.prepare`. Captured on **tesseract 5.3.4**. Whatever the
/// engine got wrong is preserved, and a great deal of it is wrong.
///
/// **Generated, not written. Do not hand-edit.** Regenerate with
/// `tool/capture_menu_ocr_fixtures.sh`.
///
/// ## The source image was already compressed, and that is part of the finding
///
/// [vivie] was supplied at **480x640, 40 KB** — a phone photograph after a
/// messaging app had had it. Nothing here downscaled it further; it arrived
/// that way, which is how a photograph normally reaches an app that accepts
/// one from the gallery. `OcrImagePrep` grows it to 1600 px wide before the
/// engine sees it, its `maxUpscale` of 4 not even reached.
///
/// ## What it found: the dish names read, the prices do not
///
/// This is the uncomfortable half of M16 and it belongs in the fixture rather
/// than only in a design document.
///
/// The menu prints **23 prices**, 19 of them distinct. The pipeline returned
/// **12 numbers**. Two of them were right. The other ten match nothing printed
/// anywhere on the menu, and they are wrong in one consistent way: the
/// left-hand digit is gone and the right-hand one survives. `28` came back as
/// `8`, `18` as `8`, `74` as `4`, `63` as `3`, `58` as `8`. Both prices that
/// survived whole — `72` and `79` — did so complete; nothing came back
/// half-right in the other direction.
///
/// A scanner that reads a 28 shekel dish as 8 shekels has not failed visibly.
/// It has lied quietly, in the exact shape #257 was, and a user has no way to
/// tell the two apart from the result alone. The nine dishes of the third
/// section returned no number at all, which is the honest failure and the one
/// worth preferring.
///
/// The Hebrew is a different story, and a much better one. Scored by edit
/// distance against the printed menu, of the **23 dish names**:
///
/// * **9 came back character-perfect** — `צלחת חריפים`, `ריזוטו, פטריות בלו
///   אויסטר`, `פילה דג ים, אורז אסור, ביסק סרטנים`.
/// * **17 scored 0.75 or better**, the band where a word is plainly
///   recognisable through one or two corrupted letters (`ברוסקטה סרדינים
///   כבושיט` for `...כבושים`).
/// * **The 4 that failed are the last four on the page**, nearest the foot of
///   the photograph where the frame falls off — 0.33 to 0.55. Not a property
///   of the dishes; a property of where they sat in the shot.
///
/// That asymmetry is the single most useful thing this capture says about
/// M16. A keto classifier reads ingredients, not prices, so the payload M16
/// needs is the payload that survives — which is the exact inverse of Keto
/// Lens, where the numbers are the whole point and the Hebrew is scaffolding.
///
/// ## Resolution is the limit here, not the settings
///
/// Measured rather than assumed: re-running the same photograph at 1600, 2400,
/// 3200, 4000 and 4500 px wide on the app's own kernel recovers at most 3 of
/// 19 distinct prices at any width. Upscaling cannot invent strokes a 480 px
/// source never recorded, so the app's own `targetWidth` is as good as any
/// larger number and the cap is not what is costing the digits.
///
/// ## `psm 4` is pinned for a label, and a menu is not a label
///
/// Also measured, on this image: `psm 6` returned 21% more text than `psm 4`
/// and kept **20** of the 23 dish rows whole against `psm 4`'s **12**,
/// recovering most of a third section `psm 4` dropped entirely. Neither reads
/// the prices. `psm 4` was chosen because `psm 6` flattened a bordered
/// nutrition table (`design/m6_platform_handoff.md`); nothing about that
/// finding was ever about menus. M16 should not assume the inherited setting
/// is right for it — see `design/m16_menu_scanner_research.md` §10.
///
/// ## What this still does not establish
///
/// **One menu is not a corpus.** Issue #373 asks for three, deliberately
/// differing — a multi-column layout, a laminated sheet with glare, and a
/// bilingual Hebrew/English card. This is one, and it is none of those three
/// on purpose: it is simply the menu somebody had. No accuracy figure is
/// claimed for menus in general, no menu has been read *through the app's own
/// camera*, and #373 stays open until the other two are photographed.
abstract final class PhotographedMenuOcrFixture {
  /// A real Israeli restaurant menu, photographed off the table by the user who asked for M16. Three price-bearing sections, dish names right, prices left, a designer's light serif on cream stock. The dish names largely survive the engine; the prices largely do not, and what they come back as is the finding — see the class comment.
  static const String vivie = """
(>

בייגלירושלחי, חמאה מלוחה וינגרט ‎an‏

8 שיח
צלחת חריפים 8 שית
ברוסקטה סרדינים כבושיט 2 ‎mew‏
‏אוייסטר, חומץ שאלוט. שמ ‎(ny) Frey‏ 4 ש"ח.

טרטר דג ים, איולי חמאה רוומה, בריוש 4 ‎nw‏
‏סביציה דג ים, חלפיניו כוסברה וליים 3 שיח
קרפצייו דג ים, שרי, עלי ריחן, פרחי שומר 8 שייח
טרטר בקר, רוטב קיסר, שאלוט על הגריל, בריוש ‎nw72‏
‏חסות, ‎TaN‏ לוז, בושה על ‎one‏ פרי העונה 3 ש"ת
עגבניות ‎on‏ עגרניות לב השור. גבינת סטרטצילה, שמן זית וקרוטונים ‎wot‏
‏פטריית מלך היער, ציר פורציני, קרם קשיו 8 ‎mw‏
‏תירס גמדי על הגריל, רליש שיפקה ובצלירוק, פרמזן. רומאה חומה ‎mw?‏
‏ניוקי צרוב, בר בלאן, פירורי בריוש ‎nw79‏
‏ריזוטו, פטריות בלו אויסטר 3 ‎nw‏

שיפוד דג ים, עגבניות מגי ושאלוט על הגריל, יוגורט באפלו- /
פילה דג ים, אורז אסור, ביסק סרטנים

מול מרינייר וציפס ₪
לברק שלם על ‎inns‏ שעועית תאילנדית ופירה, מרינייר
שניצל דג רוטב טרטר, פירה

ציזבוה חטבטרטה ‎‘voy‏""";
}
