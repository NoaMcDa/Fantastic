/// Keto substitution and staple rule tables for the recipe converter.
///
/// `CLAUDE.md` §"Keto Business Logic" names `IngredientRules` as the single
/// source of truth for forbidden oils and insulin-spiking sweeteners; this
/// file is the same kind of thing for the recipe converter, and lives beside
/// it for the same reason: an engine with no table is untestable, and a
/// table is data, not code, so it belongs in `lib/core/constants/` rather
/// than in `lib/features/recipe/domain/`.
///
/// ## Every alias and staple is stored final-form folded
///
/// `SubstitutionEngine.key` folds sofit letters (ך→כ, ם→מ, ן→נ, ף→פ, ץ→צ) on
/// both the input it is matching and the tables below, so a word that is
/// naturally spelled with a final letter — `לחם`, `שמן`, `לימון` — is written
/// here with the **regular** form of that letter instead: `לחמ`, `שמנ`,
/// `לימונ`. That looks wrong to a Hebrew reader. It is deliberate: these
/// strings are match keys, never displayed, and `test/core/constants/
/// substitution_rules_test.dart` asserts every one of them already equals
/// `SubstitutionEngine.key` of itself. `replacement` and `reason` are shown
/// to the user and are ordinary, correctly spelled Hebrew.
///
/// Folding is **not** in `HebrewTextNormaliser.normalise` — see that file's
/// own doc comment and `design/m10_recipe_converter_research.md` §1.5.
/// `IngredientClassifierImpl` matches `IngredientRules` by `contains` on the
/// unfolded normalised input, and `מלטודקסטרין` ends in a final nun; folding
/// there would silently stop that rule firing on every label that prints it.
typedef SubstitutionRow = ({
  List<String> aliases,
  String replacement,
  double ratio,
  String reason,
});

abstract final class SubstitutionRules {
  /// Every seed row is unreviewed — `design/m10_recipe_converter_research.md`
  /// §10. Two notes from the first draft:
  ///
  /// * Spelt flour substitutes to `קמח שקדים` at 1.0, the same as every other
  ///   wheat flour, rather than coconut flour at a quarter — coconut flour
  ///   needs added egg and liquid that one reason line cannot say.
  /// * Row 8's replacement is `סירופ אריתריטול`, not `סירופ נזיר` (monk-fruit
  ///   syrup): several commercial monk-fruit syrups are maltitol blends, and
  ///   the consistency test cannot see inside a product name.
  static const List<SubstitutionRow> substitutions = [
    (
      aliases: ['קמח', 'קמח לבנ', 'קמח חיטה', 'flour', 'wheat flour'],
      replacement: 'קמח שקדים',
      ratio: 1.0,
      reason: 'עתיר פחמימות',
    ),
    (
      aliases: ['קמח כוסמינ', 'קמח מלא', 'spelt flour', 'whole wheat flour'],
      replacement: 'קמח שקדים',
      ratio: 1.0,
      reason: 'עתיר פחמימות',
    ),
    (
      aliases: ['קמח תירס', 'קורנפלור', 'cornflour', 'cornstarch'],
      replacement: 'קסנטן גאם',
      ratio: 0.125,
      reason: 'עמילן טהור; מסמיך חזק בהרבה',
    ),
    (
      aliases: ['סולת', 'semolina'],
      replacement: 'קמח שקדים גס',
      ratio: 1.0,
      reason: 'עתיר פחמימות',
    ),
    (
      aliases: ['פירורי לחמ', 'breadcrumbs'],
      replacement: 'קמח שקדים',
      ratio: 1.0,
      reason: 'עתיר פחמימות',
    ),
    (
      aliases: ['סוכר', 'סוכר לבנ', 'סוכר חומ', 'sugar', 'brown sugar'],
      replacement: 'אריתריטול',
      ratio: 1.0,
      reason: 'מעלה אינסולין',
    ),
    (
      aliases: ['אבקת סוכר', 'powdered sugar', 'icing sugar'],
      replacement: 'אריתריטול טחון',
      ratio: 1.0,
      reason: 'מעלה אינסולין',
    ),
    (
      aliases: [
        'דבש',
        'סילאנ',
        'מייפל',
        'סירופ מייפל',
        'honey',
        'maple syrup',
        'date syrup',
      ],
      replacement: 'סירופ אריתריטול',
      ratio: 1.0,
      reason: 'סוכר נוזלי',
    ),
    (
      aliases: ['תפוח אדמה', 'תפוחי אדמה', 'potato', 'potatoes'],
      replacement: 'קולורבי',
      ratio: 1.0,
      reason: 'עתיר עמילן',
    ),
    (
      aliases: ['בטטה', 'sweet potato'],
      replacement: 'דלעת',
      ratio: 1.0,
      reason: 'עתיר עמילן',
    ),
    (
      aliases: ['אורז', 'rice'],
      replacement: 'אורז כרובית',
      ratio: 1.0,
      reason: 'עתיר פחמימות',
    ),
    (
      aliases: ['פסטה', 'ספגטי', 'אטריות', 'pasta', 'spaghetti', 'noodles'],
      replacement: 'נודלס קישוא',
      ratio: 1.0,
      reason: 'עתיר פחמימות',
    ),
    (
      aliases: ['חלב', 'milk'],
      replacement: 'שמנת מתוקה מדוללת במים',
      ratio: 1.0,
      reason: 'לקטוז',
    ),
    (
      aliases: ['מרגרינה', 'margarine'],
      replacement: 'חמאה',
      ratio: 1.0,
      reason: 'שומן מעובד',
    ),
    (
      aliases: [
        'שמנ קנולה',
        'שמנ סויה',
        'שמנ תירס',
        'שמנ חמניות',
        'שמנ צמחי',
        'canola oil',
        'soybean oil',
        'corn oil',
        'sunflower oil',
        'vegetable oil',
      ],
      replacement: 'שמן זית',
      ratio: 1.0,
      reason: 'שמן זרעים מעובד',
    ),
    (
      aliases: ['לחמ', 'לחמניה', 'לחמניות', 'פיתה', 'bread', 'pita'],
      replacement: 'לחם שקדים',
      ratio: 1.0,
      reason: 'עתיר פחמימות',
    ),
  ];

