/// What a label's printed macro figures are measured against.
///
/// An Israeli nutrition label declares its values **per 100 g** — occasionally
/// per 100 ml, sometimes per serving, and often in two columns showing both.
/// Until this existed the pipeline extracted the numbers and said nothing
/// about what they were *per*, so a user who scanned a 30 g protein bar and
/// tapped through logged the whole 100 g: the day's macros, the keto ratio,
/// the streak evaluation and the phase all computed from a figure more than
/// three times too large (#257).
///
/// [unknown] is not a failure state, it is the honest one. A two-column label
/// resolves to [unknown] rather than to a guess, because picking the wrong
/// column silently is the exact defect this enum exists to remove — and a
/// wrong number the user never sees is worse than no number at all.
enum ServingBasis {
  /// `ל-100 גרם` and its spellings. The common case.
  per100g,

  /// `ל-100 מ"ל`. Scales identically to [per100g]; kept distinct so the UI can
  /// say millilitres and not silently call a drink a solid.
  per100ml,

  /// `למנה` — the figures already describe one serving, so they are logged
  /// unscaled.
  perServing,

  /// No basis was found, or more than one was — a two-column label.
  ///
  /// The caller must not scale. The sheet keeps its existing copy asking the
  /// user to check the serving size themselves, which is what shipped in M6
  /// and is still the right answer when the label cannot be read confidently.
  unknown,
}

/// Whether figures on this basis describe 100 units and therefore scale.
///
/// A single place for the question so the parser, the sheet and the tests
/// cannot disagree about whether `per100ml` scales. It does — the unit differs,
/// the arithmetic does not.
extension ServingBasisScaling on ServingBasis {
  bool get isPerHundred =>
      this == ServingBasis.per100g || this == ServingBasis.per100ml;
}
