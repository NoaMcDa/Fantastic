import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';

/// What the three dish verdicts mean, and the caps the menu-scanner request
/// and response are bounded by.
///
/// **Read by both the prompt and the legend.** `MenuAnalysisPrompt` quotes
/// [definitions] and [hiddenCarbTraps] verbatim into the system prompt, and
/// `MenuVerdictLegend` (a later issue) renders the same [definitions] to the
/// user — one source, so the model and the person reading its answer are
/// told the same thing and the two cannot drift apart.
///
/// Every numeric cap below carries a doc comment saying why, per
/// `CLAUDE.md`'s rule that "why 25 g per 100 g?" must have an answer.
abstract final class MenuVerdictRules {
  /// One Hebrew sentence per [DishVerdict], precise enough to test a real
  /// dish against.
  ///
  /// The three states, from `design/m16_menu_scanner_research.md` §3: green
  /// is suitable as printed; yellow contains a non-keto element a single
  /// request removes or swaps; red is structurally carbohydrate-heavy and no
  /// request saves it.
  static const Map<DishVerdict, String> definitions = {
    DishVerdict.orderAsIs: """מתאים להזמנה כמו שהוא — המנה מבוססת על רכיבים קטוגניים בלבד, בדיוק כפי שהיא מוגשת.""",
    DishVerdict.modifiable: """מכיל רכיב לא-קטוגני אחד שאפשר להוריד או להחליף בבקשה אחת לפני ההזמנה.""",
    DishVerdict.nonKeto: """מבוסס מבנית על פחמימות (כמו בצק, אורז או תפוחי אדמה) ואי אפשר להציל אותו בבקשת שינוי.""",
  };

  /// The hidden sugars and starches a menu does not print — named explicitly
  /// so the model looks for them rather than only reading the dish name.
  ///
  /// Hebrew and English together, since a dish description can be printed in
  /// either. Order follows `design/m16_menu_scanner_research.md`'s own list:
  /// glazes, sweet sauces, breading, cornstarch thickeners, croutons.
  static const List<String> hiddenCarbTraps = [
    'זיגוג',
    'גלייז',
    'רוטב מתוק',
    'ציפוי פירורי לחם',
    'עמילן תירס',
    'קרוטונים',
    'glaze',
    'sweet sauce',
    'breading',
    'cornstarch',
    'croutons',
  ];

  /// The verdict name as it appears in the model's JSON reply.
  static String nameOf(DishVerdict v) => v.name;

  /// The reverse of [nameOf]. Matches by `.name`, **never by index** — a
  /// stored or transmitted ordinal would silently reinterpret every past
  /// response the day a fourth verdict is inserted mid-enum, the same trap
  /// `CLAUDE.md`'s Local Persistence section documents for sembast.
  ///
  /// Returns `null` for anything unrecognised, including a differently-cased
  /// match (`'MODIFIABLE'`) or a non-name string (`'1'`) — the caller treats
  /// `null` as "could not classify", never as a default verdict.
  static DishVerdict? verdictOf(String name) {
    for (final verdict in DishVerdict.values) {
      if (verdict.name == name) {
        return verdict;
      }
    }
    return null;
  }

  /// The longest menu text sent to the model, in UTF-16 code units.
  ///
  /// An eight-page menu's OCR output comfortably fits well under this; a
  /// pasted document longer than it is not a menu, and the cap bounds one
  /// request's cost rather than trusting whatever is on the clipboard.
  static const int maxMenuChars = 12000;

  /// The page cap the input screen enforces (`design/m16_menu_scanner_research.md`
  /// §7: "Page cap 8, enforced in Dart" — `image_picker`'s own `limit` is not
  /// honoured on every platform).
  static const int maxPages = 8;

  /// More dishes than this in one reply is not a menu that was read
  /// correctly — a real Israeli menu tops out far below it. The parser
  /// treats a reply over this count as `badResponse` rather than trusting a
  /// runaway list.
  static const int maxDishes = 150;

  /// The longest a dish `name` may be before the parser treats it as
  /// hallucinated rather than transcribed — long enough for the longest real
  /// menu line (a dish name plus a short parenthetical), short enough to
  /// catch a run-on paragraph standing in for a name.
  static const int maxDishNameChars = 120;

  /// The longest `why` the parser accepts before truncating — one or two
  /// sentences naming the carb trap or the keto-friendly macros, never a
  /// paragraph.
  static const int maxWhyChars = 300;

  /// The longest `modification` the parser accepts before truncating — one
  /// sentence a person can say to a waiter, the same budget as [maxWhyChars]
  /// because both are single-sentence fields.
  static const int maxModificationChars = 300;

  /// The reply's token budget: roughly 150 dishes at about 40 tokens of JSON
  /// each — [maxDishes] at its cap, with room for `why` and `modification`.
  /// Below this a full-menu reply truncates mid-array, which is a
  /// `badResponse` the user cannot fix by retrying; a provider's own default
  /// is not trusted to be enough for a real menu.
  static const int maxOutputTokens = 6000;

  /// The shortest dish-name word the provenance check accepts as evidence
  /// the dish came from the menu, digits excluded.
  ///
  /// `design/m16_menu_scanner_research.md` §6.6: loose enough to survive one
  /// OCR-corrupted letter in a three-word name, strict enough that a
  /// one- or two-letter fragment (a stray preposition, a corrupted number)
  /// cannot itself count as proof.
  static const int provenanceMinWordChars = 3;

  /// The share of letter characters on an extracted PDF page that must be
  /// Hebrew for its text layer to be trusted.
  ///
  /// `PdfrxPageExtractor`'s legibility guard, and the reason this issue
  /// exists: Israeli menu PDFs are frequently produced by design tools that
  /// embed subset fonts with no usable `ToUnicode` map, and extraction from
  /// those yields mojibake — plausible-looking character soup, not Hebrew.
  /// Mojibake is worse than no text at all: unchecked, it would reach the
  /// model, spend one of the 50 daily free requests, and come back as
  /// invented dishes the provenance rule silently discards. A genuinely
  /// bilingual menu page still clears this comfortably; a Latin-only menu is
  /// out of scope for a Hebrew keto app and degrades to the OCR path, which
  /// is the safe direction.
  static const double minHebrewLetterRatio = 0.5;

  /// Below this many letters on an extracted PDF page, the ratio above is
  /// not meaningful and the page is treated as having no usable text layer.
  ///
  /// A page with only a logo and a page number is not a menu page.
  static const int minExtractedLetters = 20;
}
