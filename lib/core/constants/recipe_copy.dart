import 'package:fantastic/core/utils/numeric_input.dart';

/// The Hebrew the recipe converter tab is worded in.
///
/// In `lib/core/constants/` with the other copy files rather than inline in
/// a widget, so a string is changed in one reviewable place and the same
/// words cannot end up spelled two ways on two screens.
abstract final class RecipeCopy {
  static const String title = 'המרת מתכון';

  /// The tab label. Seven characters at six destinations — see
  /// `design/m10_recipe_converter_research.md` and `AppShell`.
  static const String tabLabel = 'מתכונים';

  static const String pasteHint = 'הדביקו כאן את רשימת המצרכים, שורה לכל מצרך';
  static const String convert = 'המירו לקטו';

  static const String alreadyKeto = 'מתאים לקטו';
  static const String flagged = 'הסירו מהמתכון — לא מתאים לקטו';
  static const String unrecognised = 'לא זוהה';

  /// Shown under a [Substituted] or [AlreadyKeto] row whose
  /// `OutcomeSource` is `suggested` — a model's answer (#396), not the rule
  /// table's.
  static const String suggestedMarker = 'הצעה אוטומטית — בדקו';

  static const String emptyResult = 'לא הודבק מתכון';

  // --- #120: the library and the save affordance ---

  static const String openLibrary = 'המתכונים השמורים שלי';
  static const String save = 'שמירת מתכון';
  static const String saved = 'המתכון נשמר';
  static const String saveFailed = 'שמירת המתכון נכשלה. נסו שוב.';
  static const String cancel = 'ביטול';
  static const String recipeTitleHint = 'שם המתכון';

  static const String libraryTitle = 'מתכונים שמורים';
  static const String emptyLibraryTitle = 'טרם נשמרו מתכונים';
  static const String emptyLibraryBody =
      'המירו מתכון וסמנו לשמירה כדי לראות אותו כאן.';
  static const String loadFailed = 'לא ניתן לטעון את המתכונים השמורים';
  static const String deleteFailed = 'מחיקת המתכון נכשלה. נסו שוב.';

  /// Shown by `SavedRecipeLoader` when a path id is missing, non-numeric, or
  /// resolves to no stored recipe. Never a crash on a bad deep link.
  static const String recipeNotFound = 'המתכון המבוקש לא נמצא';

  static String ingredientCount(int count) => '$count מצרכים';
  static String substitutedCount(int count) => '$count הוחלפו';

  // --- #396: the opt-in model pass over unrecognised lines ---

  static const String suggestButton = 'הצעות לשורות שלא זוהו';
  static const String suggesting = 'מבקשים הצעות...';

  /// Shown when the model was reached and answered, but nothing usable came
  /// back for any unrecognised line — a real, non-error outcome, not a
  /// failure banner.
  static const String noSuggestions = 'לא התקבלה הצעה עבור אף שורה';

  static const String openProfile = 'פתחו את הפרופיל';

  static const String suggestFailedNotConfigured = 'הצעות אוטומטיות לא מופעלות';
  static const String suggestFailedOffline = 'אין חיבור לאינטרנט';
  static const String suggestFailedRateLimited = 'חרגתם ממכסת ההצעות היומית';
  static const String suggestFailedBadResponse = 'קבלת ההצעות נכשלה';

  // --- #397: per-serving macro estimation and logging a serving ---

  /// Shown below the results before the recipe has been saved — an id is
  /// what `RecipeMacrosSection` writes its answer onto.
  static const String saveToSeeMacrosHint =
      'שמרו את המתכון כדי לחשב ערכים למנה';

  static const String servingsFieldLabel = 'כמות מנות';
  static const String estimateMacrosButton = 'ערכים למנה';

  /// Shown instead of [estimateMacrosButton] once a stored estimate already
  /// exists — a fresh request is a recalculation, not a first attempt.
  static const String recalculateMacrosButton = 'חשבו מחדש';

  static const String perServingLabel = 'למנה';
  static const String saveMacrosButton = 'שמרו על המתכון';
  static const String macrosSaved = 'ערכי המנה נשמרו';
  static const String macrosSaveFailed = 'שמירת ערכי המנה נכשלה. נסו שוב.';
  static const String logServingButton = 'הוסיפו מנה ליומן';

  /// `שומן 12 · פחמימות 3 · חלבון 9 למנה` — the library card's compact line,
  /// and the section's own per-serving row.
  static String perServingSummary(
    double fatG,
    double netCarbsG,
    double proteinG,
  ) =>
      'שומן ${GramsText.format(fatG)} · '
      'פחמימות ${GramsText.format(netCarbsG)} · '
      'חלבון ${GramsText.format(proteinG)} $perServingLabel';
}
