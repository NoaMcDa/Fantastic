/// A short Hebrew recipe for the recipe converter's e2e flow (#398).
///
/// Written against the **shipped** `SubstitutionRules` table
/// (`lib/core/constants/substitution_rules.dart`) and `IngredientRules`
/// (`lib/core/constants/ingredient_rules.dart`), not invented — every line
/// below was traced by hand through `SubstitutionEngine.classify` before
/// being written here, because a fixture that merely *looks* right produces
/// a flow that passes while asserting the wrong outcome variant
/// (`design/m10_recipe_converter_research.md` and this issue's correction
/// (3)).
///
/// Per `CLAUDE.md` §Testing, this is written with `"""` rather than `'''`:
/// Hebrew grams are abbreviated with a geresh, and a geresh-terminated line
/// would otherwise close the literal early.
abstract final class RecipeFixture {
  static const String title = 'עוגת שוקולד קלה';

  /// One line of each [IngredientOutcome] variant, plus a blank line —
  /// distinct ingredients throughout, so a row rendered under the wrong key
  /// is caught rather than hidden by two lines sharing an outcome.
  ///
  /// | Line | Outcome (index after blank-line filtering) | Why, against the shipped table |
  /// |---|---|---|
  /// | `2 כוסות קמח` | `Substituted`, ratio **1.0** (index 0) | `קמח` is an exact alias of `SubstitutionRules.substitutions` row 1 (`קמח` → `קמח שקדים`) |
  /// | `4 כפות קורנפלור` | `Substituted`, ratio **0.125** (index 1) | `קורנפלור` is an exact alias of row 3 (`קורנפלור` → `קסנטן גאם`); `4 * 0.125 = 0.5` is observably different from the raw `4` |
  /// | *(blank)* | — | filtered by `RecipeConverterScreen._convert` before it ever becomes a [ParsedIngredient] — never gets an index |
  /// | `3 ביצים` | `AlreadyKeto` (index 2) | `SubstitutionEngine.key` folds the final mem, giving `ביצימ` — an exact `SubstitutionRules.ketoStaples` entry |
  /// | `כפית מלטיטול` | `Flagged` (index 3) | no alias or staple matches, but `IngredientRules.insulinSpikingSweetenersHebrew` names `מלטיטול`, and the un-stripped form of the line still contains it verbatim |
  /// | `חצי כוס פירורי עוגיות` | `Unrecognised` (index 4) | matches no substitution alias, no staple, and no `IngredientRules` entry — the model path's only target line |
  static const String cake = """
2 כוסות קמח
4 כפות קורנפלור

3 ביצים
כפית מלטיטול
חצי כוס פירורי עוגיות
""";
}
