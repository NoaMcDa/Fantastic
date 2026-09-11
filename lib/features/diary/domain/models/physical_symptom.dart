/// The somatic keto-induction symptoms the diary records for a day.
///
/// **Deliberately excludes fatigue, brain fog, mood change and appetite
/// change**, which the scoping review ranks among the most common
/// keto-induction symptoms but which `SymptomScale` already covers as
/// `energy`, `clarity`, `mood` and `hunger`. Listing them here too would
/// double-count them and stop the scales being independent.
///
/// Declaration order is adult occurrence rate, descending — the chip grid
/// renders in this order, so the most likely symptom is where the eye lands
/// first. It is not alphabetical and should not be "tidied" into alphabetical.
///
/// Rates are from a 2025 scoping review of keto-induction symptoms
/// (https://pmc.ncbi.nlm.nih.gov/articles/PMC11978633/).
///
/// Persisted by [Enum.name] — `design/web_support.md` §4: reordering is safe,
/// **renaming a value orphans stored records**. Treat these names as a storage
/// contract.
///
/// Pure domain: no Flutter, no persistence package. The Hebrew label and icon
/// live in `presentation/physical_symptom_copy.dart`, for the reason
/// `symptom_scale.dart` records — an `IconData` cannot follow a value here.
enum PhysicalSymptom {
  /// 38% of adults. The most reported single symptom.
  halitosis,

  /// 1–68% of adults. Driven by reduced fibre intake, not by ketosis itself.
  constipation,

  /// 3–37% of adults. Magnesium and potassium depletion.
  muscleCramps,

  /// 8–25% of adults. Hypovolemia following sodium loss.
  headache,

  /// 2–23% of adults. Fat maldigestion during adaptation.
  diarrhea,

  /// 15–21% of adults. Orthostatic, from the same hypovolemia as headache.
  dizziness,

  /// 8–16% of adults. Delayed gastric emptying under high fat intake.
  nausea,

  /// Commonly reported during induction; the review does not quantify it
  /// separately. Included because it is actionable and distinct from the
  /// `energy` scale — a user can sleep badly and still report good energy.
  insomnia,
}
