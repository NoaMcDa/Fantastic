/// Where an [IngredientOutcome] answer came from. Stored by `.name`.
enum OutcomeSource {
  /// The constant tables in `lib/core/constants/substitution_rules.dart`.
  rule,

  /// A model's answer (#396). Rendered with a visible marker, because a
  /// clean badge or a swap from a model is not evidence — `MacroSource`'s
  /// reasoning, applied here.
  suggested,
}
