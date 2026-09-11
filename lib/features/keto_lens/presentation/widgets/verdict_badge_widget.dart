import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/keto_lens/domain/models/verdict_badge.dart';
import 'package:flutter/material.dart';

/// The scan verdict as a coloured chip.
///
/// ## Why it takes a flag as well as a badge
///
/// `IngredientClassifier` does not flag a token it does not recognise —
/// "the verdict describes what was found, not what was understood" — so a
/// wheat-flour wafer whose ingredients happen to match no rule also earns
/// [VerdictBadge.cleanKeto]. A green "קטו נקי ✓" on that label asserts far
/// more than the pipeline knows, and it is the single failure this feature
/// must not have.
///
/// So [recognisedNothing] — `IngredientVerdict.recognisedNothing` — softens
/// the clean case to "nothing problematic was found", which is true.
/// `design/m6_preflight.md` §4.1.
///
/// ## Why colour is not the only signal
///
/// Each variant carries an icon as well as a colour. Roughly one man in
/// twelve cannot reliably separate the green from the red, and a verdict
/// badge is the one widget in the app where that distinction is the whole
/// message.
class VerdictBadgeWidget extends StatelessWidget {
  const VerdictBadgeWidget({
    required this.badge,
    this.recognisedNothing = false,
    super.key,
  });

  /// The verdict to render.
  /// The badge to show, or null when neither the ingredients nor the panel
  /// carried evidence — a fourth, neutral appearance rather than a guess
  /// (#306).
  final VerdictBadge? badge;

  /// Whether the classifier matched no rule at all, in either direction.
  ///
  /// Only meaningful for [VerdictBadge.cleanKeto]; ignored otherwise, since
  /// a flagged verdict recognised something by definition.
  final bool recognisedNothing;

  /// The chip's text.
  ///
  /// Exposed for the widget test and for `ScanResultSheet`'s semantics
  /// label, so neither has to re-derive the copy and drift from it.
  @visibleForTesting
  static String labelFor(
    VerdictBadge? badge, {
    bool recognisedNothing = false,
  }) {
    if (badge == null) {
      return 'לא ניתן לקבוע — בדקו את התווית';
    }
    if (badge == VerdictBadge.cleanKeto && recognisedNothing) {
      return 'לא נמצאו רכיבים בעייתיים';
    }
    return switch (badge) {
      VerdictBadge.cleanKeto => 'קטו נקי',
      VerdictBadge.cautionQuantityDependent => 'זהירות — תלוי כמות',
      VerdictBadge.nonKeto => 'לא קטו',
    };
  }

  /// The chip's colour.
  ///
  /// Drawn from [AppTheme] rather than the raw hex #86 lists — its own
  /// Definition of Done asks for named constants — and following M3's
  /// `PhaseBadgeWidget`, which takes the palette "so the badge tracks the
  /// palette every other widget uses".
  ///
  /// Public rather than `@visibleForTesting`: `ScanResultSheet` tints its
  /// flagged-ingredient heading with it, and a second hand-written mapping
  /// there is how the chip and the list come to disagree.
  static Color colourFor(VerdictBadge? badge) => switch (badge) {
    null => AppTheme.surface,
    VerdictBadge.cleanKeto => AppTheme.success,
    VerdictBadge.cautionQuantityDependent => AppTheme.caution,
    VerdictBadge.nonKeto => AppTheme.danger,
  };

  /// The colour of the text and icon sitting on [colourFor].
  ///
  /// The caution token is `#FFD60A`, a bright yellow: white on it is close
  /// to unreadable. Dark ink on the two light-ish fills and white on the
  /// red — and on the dark neutral surface — is what keeps all four legible.
  @visibleForTesting
  static Color inkFor(VerdictBadge? badge) => switch (badge) {
    // `surface` is the dark palette's card colour, so it takes light ink.
    null => Colors.white,
    VerdictBadge.cleanKeto ||
    VerdictBadge.cautionQuantityDependent => AppTheme.primary,
    VerdictBadge.nonKeto => Colors.white,
  };

  /// The chip's icon.
  ///
  /// Deliberately not a directional glyph, so nothing needs mirroring in
  /// the RTL layout.
  @visibleForTesting
  static IconData iconFor(VerdictBadge? badge) => switch (badge) {
    null => Icons.help_outline,
    VerdictBadge.cleanKeto => Icons.check_circle,
    VerdictBadge.cautionQuantityDependent => Icons.warning_amber_rounded,
    VerdictBadge.nonKeto => Icons.cancel,
  };

  @override
  Widget build(BuildContext context) {
    final ink = inkFor(badge);

    return Chip(
      key: const Key('verdict_badge'),
      avatar: Icon(iconFor(badge), color: ink, size: 20),
      label: Text(
        labelFor(badge, recognisedNothing: recognisedNothing),
        style: TextStyle(color: ink, fontWeight: FontWeight.bold),
      ),
      backgroundColor: colourFor(badge),
      // The fill is the signal; a border would compete with it. Same call
      // PhaseBadgeWidget made.
      side: BorderSide.none,
      // 44pt is the Apple HIG minimum touch target. The chip is not
      // tappable, but it sits beside controls that are, and a short chip
      // in that row reads as broken.
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
