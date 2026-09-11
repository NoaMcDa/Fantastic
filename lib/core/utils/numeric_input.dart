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

/// The one place a `double` becomes gram text on screen.
///
/// The inverse of [NumericInput], and it exists for the same reason: the app
/// had **three** copies of this, two of which were wrong in the same way
/// (#304). `_MacroStrip._format` in the scan sheet rounded to one decimal and
/// showed `0.2`; `_grams` in the add-meal sheet and `_formatGrams` beside it
/// both fell through to `'$value'` and wrote `0.17999999999999988` into the
/// field. So the sheet displayed one number and prefilled another, and **the
/// number the user saw when they pressed save was not the number that got
/// saved.**
///
/// Add a fourth caller by calling this, never by copying it.
abstract final class GramsText {
  /// [value] as a gram figure: rounded to one decimal, with no pointless
  /// trailing `.0`, and never raw floating-point noise.
  ///
  /// Empty for null — a macro the label did not give must stay absent so the
  /// form's validator asks for it, rather than defaulting to zero. A
  /// zero-macro meal saves without complaint and is invisible in the day's
  /// totals.
  ///
  /// One decimal because that is what an Israeli nutrition label prints and
  /// what the scan sheet already displayed. Rounding *before* deciding whether
  /// the value is whole is what removes the noise: `0.17999999999999988` is
  /// not whole, but `0.2` is not whole either, so the decision has to be made
  /// on the rounded figure or the raw one leaks through.
  ///
  /// The old `value.abs() < 1e9` and `< 1000` guards are gone with the
  /// interpolation that needed them: `'$value'` switches to exponent notation
  /// for large doubles, and `toStringAsFixed` never does.
  static String format(double? value) {
    if (value == null) {
      return '';
    }
    final rounded = double.parse(value.toStringAsFixed(1));
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1);
  }
}
