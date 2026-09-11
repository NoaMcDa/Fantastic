/// Ingredient classification rule lists for the Keto Lens OCR pipeline.
///
/// `CLAUDE.md` §"OCR & ML" is the specification these lists implement, and
/// this file is the single source of truth for them. `IngredientClassifier`
/// says so on the interface: implementations *"read them rather than
/// redeclaring them, so the forbidden and clean sets have one source of
/// truth."* #82's snippet declared its own copies; see
/// `design/m6_preflight.md` §1.4.
///
/// ## English and Hebrew are separate lists
///
/// The English lists are the spec, verbatim, and their lengths are asserted
/// in `test/core/constants/constants_test.dart`. The Hebrew lists are the
/// same rules as an Israeli label actually prints them. They are kept apart
/// rather than merged so that the spec stays legible next to `CLAUDE.md`,
/// and combined in the `all*` getters, which are what the classifier reads.
///
/// ## Why some Hebrew entries are the full phrase and some are the bare word
///
/// Matching is `contains`, so a bare word matches more. That is right for
/// canola — it is only ever an oil — and wrong for soy, corn and sunflower,
/// whose names also appear on perfectly keto ingredients:
///
/// * `סויה` alone would flag soy lecithin, which is an emulsifier, not a
///   seed oil, and is not disallowed.
/// * `חמניות` alone would flag sunflower *seeds*.
/// * `תירס` alone would flag corn fibre.
///
/// So those three carry the oil word and canola, cottonseed and safflower do
/// not. Each entry below says which it is and why.
///
/// All entries are lowercase; the classifier lowercases its input to match.
abstract final class IngredientRules {
  /// The six forbidden seed oils, in `CLAUDE.md`'s words.
  static const List<String> forbiddenSeedOils = [
    'canola',
    'soybean',
    'corn oil',
    'sunflower',
    'cottonseed',
    'safflower',
  ];

  /// The same six as an Israeli label prints them.
  ///
  /// `לפתית` is rapeseed, the plant canola is pressed from, and appears on
  /// its own on some imported labels.
  static const List<String> forbiddenSeedOilsHebrew = [
    'קנולה',
    'לפתית',
    'שמן סויה',
    'שמן פולי סויה',
    'שמן תירס',
    'שמן חמניות',
    'שמן חמנייה',
    'כותנה',
    'חריע',
  ];

  /// The insulin-spiking sweeteners, in `CLAUDE.md`'s words.
  static const List<String> insulinSpikingSweeteners = [
    'maltitol',
    'sorbitol',
    'dextrose',
    'maltodextrin',
    'hfcs',
    'high fructose corn syrup',
  ];

  /// The same sweeteners as an Israeli label prints them.
  ///
  /// `סירופ תירס` covers the longer `סירופ תירס עתיר פרוקטוז` by
  /// substring, so only the short form is listed.
  static const List<String> insulinSpikingSweetenersHebrew = [
    'מלטיטול',
    'סורביטול',
    'דקסטרוז',
    'מלטודקסטרין',
    'סירופ תירס',
  ];

  /// Oil declared only as "vegetable oil", with no plant named.
  ///
  /// **An extension to `CLAUDE.md`'s list, and the only one in this file.**
  /// It is on a large share of Israeli packaged food, and in practice it is
  /// a seed-oil blend — but it can also be palm or coconut, which are not
  /// forbidden. That is precisely the "quantity/identity dependent" case the
  /// middle badge exists for, so it is a caution rather than a refusal, and
  /// a clean fat named in the same token overrides it (see
  /// `IngredientClassifierImpl`).
  static const List<String> unspecifiedVegetableOils = [
    'vegetable oil',
    'שמן צמחי',
    'שמנים צמחיים',
  ];

  /// Plant names that make an otherwise-unspecified vegetable oil
  /// acceptable.
  ///
  /// Used **only** to disqualify the [unspecifiedVegetableOils] caution, not
  /// as a general clean match. An Israeli label almost always names the
  /// plant in brackets — `שמן צמחי (קנולה)`, `שמן צמחי (קוקוס)` — and the
  /// bracketed word is not the full `שמן קוקוס` the clean list holds.
  ///
  /// Scoped to that one branch on purpose: `קוקוס` on its own is *not* a
  /// clean ingredient. `סוכר קוקוס` is coconut sugar.
  static const List<String> cleanOilSources = [
    'קוקוס',
    'זית',
    'אבוקדו',
    'coconut',
    'olive',
    'avocado',
  ];

  /// The clean fats, in `CLAUDE.md`'s words.
  static const List<String> cleanApprovedFats = [
    'olive oil',
    'avocado oil',
    'coconut oil',
    'butter',
    'ghee',
    'tallow',
    'lard',
  ];

  /// The same clean fats in Hebrew.
  ///
  /// Tallow is `שומן בקר`, not `חלב` — the unpointed spelling of the
  /// classical word for tallow is identical to the word for milk.
  static const List<String> cleanApprovedFatsHebrew = [
    'שמן זית',
    'שמן אבוקדו',
    'שמן קוקוס',
    'חמאה',
    'גהי',
    'שומן בקר',
    'שומן חזיר',
  ];

  /// The clean sweeteners, in `CLAUDE.md`'s words.
  static const List<String> cleanSweeteners = [
    'monk fruit',
    'stevia',
    'allulose',
    'erythritol',
  ];

  /// The same clean sweeteners in Hebrew.
  static const List<String> cleanSweetenersHebrew = [
    'סטיביה',
    'אריתריטול',
    'אלולוז',
    'מונק פרוט',
    'פרי נזיר',
  ];

  /// Everything that earns `VerdictBadge.nonKeto`.
  static const List<String> allForbiddenSeedOils = [
    ...forbiddenSeedOils,
    ...forbiddenSeedOilsHebrew,
  ];

  /// Everything that earns `VerdictBadge.cautionQuantityDependent` outright.
  static const List<String> allInsulinSpikingSweeteners = [
    ...insulinSpikingSweeteners,
    ...insulinSpikingSweetenersHebrew,
  ];

  /// Everything positively recognised as keto-clean.
  static const List<String> allCleanIngredients = [
    ...cleanApprovedFats,
    ...cleanApprovedFatsHebrew,
    ...cleanSweeteners,
    ...cleanSweetenersHebrew,
  ];
}
