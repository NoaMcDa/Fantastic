import 'package:fantastic/core/constants/keto_constants.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Which band a keto ratio falls in.
enum KetoRatioBand {
  /// Under [KetoConstants.targetKetoRatioMin].
  below,

  /// At or above the minimum, under the ideal.
  approaching,

  /// At or above [KetoConstants.targetKetoRatioIdeal].
  met,
}

/// How a keto ratio is shown: one band, one colour, one icon.
///
/// **The single source for the ratio→appearance mapping.** It lived as a
/// `static` on `StreakRingPainter`, where `MacroSummaryCard` could not reach
/// it without importing an adaptation-feature painter — so the card used a
/// fixed accent instead, and the two widgets stacked one above the other
/// disagreed about the same number. At ratio 2.6 the ring was green and full
/// while the bar directly below it was gold; at 0.9 the ring was red and the
/// bar was still gold (#305).
///
/// The bar's colour carried no information at all. Fat, net carbs and protein
/// each get a distinct fixed hue so the three can be told apart from one
/// another — that is an identity, not a verdict, and those rows are
/// untouched. The ratio is the one row where the *value* has a good/marginal/
/// bad reading, and it inherited the wrong treatment.
abstract final class KetoRatioPalette {
  /// Which band [ratio] falls in.
  ///
  /// Boundaries are inclusive at the lower edge, matching the convention
  /// everywhere else in the app: hitting a target meets it.
  ///
  /// **`NaN` lands on [KetoRatioBand.below], and that is load-bearing rather
  /// than incidental.** Every comparison against `NaN` is false, so the chain
  /// falls through — but a `NaN` ratio silently reading as "target met" is
  /// precisely the failure `NumericInput.positiveFinite` exists to prevent
  /// elsewhere, and it is asserted rather than assumed.
  static KetoRatioBand bandFor(double ratio) {
    if (ratio >= KetoConstants.targetKetoRatioIdeal) {
      return KetoRatioBand.met;
    }
    if (ratio >= KetoConstants.targetKetoRatioMin) {
      return KetoRatioBand.approaching;
    }
    return KetoRatioBand.below;
  }

  /// The band's colour.
  static Color colourFor(double ratio) => switch (bandFor(ratio)) {
    KetoRatioBand.met => AppTheme.success,
    KetoRatioBand.approaching => AppTheme.caution,
    KetoRatioBand.below => AppTheme.danger,
  };

  /// A non-colour signal of the same band.
  ///
  /// Three distinct glyphs, not three variants of one: `design/m6_handoff.md`
  /// convention 8 — colour is never the only signal — and a user who cannot
  /// tell green from amber has nothing otherwise.
  static IconData iconFor(double ratio) => switch (bandFor(ratio)) {
    KetoRatioBand.met => Icons.check_circle_outline,
    KetoRatioBand.approaching => Icons.trending_up,
    KetoRatioBand.below => Icons.error_outline,
  };

  /// Hebrew label for the band.
  ///
  /// For a semantic label and for any future text rendering: colour is not a
  /// screen-reader signal, and neither is an icon without one.
  static String labelFor(double ratio) => switch (bandFor(ratio)) {
    KetoRatioBand.met => 'ביעד',
    KetoRatioBand.approaching => 'מתקרב ליעד',
    KetoRatioBand.below => 'מתחת ליעד',
  };
}
