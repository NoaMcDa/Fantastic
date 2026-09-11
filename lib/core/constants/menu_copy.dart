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

  // --- MenuResultView (#362) ---

  /// Heading over the green group — [DishVerdict.orderAsIs].
  static const String orderAsIsHeading = 'אפשר להזמין';

  /// Heading over the yellow group — [DishVerdict.modifiable].
  static const String modifiableHeading = 'אפשר עם שינוי';

  /// The always-visible label on the collapsed/expanded red header —
  /// [DishVerdict.nonKeto]. The same Hebrew as [verdictLabels]'s entry for
  /// that verdict, kept as its own constant because the header is a
  /// standalone heading rather than a badge.
  static const String nonKetoHeading = 'לא מתאים לקטו';

  /// Heading over `MenuAnalysed.unclassified` — reported, never dropped.
  static const String unclassifiedHeading = 'לא ניתן לקבוע';

  /// One-line note under [unclassifiedHeading] explaining what the plain
  /// rows beneath it are.
  static const String unclassifiedNote =
      'שמות אלה הופיעו בתפריט אך לא ניתן היה לקבוע את התאמתם לקטו.';

  /// Shown above the unclassified section when `MenuAnalysed.dishes` is
  /// empty and `unclassified` is not — every name from the reply landed
  /// there and none earned a verdict. Replaces an empty-list state, which
  /// would read as "nothing was found" rather than "nothing could be
  /// classified".
  static const String noDishesClassifiedNote =
      'המנות זוהו אך לא ניתן היה לסווג אותן';

  /// The warning line naming the pages OCR read nothing from — one page
  /// (`עמוד 3 לא נקרא — נסו לצלם שוב`) or several
  /// (`עמודים 2 ו-4 לא נקראו — נסו לצלם שוב`). The caller only shows this
  /// line when [pages] is non-empty; this method does not special-case an
  /// empty list.
  static String unreadPagesLine(List<int> pages) {
    final sorted = [...pages]..sort();
    final isPlural = sorted.length > 1;
    final pageWord = isPlural ? 'עמודים' : 'עמוד';
    final verb = isPlural ? 'לא נקראו' : 'לא נקרא';
    return '$pageWord ${_joinPageNumbers(sorted)} $verb — נסו לצלם שוב';
  }

  /// `[3]` → `'3'`; `[2, 4]` → `'2 ו-4'`; `[2, 3, 4]` → `'2, 3 ו-4'`.
  static String _joinPageNumbers(List<int> pages) {
    if (pages.length == 1) {
      return '${pages.first}';
    }
    final allButLast = pages.sublist(0, pages.length - 1).join(', ');
    return '$allButLast ו-${pages.last}';
  }
}
