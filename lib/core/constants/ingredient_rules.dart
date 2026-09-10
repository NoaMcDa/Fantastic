/// Ingredient classification rule lists for the Keto Lens OCR pipeline.
///
/// All entries are lowercase — ingredient matching in the classifier is
/// case-insensitive, so these lists stay lowercase for consistency.
abstract final class IngredientRules {
  static const List<String> forbiddenSeedOils = [
    'canola',
    'soybean',
    'corn oil',
    'sunflower',
    'cottonseed',
    'safflower',
  ];

  static const List<String> insulinSpikingSweeteners = [
    'maltitol',
    'sorbitol',
    'dextrose',
    'maltodextrin',
    'hfcs',
    'high fructose corn syrup',
  ];

  static const List<String> cleanApprovedFats = [
    'olive oil',
    'avocado oil',
    'coconut oil',
    'butter',
    'ghee',
    'tallow',
    'lard',
  ];

  static const List<String> cleanSweeteners = [
    'monk fruit',
    'stevia',
    'allulose',
    'erythritol',
  ];
}
