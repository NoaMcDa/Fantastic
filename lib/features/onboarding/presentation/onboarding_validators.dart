/// Form validation for the onboarding numeric fields.
///
/// Static and pure, so the rules are testable without pumping a widget and
/// so screens 2 and 4 cannot drift apart on what "a number" means.
///
/// **`double.tryParse` is not validation.** It accepts `Infinity` and `NaN`,
/// and neither is null — so a `tryParse(...) ?? fallback` never fires for
/// either, and neither is `< 0`. Both then reach the macro totals and poison
/// every figure derived from them. `m2_handoff.md` recorded this for the
/// meal form; #72's `_onConfirm` repeats it.
abstract final class OnboardingValidators {
  /// The youngest and oldest the flow accepts, per #70.
  ///
  /// Mifflin-St Jeor is not validated for young children, and this is not a
  /// paediatric tool.
  static const int minAge = 10;
  static const int maxAge = 120;

  /// Bounds wide enough to hold any real person and narrow enough to catch a
  /// misplaced decimal point, or a value typed in the wrong unit — 175 pounds
  /// entered as kilograms, say.
  static const double minWeightKg = 20;
  static const double maxWeightKg = 400;
  static const double minHeightCm = 80;
  static const double maxHeightCm = 250;

  static String? age(String? value) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null) {
      return 'יש להזין גיל';
    }
    if (parsed < minAge || parsed > maxAge) {
      return 'גיל חייב להיות בין $minAge ל-$maxAge';
    }
    return null;
  }

  static String? weightKg(String? value) => _inRange(
    value,
    min: minWeightKg,
    max: maxWeightKg,
    missing: 'יש להזין משקל',
    outOfRange:
        'משקל חייב להיות בין ${minWeightKg.toStringAsFixed(0)} '
        'ל-${maxWeightKg.toStringAsFixed(0)} ק״ג',
  );

  static String? heightCm(String? value) => _inRange(
    value,
    min: minHeightCm,
    max: maxHeightCm,
    missing: 'יש להזין גובה',
    outOfRange:
        'גובה חייב להיות בין ${minHeightCm.toStringAsFixed(0)} '
        'ל-${maxHeightCm.toStringAsFixed(0)} ס״מ',
  );

  /// A macro target on screen 4: any finite number above zero.
  ///
  /// Deliberately unbounded above — a target is the user's own call, and the
  /// only thing that must not reach the dashboard is a value that breaks the
  /// arithmetic.
  static String? macroTargetG(String? value) =>
      positiveFinite(value) == null ? 'יש להזין מספר גדול מאפס' : null;

  /// [value] as a positive, finite double, or null if it is not one.
  ///
  /// The single parse every caller goes through, so the `Infinity`/`NaN`
  /// check cannot be forgotten at one call site.
  static double? positiveFinite(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed.isNaN || parsed.isInfinite || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  static String? _inRange(
    String? value, {
    required double min,
    required double max,
    required String missing,
    required String outOfRange,
  }) {
    final parsed = positiveFinite(value);
    if (parsed == null) {
      return missing;
    }
    if (parsed < min || parsed > max) {
      return outOfRange;
    }
    return null;
  }
}
