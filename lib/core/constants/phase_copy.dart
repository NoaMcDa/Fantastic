import 'package:fantastic/features/adaptation/domain/models/adaptation_phase.dart';

/// Hebrew guidance copy for each adaptation phase.
///
/// Const strings in `core/` rather than literals inside the widget, so the
/// text is reviewable in one place and a copy change is not a widget change.
/// The phase-to-copy mapping is the only thing here; the electrolyte numbers
/// live in `ElectrolyteConstants` and are read from there.
abstract final class PhaseCopy {
  /// The phase's name as the user sees it.
  static const Map<AdaptationPhase, String> names = {
    AdaptationPhase.induction: 'שלב ההסתגלות',
    AdaptationPhase.fatAdapted: 'מותאם לשומן',
    AdaptationPhase.deepKetosis: 'קטוזיס עמוק',
  };

  /// The day range each phase covers, as display copy.
  ///
  /// Display only — progression is driven by the streak count through
  /// `AdaptationPhaseService`, never by this string. The ranges match the
  /// thresholds that service uses (8 and 28); see `design/m3_preflight.md`
  /// §1.4 for why they are not the 8–28 / 29+ the issue text described.
  static const Map<AdaptationPhase, String> dayRanges = {
    AdaptationPhase.induction: 'ימים 1–7',
    AdaptationPhase.fatAdapted: 'ימים 8–27',
    AdaptationPhase.deepKetosis: 'יום 28 ואילך',
  };

  /// One line on what the phase is for.
  static const Map<AdaptationPhase, String> summaries = {
    AdaptationPhase.induction: 'ניהול שפעת קטו ובניית הרגל',
    AdaptationPhase.fatAdapted: 'מעבר לניצול שומן כמקור אנרגיה',
    AdaptationPhase.deepKetosis: 'אופטימיזציה ושמירה לטווח ארוך',
  };

  /// What to expect, and what to do about it.
  static const Map<AdaptationPhase, String> descriptions = {
    AdaptationPhase.induction:
        'השבוע הראשון הוא המאתגר ביותר. הגוף מרוקן את מאגרי הגליקוגן ומפריש '
        'נוזלים ומלחים במהירות, ומכאן העייפות, כאבי הראש והבחילה שמכונים '
        '"שפעת קטו". שתייה מרובה ותוספת מלח מקצרות את התקופה הזו מאוד.',
    AdaptationPhase.fatAdapted:
        'הגוף מתחיל לנצל שומן וקטונים כמקור האנרגיה העיקרי. האנרגיה '
        'מתייצבת, התיאבון יורד והחשקים נחלשים. ייתכן שהביצועים הגופניים '
        'עדיין מעט מופחתים — זה חולף.',
    AdaptationPhase.deepKetosis:
        'ההסתגלות הושלמה. האנרגיה יציבה לאורך היום, הריכוז חד והרעב צפוי. '
        'זה הזמן להרחיב את מגוון המזונות ולכוון לשמירה לטווח ארוך.',
  };
}
