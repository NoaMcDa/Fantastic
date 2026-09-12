/// Hebrew copy for the dashboard controls that are not macro labels.
///
/// The four progress-bar labels stay inline in `MacroSummaryCard`, where they
/// name a macro and nothing else reads them. These three are different: the
/// training-day chip is a control with a failure message, and a copy change
/// to a control the user acts on should be reviewable without opening a
/// widget.
abstract final class DashboardCopy {
  /// The chip that marks today as a day the user trained on.
  static const String trainingDay = 'אימון היום';

  /// What the chip means, for a screen reader and for anyone wondering why
  /// their fat target moved.
  static const String trainingDayHint = 'יעד השומן להיום עולה בהתאם';

  static const String trainingDaySaveFailed = 'לא ניתן לעדכן את סימון האימון';
}
