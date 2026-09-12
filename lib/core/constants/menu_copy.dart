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

  /// The three input-mode tab labels. `photoPagesTab` names the mode #365
  /// wires up; until then it renders [photoTabComingSoon]. `pdfFileTab`
  /// names the third mode #408 adds.
  static const String pasteTextTab = 'הדביקו טקסט';
  static const String photoPagesTab = 'צלמו עמודים';
  static const String pdfFileTab = 'קובץ PDF';

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

  /// #408's two PDF-only failure reasons — added to the same headline set,
  /// so `MenuScannerScreen.headlineFor`'s exhaustive switch fails to compile
  /// if either is left out.
  static const String failedPdfUnreadableHeadline = 'לא ניתן לפתוח את הקובץ';
  static const String failedPdfNeedsOcrHeadline =
      'לא ניתן לקרוא את התפריט הסרוק';

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

  /// The PDF is not a PDF at all, is corrupt, or is password-protected — not
  /// worth retrying with the same file, so this names no retry action.
  static const String advicePdfUnreadable =
      'בחרו קובץ PDF אחר, או ודאו שהקובץ אינו מוגן בסיסמה.';

  /// No page of the PDF had a usable text layer, and this build has no OCR
  /// engine to read it as a scanned image — points at the pasted-text mode,
  /// which needs neither OCR nor a readable text layer, per the issue.
  static const String advicePdfNeedsOcr =
      'המכשיר הזה אינו יכול לקרוא תפריט סרוק. הדביקו את טקסט התפריט בלשונית '
      '"הדביקו טקסט" במקום.';

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

  // --- MenuPdfTab (#408) ---

  /// The empty state's pick button.
  static const String pickPdfButton = 'בחרו קובץ PDF';

  /// Shown under [pickPdfButton] — the mode this isn't is still one tap
  /// away, per the issue's own instruction to name the alternative.
  static const String pdfAlternativeHint =
      'אפשר גם לצלם את עמודי התפריט בלשונית "צלמו עמודים".';

  /// Tooltip on the chosen-file state's clear control.
  static const String removePdfTooltip = 'הסירו קובץ';

  /// A [DocumentPickerException] — the platform picker itself failing, or
  /// (`design/user_bugs_handoff.md`'s exact shape of bug) handing back a
  /// file with no filesystem path, which the adapter now reports as this
  /// same exception rather than silently returning null. A cancelled pick
  /// is not an error and shows nothing.
  static const String pdfPickError =
      'לא ניתן היה לפתוח את הקובץ שנבחר. נסו שוב.';

  /// A PDF's page count over [MenuVerdictRules.maxPages] reuses
  /// [pageCapNotice] verbatim — the same cap, the same wording, regardless
  /// of whether the pages arrived by camera or inside a PDF.
  ///
  /// Shown when the PDF's extracted text is longer than
  /// [MenuVerdictRules.maxMenuChars] and `MenuAnalysisPrompt.user` silently
  /// truncated it before sending — an inline notice, not an error: the
  /// analysis still ran, just on the first [maxChars] characters.
  static String textTruncatedNotice(int maxChars) =>
      'התפריט ארוך מ-$maxChars תווים, ולכן רק תחילתו נותחה.';
}
