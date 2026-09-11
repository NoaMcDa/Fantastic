import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';

/// Hebrew copy for the dish card and its badge.
///
/// `DishVerdictBadge` is deliberately not `VerdictBadgeWidget`: Keto Lens's
/// amber means "quantity dependent", and this amber means "order it with a
/// change" — `design/m16_menu_scanner_research.md` §1.3. So its three labels
/// live here, not in `VerdictBadgeWidget.labelFor`.
///
/// `lib/core/constants/menu_verdict_rules.dart` (issue #356, filed in
/// parallel) owns the classification rules and the legend copy shown on the
/// results screen — a different concern from the card's own headings and
/// button text kept here. This file is deliberately **not** exported from
/// `constants.dart`, following `goal_copy.dart` / `phase_copy.dart` /
/// `profile_copy.dart`: the barrel exports constants files, not copy files.
abstract final class MenuCopy {
  /// `DishVerdictBadge`'s three labels, keyed by [DishVerdict].
  static const Map<DishVerdict, String> verdictLabels = {
    DishVerdict.orderAsIs: 'אפשר להזמין',
    DishVerdict.modifiable: 'אפשר עם שינוי',
    DishVerdict.nonKeto: 'לא מתאים לקטו',
  };

  /// Heading over the dish's `why` text in the expanded card.
  static const String whyHeading = 'למה';

  /// Heading over the dish's `modification` text in the expanded card.
  static const String modificationHeading = 'מה לבקש';

  /// Tooltip on the button that copies the modification instruction.
  static const String copyInstructionTooltip = 'העתק';

  /// Shown after [copyInstructionTooltip] is tapped and the instruction has
  /// been written to the clipboard.
  static const String copiedConfirmation = 'הועתק';
}
