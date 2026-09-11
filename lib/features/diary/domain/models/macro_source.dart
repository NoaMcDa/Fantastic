/// Where a meal's macros came from.
///
/// A meal the user typed and a meal a model guessed are not the same kind of
/// datum, and the diary has to be able to tell them apart a week later —
/// `MealLoggingService` feeds every meal into the day's totals and hands the
/// day to `AdaptationPhaseService`, so a wrong estimate reaches the adaptation
/// phase state machine and can break a streak or falsely preserve one.
///
/// Stored by `.name`. Nothing here depends on declaration order, and nothing
/// may start to — a stored ordinal silently reinterprets every existing record
/// the day a value is inserted mid-enum.
enum MacroSource {
  /// Typed into `AddMealBottomSheet` by hand.
  manual,

  /// Read off a packaged product's nutrition panel by the Keto Lens OCR
  /// pipeline. Printed figures, not an estimate.
  scannedLabel,

  /// Estimated from a Hebrew description of the meal.
  estimatedFromText,

  /// Estimated from a photograph of the meal.
  estimatedFromPhoto;

  /// Whether these macros were estimated rather than measured or typed.
  ///
  /// The single place that question is asked, so the diary does not re-derive
  /// it and the two cannot drift.
  ///
  /// **A value is not fixed for the life of a meal.**
  /// `AddMealBottomSheet.sourceAfterEdit` is the one place it changes: an
  /// edit that alters a macro re-sources the meal to [manual], because once a
  /// human has corrected a number, a badge still calling it a guess is false
  /// — and a badge that lies trains people to ignore it. An edit that changes
  /// only the name leaves the source alone.
  bool get isEstimate =>
      this == MacroSource.estimatedFromText ||
      this == MacroSource.estimatedFromPhoto;
}
