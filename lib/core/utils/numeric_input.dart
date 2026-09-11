/// The one place a user-typed number becomes a `double`.
///
/// **`double.tryParse` is not validation.** It accepts `Infinity` and `NaN`,
/// and neither is null — so a `tryParse(...) ?? fallback` never fires for
/// either, and both then propagate silently into arithmetic that produces a
/// `NaN` keto ratio or an infinite macro total.
///
/// This lived on `OnboardingValidators` while onboarding was the only screen
/// taking a number. #257 added a second — the scan sheet's "how much did you
/// eat?" field — and duplicating the guard is precisely the drift that
/// comment warned against, so it moved here. `OnboardingValidators.positiveFinite`
/// now delegates to it and keeps its own name for its own callers.
abstract final class NumericInput {
  /// [value] as a positive, finite double, or null if it is not one.
  static double? positiveFinite(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed <= 0) {
      return null;
    }
    return parsed;
  }
}
