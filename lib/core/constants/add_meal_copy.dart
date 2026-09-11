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

  /// What a mode that has no flow behind it yet says.
  ///
  /// A shipped placeholder that names itself, not a `TODO` comment: a mode
  /// that does nothing when tapped reads as a bug, and
  /// `issue_conventions.md` forbids the comment anyway.
  static const String comingSoon = 'המצב הזה בדרך ויתווסף בקרוב.';

  static const String close = 'סגירה';
}
