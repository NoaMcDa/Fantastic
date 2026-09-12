import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';

/// Hebrew copy for the profile tab.
///
/// Const strings in `core/` rather than literals inside the widget, following
/// [GoalCopy] and `PhaseCopy`: the text is reviewable in one place and a copy
/// change is not a widget change. `GoalCopy`'s own doc comment names this
/// screen as the reason it lives here.
abstract final class ProfileCopy {
  static const String title = 'פרופיל';

  // Section headings.
  static const String biometricsSection = 'נתונים אישיים';
  static const String goalSection = 'מטרה';
  static const String targetsSection = 'יעדים יומיים';
  static const String notificationsSection = 'התראות';
  static const String aboutSection = 'אודות';

  // Rows.
  static const String sex = 'מין';
  static const String age = 'גיל';
  static const String weight = 'משקל';
  static const String height = 'גובה';
  static const String fat = 'שומן';
  static const String netCarbs = 'פחמימות נטו';
  static const String protein = 'חלבון';
  static const String ketoRatio = 'יחס קטו מומלץ';
  static const String ketoStartDate = 'תחילת הקטו';
  static const String appVersion = 'גרסה';

  /// The sexes as the onboarding flow words them.
  ///
  /// Same two strings `OnboardingScreen2`'s segmented button uses, so the
  /// profile reads back exactly what the user picked.
  static const Map<BiologicalSex, String> sexes = {
    BiologicalSex.male: 'זכר',
    BiologicalSex.female: 'נקבה',
  };

  /// Units. Separate from the numbers so a digit run can be rendered LTR on
  /// its own and the unit stays in the RTL flow beside it.
  static const String years = 'שנים';
  static const String kg = 'ק״ג';
  static const String cm = 'ס״מ';
  static const String grams = 'גרם';

  // States.
  static const String loadFailed = 'לא ניתן לטעון את הפרופיל';
  static const String notOnboardedTitle = 'עוד לא מילאתם פרופיל';
  static const String notOnboardedBody =
      'השלימו את תהליך ההרשמה כדי לקבל יעדים אישיים.';

  // The read-only boundary, stated on screen rather than only in a doc
  // comment: a user who wants to change a target should learn that they
  // cannot yet, rather than hunt for a control that is not there.
  static const String readOnlyNote =
      'היעדים נקבעו בהרשמה ועדיין לא ניתנים לעריכה כאן.';

  // Notifications.
  static const String notificationsOn = 'התראות מופעלות';
  static const String notificationsOnBody =
      'נשלח תזכורת יומית כדי לשמור על הרצף.';
  static const String notificationsOff = 'התראות כבויות';
  static const String notificationsOffBody =
      'הפעילו התראות כדי לקבל תזכורת יומית לפני שהרצף נשבר.';
  static const String enableNotifications = 'הפעל התראות';
  static const String notificationsUnsupported = 'תזכורות אינן נתמכות כאן';
  static const String notificationsUnsupportedBody =
      'הפלטפורמה הזו אינה תומכת בתזכורות מתוזמנות. שאר האפליקציה עובדת כרגיל.';

  /// Shown when a request returns false.
  ///
  /// **A refusal is not an error** — `OnboardingService` already treats it
  /// that way. iOS shows its prompt at most once per install and silently
  /// returns the stored answer afterwards, so a second tap cannot re-ask and
  /// the row must say where the setting actually lives rather than look
  /// broken.
  static const String notificationsRefused =
      'ההרשאה לא ניתנה. אפשר להפעיל אותה בהגדרות המכשיר.';
  // Estimation (#321). Everything a user needs to decide whether to turn on
  // the one feature in this app that sends anything anywhere.
  static const String estimationSection = 'הערכת ערכים תזונתיים';

  /// The disclosure, always visible and never behind an expander.
  ///
  /// Estimation sends dietary health information off a device that has until
  /// now sent nothing anywhere. What it says is therefore specific about
  /// three things — what leaves, when, and what never leaves — rather than a
  /// generic privacy sentence.
  static const String estimationDisclosure =
      'כשתשתמשו בהערכה, התיאור שתכתבו — ובמצב צילום, גם התמונה של המנה — '
      'ובממיר המתכונים — שורות המצרכים שלא זוהו, כשתבקשו הצעות — '
      'יישלחו לשירות OpenRouter ולמודל שהוא מפנה אליו. '
      'כשמנתחים תפריט מסעדה נשלח הטקסט שזוהה מהתפריט (מודבק או מצולם). '
      'תמונות התפריט עצמן לא נשלחות — הן נקראות במכשיר. '
      'זה קורה רק כשאתם מפעילים הערכה. '
      'רישום ידני של ארוחה לא שולח שום דבר, סריקת תווית לא שולחת שום דבר, '
      'וקריאת תמונת תפריט לא שולחת שום דבר — '
      'הסריקה וקריאת התפריט רצות כולן על המכשיר.';

  static const String estimationConsent = 'אני מאשר/ת את שליחת הנתונים';
  static const String estimationApiKey = 'מפתח API';
  static const String estimationSave = 'שמירה';
  static const String estimationRemoveKey = 'הסרת המפתח';

  // The state line names the missing half rather than saying "disabled".
  static const String estimationOn = 'פעיל';
  static const String estimationNoKey = 'לא פעיל — לא הוזן מפתח';
  static const String estimationNoConsent = 'לא פעיל — האישור לא ניתן';
  static const String estimationNoKeyOrConsent = 'לא פעיל — חסרים מפתח ואישור';

  static const String estimationKeySource = 'openrouter.ai/keys';
  static const String estimationKeyHint =
      'מפתח חינמי נוצר כאן, והמכסה החינמית היא כ־50 הערכות ביום:';

  static const String estimationLoadFailed = 'לא ניתן לטעון את הגדרות ההערכה.';
  static const String estimationSaveFailed =
      'השמירה נכשלה. הנתונים שהזנתם נשמרו על המסך — נסו שוב.';

  static const String notificationsCheckFailed =
      'לא ניתן לבדוק את מצב ההתראות.';
}
