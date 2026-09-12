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
  // #120, #396 and #397 add their strings here.
}
