/// A verbatim model reply the real `MenuResponseParser` accepts.
///
/// Built from the corpus in `HebrewMenuFixture.grill`: every dish name below
/// is a real line from that menu, because `MenuResponseParser`'s provenance
/// rule (`design/m16_menu_scanner_research.md` §6.6) demotes any name that
/// does not occur in the source text it was given. This is the shape
/// `RemoteMenuAnalyzer` hands to `MenuResponseParser.parse` — a single JSON
/// object, no markdown fence — exactly as `MenuAnalysisPrompt.system` asks
/// the model to answer.
///
/// A `"""` literal, not `'''`: two of the three dish descriptions below
/// carry a geresh (`צ'יפס`), which `CLAUDE.md`'s Testing section records as
/// unsafe inside a triple-single-quoted Dart string.
abstract final class MenuReplyFixture {
  /// The reply for [HebrewMenuFixture.grill] — one dish per [DishVerdict]
  /// plus one name the model could not place, so a test exercising the real
  /// parser over real JSON reaches every branch [MenuResultView] renders.
  static const String grill = """
{"dishes":[{"name":"אנטריקוט על הגריל","description":"300 גרם אנטריקוט בשל טרי, צלוי על גריל פחמים","verdict":"orderAsIs","why":"בשר ושומן בלבד, ללא רכיבי פחמימה"},{"name":"המבורגר בית","description":"200 גרם בקר טחון, בלחמניה תוצרת בית, עם צ'יפס","verdict":"modifiable","why":"הלחמניה והצ'יפס עמוסים בפחמימות עמילניות","modification":"בקשו בלי לחמניה, עם סלט ירוק במקום הצ'יפס"},{"name":"פירות העונה","description":"פירות העונה חתוכים","verdict":"nonKeto","why":"פרי הוא פחמימה טבעית שאי אפשר להסיר מהמנה"}],"unclassified":["לימונדה ביתית"]}
""";
}
