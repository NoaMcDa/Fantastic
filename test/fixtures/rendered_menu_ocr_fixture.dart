/// Genuine Tesseract output for a **rendered** two-column Hebrew menu.
///
/// Its own file, not part of `real_ocr_fixture.dart`, for the reason
/// `ci_ocr_fixture.dart` is its own file: the provenance differs and saying
/// so is worth more than one import line. The engine output here is real -
/// captured at `-l heb+eng --psm 4 -c user_defined_dpi=300`
/// against the bundled models, on Tesseract 5.3.4 - but **the image is
/// rendered, not photographed**: the app's own Assistant font, flat, evenly
/// lit, no glare, no curl, no restaurant lighting. It answers the question
/// `design/m16_menu_scanner_research.md` §5 could not: what a
/// segmentation mode pinned for a bordered nutrition table (`psm 4`) does
/// when handed two columns instead of one.
///
/// **Generated, not written. Do not hand-edit.** Regenerate with
/// `python3 tool/capture_menu_ocr_fixture.py`.
///
/// ## What it found about columns
///
/// `psm 4` did **not** interleave the two columns. Every price stayed
/// paired with its own dish, on its own output line, in the right reading
/// order - confirmed with `tesseract ... tsv` word-box output, where each
/// price's bounding box shares its own dish's `line_num` and never a
/// neighbouring row's.
///
/// What it did instead is corrupt the price digits themselves, on every
/// row: `₪28` came back `₪588`, `₪32` came back `2`, `64 ש"ח`
/// came back `4 ש"ח`, `58 ש"ח` came back `8 ש"ח` - a leading digit lost in
/// three of the four, a wrong extra one gained in the fourth. That is not a
/// new defect: it is the already-documented "the Hebrew model cannot read
/// an isolated column of Latin digits" (`design/m6_platform_handoff.md`),
/// reappearing on a menu's much wider price-margin gap.
///
/// **One dish name was corrupted too, and it is the more interesting
/// finding.** `סלט ירוק עם רוטב שמן זית ולימון` came back with `שמן`
/// replaced by the Latin token `Pow`. That is the `heb+eng` trade-off
/// `CLAUDE.md` already documents - English sometimes wins a Hebrew word -
/// landing on a dish name rather than on a macro row. The other four dish
/// names and the one wrapped description came through unharmed.
///
/// **What this means for `MenuAnalysisPrompt`'s "columns may be
/// interleaved" instruction:** it is aimed at a failure mode this capture
/// did not produce. Of the two it did produce, a corrupted price never
/// reaches the parser's output at all - `MenuResponseParser` has no price
/// field. A corrupted *word inside a dish name* does reach it, and this
/// capture is the first evidence that the provenance rule survives one:
/// `nameOccursIn` needs only one qualifying word of the model's name to
/// occur in the source, and `סלט`, `ירוק`, `רוטב`, `זית` and
/// `ולימון` all still do. That is exactly the case #357 documented
/// itself as loose enough to survive and could not previously prove.
/// **This one capture does not show OCR as the bottleneck for a dish/price
/// row, and does not by itself justify filing the vision swap.** It does
/// not clear a side-by-side two-section layout (two independent lists
/// printed next to each other, not built here) - the shape "interleaved"
/// was actually written for - which stays unmeasured. See
/// `design/m16_menu_scanner_research.md` §5.
abstract final class RenderedMenuOcrFixture {
  /// A two-section grill menu (ראשונות / עיקריות), each dish printed with
  /// its price on the same line - the dish right-aligned, the price
  /// left-aligned - and one wrapped description line. Source: `GRILL_MENU`
  /// in this script; rendered by `render_labels.render_menu`.
  static const String grill = """
ראשונות

חומוס עם טחינה ולימון ₪588
מוגש עם פטרוזיליה קצוצה, פפריקה ולחמניה חמה לצד

סלט ירוק עם רוטב ‎Pow‏ זית ולימון 2
עיקריות

אנטריקוט על הגריל עם ירקות צלויים 4 ש"ח
שניצל עוף עם פירה ורוטב פטריות 8 ש"ח

שניצל עוף פריך מוגש עם פירה תפוחי אדמה חמאתי""";
}
