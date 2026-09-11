/// Real Israeli menu text, typed from real menus. Hand-written and says so.
///
/// Issue #352 was originally filed for two artefacts with very different
/// provenance — hand-typed transcripts and a verbatim OCR transcript of a
/// photographed menu. It was re-scoped: this file is the hand-typed half
/// only. The OCR half is #372 (rendered-menu capture) and #373 (a
/// photographed real menu, which needs a human with a phone) — never here,
/// and never invented. A hand-typed guess at what an engine would output is
/// exactly the failure `test/fixtures/real_ocr_fixture.dart`'s header exists
/// to prevent.
///
/// A menu transcript is different from that OCR fixture in kind: it is
/// ground truth about what a menu *says*, which a human can type by hand
/// honestly — the same relationship `hebrew_label_fixture.dart` has to
/// `real_ocr_fixture.dart` in that feature.
///
/// Between them the six variants below cover every dish example M16's
/// request names:
///
/// | Fixture | What it exercises |
/// |---|---|
/// | [grill] | section headers, prices in two notations, a burger with bun and fries (yellow), a schnitzel with purée (yellow), a ribeye (green); a dish name shared between two sections |
/// | [italian] | the four red examples: pizza, pasta, a breaded cutlet, risotto |
/// | [bilingualCafe] | Hebrew and English printed on one page — the `heb+eng` case |
/// | [fish] | grilled fish in butter (green) beside fish and chips (yellow) on the same page |
/// | [twoColumn] | a menu typed column by column — the shape a real two-column layout has, distinct from what OCR flattening does to it |
/// | [notAMenu] | noise with no dish in it — a receipt, so a test can prove the parser finds nothing |
///
/// Per `design/tests.md`, fixtures live here and are never inlined in a test.
abstract final class HebrewMenuFixture {
  /// An Israeli grill house.
  ///
  /// Section headers, two price notations (`₪` and `ש"ח`), a description
  /// that wraps onto a second line, and a green ribeye. The burger and the
  /// schnitzel are the request's yellow examples: a bun-and-fries plate and a
  /// starch-purée plate. "פירה" (purée) is deliberately named in both the
  /// starters and the mains section, so a test can exercise the parser's
  /// word-overlap provenance rule against a shared word that is not itself a
  /// dish name.
  static const String grill = """
מסעדת האש הכשרה
ראשונות
חומוס עם פטרוזיליה וזעתר - חומוס ביתי מוגש עם שמן זית, פטרוזיליה קצוצה
וזעתר טרי, לצד לחמניה חמה ₪32
פירה תפוחי אדמה עם חמאה מותכת ₪28
סלט ירוק עם רוטב שמן זית ולימון - תערובת עלים טריים, מלפפון ועגבנייה,
מוגש עם רוטב שמן זית כתית ולימון סחוט ₪38
עיקריות
אנטריקוט על הגריל - 300 גרם אנטריקוט בשל טרי, צלוי על גריל פחמים,
מוגש עם ירקות צלויים 64 ש"ח
המבורגר בית - 200 גרם בקר טחון, בלחמניה תוצרת בית, עם צ'יפס ורוטב
ביתי בצד 58 ש"ח
שניצל עוף עם פירה - שניצל עוף פריך מוגש עם פירה תפוחי אדמה ורוטב
פטריות 62 ש"ח
קינוחים
פירות העונה חתוכים ₪22
שתייה
לימונדה ביתית ₪18
""";

  /// An Italian trattoria — the request's red examples, together.
  ///
  /// Pizza, pasta, a breaded cutlet and risotto, each with a section header
  /// and a price, plus a wrapped description on the pizza line.
  static const String italian = """
טרטוריה איטלקית
פיצות
פיצה מרגריטה - רוטב עגבניות, מוצרלה טרייה ובזיליקום, אפויה בתנור
אבנים ₪56
פסטות
פסטה ברוטב עגבניות ובזיליקום - פנה מוגשת ברוטב עגבניות טרי, בזיליקום
ופרמזן ₪52
עיקריות
שניצל וינאי בציפוי פירורי לחם עם לימון ₪54
ריזוטו פטריות עם פרמזן ויין לבן ₪58
קינוחים
טירמיסו ביתי ₪32
""";

  /// A bilingual café menu — Hebrew and English on one page.
  ///
  /// `heb+eng` exists for exactly this layout. Includes a green salad and a
  /// yellow sweet-dressing salad, each printed in both languages.
  static const String bilingualCafe = """
קפה הפינה / The Corner Café
סלטים / Salads
סלט קינואה עם רוטב שמן זית - Quinoa Salad with Olive Oil Dressing
עלים ירוקים, קינואה, אבוקדו ורוטב שמן זית ולימון ₪46
Green leaves, quinoa, avocado and an olive oil-lemon dressing
סלט עוף עם רוטב דבש-חרדל - Chicken Salad with Honey-Mustard Dressing
עוף צלוי, עלים ירוקים ורוטב דבש-חרדל מתוק ₪52
Grilled chicken, green leaves and a sweet honey-mustard dressing
עיקריות / Mains
סלמון על הגריל בחמאה - Grilled Salmon in Butter
פילה סלמון צלוי בחמאה ועשבי תיבול, מוגש עם ירקות אדים ₪72
Salmon fillet grilled in butter and herbs, served with steamed vegetables
שתייה / Drinks
קפה שחור / Black Coffee ₪12
""";

  /// A fish restaurant — the green and yellow fish examples side by side.
  static const String fish = """
מסעדת הדייגים
עיקריות
דג לברק על הגריל בחמאה - דג לברק טרי צלוי על הגריל במחבת חמאה
ועשבי תיבול, מוגש עם ירקות מאודים ₪78
פיש אנד צ'יפס - פילה דג בציפוי פריך מטוגן עמוק, מוגש עם צ'יפס
ורוטב טרטר 68 ש"ח
דג עם פירה - פילה דג צלוי מוגש עם פירה תפוחי אדמה חמאתי 74 ש"ח
תוספות
צ'יפס בית ₪22
""";

  /// A two-column menu typed column by column.
  ///
  /// This is the shape a real two-column layout has on the page — not what
  /// OCR returns for it. `RealMenuOcrFixture` (#372) is where the flattened,
  /// possibly-interleaved OCR shape belongs; this file never guesses at it.
  static const String twoColumn = """
ראשונות                          עיקריות
סלט ירוק עם שמן זית ₪34           אנטריקוט צלוי ₪66
מרק ירקות ₪26                     סלמון בחמאה ₪72
                                  פסטה ברוטב שמנת ₪54
קינוחים                          שתייה
עוגת שוקולד ₪28                   מים מינרלים ₪14
""";

  /// Noise: a receipt, not a menu. The parser must find no dishes in it.
  static const String notAMenu = """
חשבונית מס / קבלה
עסק: מרכול השכונה בע"מ
ח.פ. 512345678
תאריך: 03/09/2026 שעה: 18:42
קופאי: 07
--------------------------------
סה"כ פריטים: 4
סכום ביניים: ₪84.50
מע"מ (17%): ₪14.37
סה"כ לתשלום: ₪98.87
אמצעי תשלום: אשראי
תודה ולהתראות
""";

  /// All six named transcripts, in declaration order.
  static const List<String> all = [
    grill,
    italian,
    bilingualCafe,
    fish,
    twoColumn,
    notAMenu,
  ];
}