  /// What [SubstitutionEngine] reports as `AlreadyKeto`. Onion and tomato are
  /// in deliberately: a converter that flags בצל on every recipe is a
  /// converter nobody trusts (`design/m10_recipe_converter_research.md`
  /// §11.2).
  static const List<String> ketoStaples = [
    // Eggs, dairy and fats.
    'ביצה',
    'ביצימ',
    'חמאה',
    'שמנת',
    'שמנת מתוקה',
    'שמנת חמוצה',
    'גבינה',
    'גבינה צהובה',
    'גבינת שמנת',
    'גבינה לבנה',
    "קוטג'",
    'פרמזנ',
    'מוצרלה',
    'פטה',
    'בולגרית',
    'לאבנה',
    'שמנ זית',
    'שמנ קוקוס',
    'שמנ אבוקדו',
    'גהי',
    'טחינה גולמית',
    'egg',
    'eggs',
    'butter',
    'cream',
    'sour cream',
    'cheese',
    'yellow cheese',
    'cream cheese',
    'cottage cheese',
    'parmesan',
    'mozzarella',
    'feta',
    'olive oil',
    'coconut oil',
    'avocado oil',
    'ghee',
    'tahini',
    // Protein.
    'עופ',
    'חזה עופ',
    'שוקיימ',
    'בקר',
    'טחונ',
    'כבש',
    'דג',
    'סלמונ',
    'טונה',
    'שרימפס',
    'הודו',
    'chicken',
    'chicken breast',
    'beef',
    'ground beef',
    'lamb',
    'fish',
    'salmon',
    'tuna',
    'shrimp',
    'turkey',
    // Keto flours and sweeteners, so an already-converted recipe reads fine.
    'קמח שקדימ',
    'קמח קוקוס',
    'פסיליומ',
    'קסנטנ גאמ',
    'אריתריטול',
    'סטיביה',
    'almond flour',
    'coconut flour',
    'psyllium',
    'xanthan gum',
    'erythritol',
    'stevia',
    // Vegetables.
    'כרובית',
    'קישוא',
    'קישואימ',
    'ברוקולי',
    'תרד',
    'חסה',
    'מלפפונ',
    'פטריות',
    'פלפל',
    'בצל ירוק',
    'שומ',
    'אבוקדו',
    'זיתימ',
    'עגבניה',
    'עגבניות',
    'בצל',
    'cauliflower',
    'zucchini',
    'broccoli',
    'spinach',
    'lettuce',
    'cucumber',
    'mushrooms',
    'pepper',
    'green onion',
    'garlic',
    'avocado',
    'olives',
    'tomato',
    'onion',
    // Seasoning.
    'מלח',
    'פלפל שחור',
    'כמונ',
    'פפריקה',
    'כורכומ',
    'אבקת אפייה',
    'סודה לשתייה',
    'וניל',
    'תמצית וניל',
    'לימונ',
    'מיצ לימונ',
    'חומצ',
    'מימ',
    'salt',
    'black pepper',
    'cumin',
    'paprika',
    'turmeric',
    'baking powder',
    'baking soda',
    'vanilla',
    'vanilla extract',
    'lemon',
    'lemon juice',
    'vinegar',
    'water',
  ];
}
