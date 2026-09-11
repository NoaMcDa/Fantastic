import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/core/theme/app_theme.dart';
import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:flutter/material.dart';

/// A dish's verdict as a coloured chip.
///
/// Not `VerdictBadgeWidget`: Keto Lens's amber reads "זהירות — תלוי כמות"
/// (quantity dependent), and a burger with a bun is not quantity dependent —
/// it is modifiable. This badge has its own three labels (`MenuCopy`) and
/// shares only the colour tokens and the accessibility rule with Keto Lens's
/// badge: colour is never the only signal. Roughly one man in twelve cannot
/// reliably separate the green from the red, and a verdict badge is the one
/// widget where that distinction is the whole message — so every variant
/// carries an icon as well as a fill colour.
class DishVerdictBadge extends StatelessWidget {
  const DishVerdictBadge({required this.verdict, super.key});

  /// The verdict to render.
  final DishVerdict verdict;

  /// The chip's text.
  ///
  /// Exposed for the widget test so it does not have to re-derive the copy
  /// and drift from it.
  @visibleForTesting
  static String labelFor(DishVerdict verdict) =>
      MenuCopy.verdictLabels[verdict]!;

  /// The chip's fill colour. `AppTheme.success` / `caution` / `danger` only —
  /// never a raw hex literal.
  static Color colourFor(DishVerdict verdict) => switch (verdict) {
    DishVerdict.orderAsIs => AppTheme.success,
    DishVerdict.modifiable => AppTheme.caution,
    DishVerdict.nonKeto => AppTheme.danger,
  };

  /// The colour of the text and icon sitting on [colourFor].
  ///
  /// The caution token is `#FFD60A`, a bright yellow: white on it is close
  /// to unreadable. Dark ink on the green and yellow fills, white on the red
  /// — the same rule `VerdictBadgeWidget` follows.
  @visibleForTesting
  static Color inkFor(DishVerdict verdict) => switch (verdict) {
    DishVerdict.orderAsIs || DishVerdict.modifiable => AppTheme.primary,
    DishVerdict.nonKeto => Colors.white,
  };

  /// The chip's icon.
  ///
  /// Deliberately not a directional glyph, so nothing needs mirroring in the
  /// RTL layout.
  @visibleForTesting
  static IconData iconFor(DishVerdict verdict) => switch (verdict) {
    DishVerdict.orderAsIs => Icons.check_circle,
    DishVerdict.modifiable => Icons.edit,
    DishVerdict.nonKeto => Icons.cancel,
  };

  @override
  Widget build(BuildContext context) {
    final ink = inkFor(verdict);

    return Chip(
      key: Key('dish_verdict_badge_${verdict.name}'),
      avatar: Icon(iconFor(verdict), color: ink, size: 20),
      label: Text(
        labelFor(verdict),
        style: TextStyle(color: ink, fontWeight: FontWeight.bold),
      ),
      backgroundColor: colourFor(verdict),
      // The fill is the signal; a border would compete with it.
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
