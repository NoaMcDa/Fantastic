import 'package:fantastic/features/onboarding/domain/models/activity_level.dart';

/// Hebrew copy for each [ActivityLevel].
///
/// Const strings in `core/` rather than literals inside the widget, following
/// [GoalCopy] and `PhaseCopy`: the text is reviewable in one place, a copy
/// change is not a widget change, and the profile tab reads back the same
/// words the user picked on onboarding screen 2.
abstract final class ActivityCopy {
  /// The section heading on onboarding screen 2.
  static const String question = 'כמה אתם פעילים?';

  /// The order the segments are shown in — the enum's own order, least
  /// active first, which is how every activity-factor table is written.
  static const List<ActivityLevel> order = ActivityLevel.values;

  /// What the selector starts on.
  ///
  /// The conservative tier, and the reasoning is
  /// `OnboardingService.sedentaryActivityMultiplier`'s, which this replaces:
  /// a target set too low leaves the user hungry and blaming keto, a target
  /// set too high stalls weight loss silently. Under-promising on activity is
  /// the safer error for a number the user can correct on this very screen.
  static const ActivityLevel defaultLevel = ActivityLevel.sedentary;

  static const Map<ActivityLevel, String> titles = {
    ActivityLevel.sedentary: 'יושבני',
    ActivityLevel.light: 'קל',
    ActivityLevel.moderate: 'בינוני',
    ActivityLevel.active: 'פעיל',
    ActivityLevel.veryActive: 'פעיל מאוד',
  };

  static const Map<ActivityLevel, String> subtitles = {
    ActivityLevel.sedentary: 'בעיקר ישיבה, כמעט בלי אימונים',
    ActivityLevel.light: 'אימון קל פעם עד שלוש בשבוע',
    ActivityLevel.moderate: 'אימון שלוש עד חמש פעמים בשבוע',
    ActivityLevel.active: 'אימון שש עד שבע פעמים בשבוע',
    ActivityLevel.veryActive: 'אימון יומי מאומץ או עבודה פיזית',
  };
}
