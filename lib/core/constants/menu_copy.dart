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

  // --- MenuScannerScreen (#364) ---

  /// The screen's app-bar title.
  static const String scannerTitle = 'ניתוח תפריט';

  /// The two input-mode tab labels. `photoPagesTab` names the mode #365
  /// wires up; until then it renders [photoTabComingSoon].
  static const String pasteTextTab = 'הדביקו טקסט';
  static const String photoPagesTab = 'צלמו עמודים';

  /// The photo tab's whole body until #365 replaces it — the reason this
  /// issue can ship the text mode on its own.
  static const String photoTabComingSoon = 'בקרוב';

  static const String textFieldHint = 'הדביקו כאן את הטקסט של התפריט';

  static const String analyseButton = 'נתחו';

  /// The analysing state's label. Always paired with the indicator
  /// (`Key('menu_analysing')`) — never an indicator alone, per
  /// `design/m6_handoff.md`'s labelled-progress rule.
  static const String analysingLabel = 'מנתח את התפריט…';

  /// Leaves a result and returns to input, with the pasted text kept.
  static const String analyseAnotherMenu = 'נתחו תפריט אחר';

  /// A headline per `MenuAnalysisFailureReason` — research §7's table.
  /// `emptyInput`'s is unreachable (the button is disabled on blank text)
  /// and worded anyway, so an unhandled case is a compile error rather than
  /// a blank headline.
  static const String failedEmptyInputHeadline = 'לא הודבק טקסט לניתוח';
  static const String failedOcrUnavailableHeadline = 'הסורק לא זמין במכשיר הזה';
  static const String failedNoTextFoundHeadline = 'לא זוהה טקסט בתמונות';
  static const String failedNotConfiguredHeadline = 'ניתוח תפריטים לא מופעל';
  static const String failedOfflineHeadline = 'אין חיבור לאינטרנט';
  static const String failedRateLimitedHeadline = 'חרגתם ממכסת הבקשות היומית';
  static const String failedUnauthorisedHeadline = 'המפתח נדחה';
  static const String failedBadResponseHeadline = 'הניתוח נכשל';
  static const String failedNoDishesFoundHeadline = 'לא זוהו מנות בתפריט';

  /// The "way out" beneath each headline above, in the same order.
  static const String adviceEmptyInput = 'יש להדביק טקסט לפני הניתוח.';
  static const String adviceOcrUnavailable =
      'הדביקו את טקסט התפריט בלשונית "הדביקו טקסט" במקום.';
  static const String adviceNoTextFound =
      'צלמו שוב את העמודים, או הדביקו את הטקסט של התפריט.';
  static const String adviceNotConfigured =
      'הפעילו ניתוח תפריטים בפרופיל כדי להמשיך.';
  static const String adviceOffline =
      'בדקו את החיבור לאינטרנט ונסו שוב. הטקסט שהדבקתם נשמר.';
  static const String adviceUnauthorised = 'בדקו את המפתח שהוזן בפרופיל.';
  static const String adviceBadResponse = 'נסו שוב.';
  static const String adviceNoDishesFound = 'ערכו את הטקסט ונסו שוב.';

  // --- MenuPagesTab (#365) ---

  /// The link out of the OCR-unavailable state, back to `הדביקו טקסט`. Not
  /// a retry — the M6 rule that an engine that cannot run here is not worth
  /// asking again.
  static const String switchToTextMode = 'הדביקו את הטקסט במקום';

  /// Paired with `Key('menu_reading_page')` while [MenuPageReader]
  /// recognises one page — never an indicator alone, per
  /// `design/m6_handoff.md`'s labelled-progress rule.
  static String readingPageLabel(int page, int of) =>
      'קורא עמוד $page מתוך $of…';

  /// Shown when a capture or a gallery pick would exceed
  /// [MenuVerdictRules.maxPages] — a one-line notice, not an error, per the
  /// issue's own instruction. The extra photos are simply not added.
  static String pageCapNotice(int maxPages) =>
      'ניתן לצלם עד $maxPages עמודים. התמונות הנוספות לא נוספו.';

  /// `3 / 8` — kept in its own method, not built inline, so every page
  /// counter in this feature reads identically. Wrapped by the caller in an
  /// LTR `Directionality`, per `CLAUDE.md`'s digit-run rule.
  static String pageCounterLabel(int count, int maxPages) =>
      '$count / $maxPages';

  /// A refused photo-library permission, most often. The same Hebrew
  /// `CameraScreen._pickFromGallery` shows inline; kept here as its own
  /// constant because this file, unlike that one, owns every string this
  /// feature renders.
  static const String galleryError = 'לא ניתן לפתוח את הגלריה';

  /// A capture that threw — a disposed controller, a capture already in
  /// flight, no storage. The same Hebrew `CameraScreen._capture` shows
  /// inline, for the same reason as [galleryError].
  static const String captureFailed = 'הצילום נכשל, נסו שוב';

  /// The camera-starting state's label, mirroring `CameraScreen`'s own.
  static const String cameraStartingLabel = 'פותח מצלמה...';

  /// The gallery affordance offered even when the camera itself will not
  /// open — "a menu photographed earlier is a real case" (the issue's own
  /// words).
  static const String importFromGallery = 'ייבוא מהגלריה';

  /// Tooltip on the per-thumbnail remove control.
  static const String removePageTooltip = 'הסירו עמוד';
}
