/// The Hebrew the add-a-meal chooser and its two new modes are worded in.
///
/// In `lib/core/constants/` with the other copy files rather than inline in a
/// widget, so a string is changed in one reviewable place and the same words
/// cannot end up spelled two ways on two screens.
abstract final class AddMealCopy {
  /// The chooser's own heading.
  static const String chooserTitle = 'איך להוסיף ארוחה?';

  static const String manualTitle = 'הזנה ידנית';
  static const String manualSubtitle = 'הזינו שומן, פחמימות וחלבון';

  static const String descriptionTitle = 'תיאור הארוחה';
  static const String descriptionSubtitle = 'כתבו מה אכלתם ונחשב עבורכם';

  static const String photoTitle = 'צילום';
  static const String photoSubtitle = 'צלמו את המנה או את התווית';

  // ---------------------------------------------------------------------
  // Description mode
  // ---------------------------------------------------------------------

  /// The shape of description that works, shown as the field's hint.
  ///
  /// A worked example rather than an instruction: a weight and a household
  /// measure in one line is the thing a user has to see to write, and
  /// "describe your meal" does not teach it.
  static const String descriptionHint =
      'לדוגמה: 200 גרם חזה עוף, 2 ביצים, כף שמן זית';

  static const String descriptionFieldLabel = 'מה אכלתם?';
  static const String estimate = 'חשבו עבורי';
  static const String estimating = 'מחשבים...';

  /// The heading over the itemised review.
  static const String reviewTitle = 'מה זוהה';

  /// Marks a token the estimator could not identify.
  ///
  /// Shown in the list beside everything else, never hidden behind a
  /// "show more": a silently dropped `לחם` turns a 40 g-carb meal into a 2 g
  /// one and the day still reads compliant.
  static const String unidentifiedMarker = 'לא זוהה';

  static const String unidentifiedWarning =
      'חלק מהמנות לא זוהו וערכיהן אינם נכללים בסכום.';

  static const String total = 'סה"כ';
  static const String removeItem = 'הסרה';

  /// The confirm control. Says *review*, because the next screen is the form.
  static const String reviewAndSave = 'המשך לעריכה';

  /// Offered on every failure, so nothing the user typed is ever a dead end.
  static const String enterManually = 'הזנה ידנית במקום';
  static const String retry = 'נסו שוב';
  static const String openProfile = 'פתחו את הפרופיל';

  /// A headline per failure reason. One generic "failed" would leave a user
  /// with no key and a user with no signal reading the same useless sentence.
  static const String failedNotConfigured = 'הערכה אוטומטית לא מופעלת';
  static const String failedOffline = 'אין חיבור לאינטרנט';
  static const String failedRateLimited = 'חרגתם ממכסת ההערכות היומית';
  static const String failedUnauthorised = 'המפתח נדחה';
  static const String failedBadResponse = 'ההערכה נכשלה';
  static const String failedNothingIdentified = 'לא זוהתה אף מנה';
  static const String failedEmptyInput = 'אין מה להעריך';

  static const String rateLimitDetail = 'המכסה החינמית מתאפסת מדי יום.';
  static const String nothingIdentifiedDetail = 'נסחו מחדש את התיאור ונסו שוב.';

  // ---------------------------------------------------------------------
  // Photo mode
  // ---------------------------------------------------------------------

  static const String takePhoto = 'צילום מצלמה';
  static const String pickPhoto = 'בחירה מהגלריה';

  /// Explains the order the sheet works in, before anything is tapped.
  ///
  /// Worth saying out loud: a user who photographs a package expects the
  /// printed numbers, and a user who photographs a plate expects a guess.
  /// The sheet does both and decides for them, so it says so.
  static const String photoIntro =
      'אם בתמונה יש טבלת ערכים תזונתיים נקרא אותה ישירות. אחרת נעריך '
      'מהתמונה.';

  static const String photoDescriptionLabel = 'תיאור (לא חובה)';

  /// The photo says how much; the description says what.
  static const String photoDescriptionHint = 'לדוגמה: שקשוקה עם חלה';

  static const String reading = 'קוראים את התמונה...';

  /// Shown when the picker itself failed rather than the user backing out.
  static const String photoSourceFailed =
      'לא הצלחנו לפתוח את המצלמה או את הגלריה. בדקו את ההרשאות ונסו שוב.';

  /// The photo mode's own "try another photo", distinct from `retry`:
  /// re-running the same unreadable file would fail the same way.
  static const String anotherPhoto = 'נסו תמונה אחרת';
}
