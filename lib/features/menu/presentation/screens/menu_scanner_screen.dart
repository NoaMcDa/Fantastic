import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/features/keto_lens/data/providers.dart';
import 'package:fantastic/features/menu/data/providers.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis_failure_reason.dart';
import 'package:fantastic/features/menu/domain/models/pdf_pages_text.dart';
import 'package:fantastic/features/menu/domain/services/pdf_page_extractor.dart';
import 'package:fantastic/features/menu/presentation/widgets/menu_pages_tab.dart';
import 'package:fantastic/features/menu/presentation/widgets/menu_pdf_tab.dart';
import 'package:fantastic/features/menu/presentation/widgets/menu_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The screen's three input modes.
///
/// A bare enum in the screen's own library — it is UI state, not domain, and
/// nothing outside this screen and its three tab widgets needs to name it.
enum MenuInputMode {
  /// `הדביקו טקסט` — the default.
  pasteText,

  /// `צלמו עמודים`.
  photoPages,

  /// `קובץ PDF` (#408).
  pdfFile,
}

/// The lens tab's `תפריט` chip lands here: paste a menu's text, photograph
/// its pages, or pick a PDF of it, and get a verdict per dish either way.
///
/// ## The states, in the order they are checked
///
/// The same discipline `CameraScreen` and `AddMealDescriptionSheet` both
/// follow — a failure is never buried under a state that assumes success or
/// assumes "still working". There is no `AsyncValue` here to get `hasError`
/// vs. `isLoading` wrong on: the analysis is local `State`, per the issue's
/// Technologies & Approach table ("screen state, since nothing else reads it
/// and it must not outlive the screen") — but the same ordering discipline
/// applies and is asserted the same way: **a failure renders no progress
/// indicator**, because [_analysing] is always false by the time [_result]
/// holds anything.
///
/// 1. **Result.** A [MenuAnalysed] replaces the whole body with
///    [MenuResultView] and a `נתחו תפריט אחר` affordance that returns to
///    input with the pasted text kept.
/// 2. **Failure.** A [MenuAnalysisFailed] renders one headline and one way
///    out per [MenuAnalysisFailureReason] (research §7's table) underneath
///    the still-visible input — the pasted text or the collected pages,
///    whichever mode is selected. Nothing typed or photographed is ever
///    discarded.
/// 3. **Analysing.** A labelled progress row under the input. In the photo
///    mode this is `קורא עמוד N מתוך M…` while [MenuPagesTab]'s pages are
///    OCR'd (#365's `onPage` callback), then the same `מנתח את התפריט…` row
///    the text mode shows.
/// 4. **Input**, `הדביקו טקסט` selected by default: a multi-line field and
///    `נתחו`, disabled on blank text or mid-analysis. `צלמו עמודים`
///    ([MenuPagesTab], #365) captures or imports pages instead and enables
///    `נתחו` at one page — feeding the identical analyser call. `קובץ PDF`
///    ([MenuPdfTab], #408) picks a file instead and feeds the same call
///    with the PDF's own text, its rendered pages, or both — never behind
///    the OCR-availability gate the photo mode checks, because a
///    text-layer PDF needs no OCR at all.
class MenuScannerScreen extends ConsumerStatefulWidget {
  const MenuScannerScreen({super.key});

  /// The headline for a failed analysis.
  ///
  /// `emptyInput` is unreachable — the button is disabled on blank text —
  /// and worded anyway: an unhandled case here would be a compile error, not
  /// a blank headline reaching a user.
  @visibleForTesting
  static String headlineFor(
    MenuAnalysisFailureReason reason,
  ) => switch (reason) {
    MenuAnalysisFailureReason.emptyInput => MenuCopy.failedEmptyInputHeadline,
    MenuAnalysisFailureReason.ocrUnavailable =>
      MenuCopy.failedOcrUnavailableHeadline,
    MenuAnalysisFailureReason.noTextFound => MenuCopy.failedNoTextFoundHeadline,
    MenuAnalysisFailureReason.notConfigured =>
      MenuCopy.failedNotConfiguredHeadline,
    MenuAnalysisFailureReason.offline => MenuCopy.failedOfflineHeadline,
    MenuAnalysisFailureReason.rateLimited => MenuCopy.failedRateLimitedHeadline,
    MenuAnalysisFailureReason.unauthorised =>
      MenuCopy.failedUnauthorisedHeadline,
    MenuAnalysisFailureReason.badResponse => MenuCopy.failedBadResponseHeadline,
    MenuAnalysisFailureReason.noDishesFound =>
      MenuCopy.failedNoDishesFoundHeadline,
    MenuAnalysisFailureReason.pdfUnreadable =>
      MenuCopy.failedPdfUnreadableHeadline,
    MenuAnalysisFailureReason.pdfNeedsOcr => MenuCopy.failedPdfNeedsOcrHeadline,
  };

  /// The way out named beneath [headlineFor]'s headline.
  ///
  /// `rateLimited` reuses `AddMealCopy.rateLimitDetail` rather than
  /// restating the same Hebrew sentence — research §7 names it as the line
  /// "#321 already shows".
  @visibleForTesting
  static String adviceFor(MenuAnalysisFailureReason reason) => switch (reason) {
    MenuAnalysisFailureReason.emptyInput => MenuCopy.adviceEmptyInput,
    MenuAnalysisFailureReason.ocrUnavailable => MenuCopy.adviceOcrUnavailable,
    MenuAnalysisFailureReason.noTextFound => MenuCopy.adviceNoTextFound,
    MenuAnalysisFailureReason.notConfigured => MenuCopy.adviceNotConfigured,
    MenuAnalysisFailureReason.offline => MenuCopy.adviceOffline,
    MenuAnalysisFailureReason.rateLimited => AddMealCopy.rateLimitDetail,
    MenuAnalysisFailureReason.unauthorised => MenuCopy.adviceUnauthorised,
    MenuAnalysisFailureReason.badResponse => MenuCopy.adviceBadResponse,
    MenuAnalysisFailureReason.noDishesFound => MenuCopy.adviceNoDishesFound,
    MenuAnalysisFailureReason.pdfUnreadable => MenuCopy.advicePdfUnreadable,
    MenuAnalysisFailureReason.pdfNeedsOcr => MenuCopy.advicePdfNeedsOcr,
  };

  @override
  ConsumerState<MenuScannerScreen> createState() => _MenuScannerScreenState();
}

class _MenuScannerScreenState extends ConsumerState<MenuScannerScreen> {
  final TextEditingController _text = TextEditingController();

  /// Which input tab is selected. [MenuInputMode.pasteText] is the default.
  MenuInputMode _mode = MenuInputMode.pasteText;
  bool _analysing = false;
  MenuAnalysis? _result;

  /// The paths [MenuPagesTab] last submitted, held only so a retry on a
  /// retryable photo-mode failure can resend the identical pages without
  /// [MenuPagesTab] itself having to expose its internal list.
  List<String> _lastPages = const [];

  /// The path [MenuPdfTab] last submitted — the PDF-mode equivalent of
  /// [_lastPages], for the same reason: a retry on a retryable PDF-mode
  /// failure resends the identical file.
  String? _lastPdfPath;

  /// The page [MenuPageReader] is reading and the total, from the
  /// analyser's `onPage` callback — null before the first page and once
  /// analysis finishes. Drives the `קורא עמוד N מתוך M…` row; a text-only
  /// analysis never calls `onPage`, so this stays null throughout it. Also
  /// used by the PDF mode while its rendered pages are OCR'd.
  int? _readingPage;
  int? _readingOf;

  /// Set by [_analysePdf] when the chosen PDF had more pages than
  /// [MenuVerdictRules.maxPages] — the pages past the cap were simply not
  /// sent. Cleared at the start of every PDF analysis.
  String? _pdfPageCapNotice;

  /// Set by [_analysePdf] when the PDF's extracted text was longer than
  /// [MenuVerdictRules.maxMenuChars] and `MenuAnalysisPrompt.user` silently
  /// truncated it. Cleared at the start of every PDF analysis.
  String? _pdfCharCapNotice;

  @override
  void initState() {
    super.initState();
    // Drives the analyse button's enabled state off what is typed.
    _text.addListener(_onTyped);
  }

  @override
  void dispose() {
    _text
      ..removeListener(_onTyped)
      ..dispose();
    super.dispose();
  }

  void _onTyped() => setState(() {});

  bool get _canAnalyse => !_analysing && _text.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(MenuCopy.scannerTitle)),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    final result = _result;
    // The two PDF-only truncation notices stay visible over a result too —
    // "the analysis still ran" (the issue's own words) means a user who got
    // a verdict must still learn that two pages or the tail of the menu were
    // dropped, not just a user still looking at the input form. Gated on
    // [_mode] so a stale notice from an earlier PDF run cannot bleed into an
    // unrelated later mode.
    final pdfNotices = _mode == MenuInputMode.pdfFile
        ? _buildPdfNotices(context)
        : const <Widget>[];

    if (result is MenuAnalysed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pdfNotices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(children: pdfNotices),
            ),
          Expanded(
            child: _ResultView(
              analysis: result,
              onAnalyseAnother: _backToInput,
            ),
          ),
        ],
      );
    }

    final failure = result is MenuAnalysisFailed ? result : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeTabs(
            mode: _mode,
            onSelect: (mode) => setState(() => _mode = mode),
          ),
          const SizedBox(height: 16),
          ...pdfNotices,
          if (pdfNotices.isNotEmpty) const SizedBox(height: 8),
          // Exhaustive, no `default` — a fourth mode added later fails to
          // compile here rather than rendering a blank tab.
          ...switch (_mode) {
            MenuInputMode.pasteText => _buildTextTab(failure),
            MenuInputMode.photoPages => _buildPhotoTab(failure),
            MenuInputMode.pdfFile => _buildPdfTab(failure),
          },
        ],
      ),
    );
  }

  /// The page-cap and character-cap notices #408 makes visible — both
  /// silent truncations before this issue. Neither is an error: the
  /// analysis still ran, just on less than the whole file.
  List<Widget> _buildPdfNotices(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return [
      if (_pdfPageCapNotice != null)
        Text(
          _pdfPageCapNotice!,
          key: const Key('menu_pdf_page_cap_notice'),
          textAlign: TextAlign.center,
          style: style,
        ),
      if (_pdfCharCapNotice != null)
        Text(
          _pdfCharCapNotice!,
          key: const Key('menu_pdf_char_cap_notice'),
          textAlign: TextAlign.center,
          style: style,
        ),
    ];
  }

  List<Widget> _buildPhotoTab(MenuAnalysisFailed? failure) => [
    // Mounted for the whole time the photo tab is selected — including
    // while `_analysing` is true and while a failure is shown below it — so
    // its own collected pages are never rebuilt away. That is what makes
    // "every failure returns to the pages tab with the thumbnails intact"
    // true without lifting the page list up into this screen.
    MenuPagesTab(
      onAnalyse: _analysePages,
      onSwitchToTextMode: () => setState(() => _mode = MenuInputMode.pasteText),
      analysing: _analysing,
    ),
    if (_analysing) ...[
      const SizedBox(height: 16),
      _readingPage != null && _readingOf != null && _readingPage! < _readingOf!
          ? _ReadingPageIndicator(page: _readingPage!, of: _readingOf!)
          : const _AnalysingIndicator(),
    ],
    if (failure != null) ...[
      const SizedBox(height: 16),
      _FailureView(
        failure: failure,
        onRetry: () => _analysePages(_lastPages),
        onProfile: _openProfile,
      ),
    ],
  ];

  List<Widget> _buildTextTab(MenuAnalysisFailed? failure) => [
    TextField(
      key: const Key('menu_text_field'),
      controller: _text,
      maxLines: 8,
      minLines: 4,
      decoration: const InputDecoration(hintText: MenuCopy.textFieldHint),
    ),
    const SizedBox(height: 12),
    FilledButton(
      key: const Key('menu_analyse_button'),
      onPressed: _canAnalyse ? _analyse : null,
      child: const Text(MenuCopy.analyseButton),
    ),
    if (_analysing) ...[
      const SizedBox(height: 16),
      const _AnalysingIndicator(),
    ],
    if (failure != null) ...[
      const SizedBox(height: 16),
      _FailureView(
        failure: failure,
        onRetry: _analyse,
        onProfile: _openProfile,
      ),
    ],
  ];

  List<Widget> _buildPdfTab(MenuAnalysisFailed? failure) => [
    MenuPdfTab(onAnalyse: _analysePdf, analysing: _analysing),
    if (_analysing) ...[
      const SizedBox(height: 16),
      _readingPage != null && _readingOf != null && _readingPage! < _readingOf!
          ? _ReadingPageIndicator(page: _readingPage!, of: _readingOf!)
          : const _AnalysingIndicator(),
    ],
    if (failure != null) ...[
      const SizedBox(height: 16),
      _FailureView(
        failure: failure,
        onRetry: () => _analysePdf(_lastPdfPath!),
        onProfile: _openProfile,
      ),
    ],
  ];

  Future<void> _analyse() async {
    setState(() {
      _analysing = true;
      _result = null;
    });

    MenuAnalysis outcome;
    try {
      outcome = await ref.read(menuAnalyzerProvider).analyse(text: _text.text);
    } on Object catch (_) {
      // `MenuAnalyzer.analyse` promises never to throw. This catch exists so
      // an implementation that breaks that promise cannot take the screen
      // down with it — the same guard `AddMealDescriptionSheet` keeps around
      // `MacroEstimator`.
      outcome = const MenuAnalysisFailed(
        reason: MenuAnalysisFailureReason.badResponse,
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _analysing = false;
      _result = outcome;
    });
  }

  /// Runs the identical analyser call the text mode uses, with [paths] as
  /// the image paths instead of pasted text — the same result, the same
  /// [MenuResultView], and the same failure states.
  Future<void> _analysePages(List<String> paths) async {
    _lastPages = paths;
    setState(() {
      _analysing = true;
      _result = null;
      _readingPage = null;
      _readingOf = null;
    });

    MenuAnalysis outcome;
    try {
      outcome = await ref
          .read(menuAnalyzerProvider)
          .analyse(
            imagePaths: paths,
            onPage: (page, of) {
              if (mounted) {
                setState(() {
                  _readingPage = page;
                  _readingOf = of;
                });
              }
            },
          );
    } on Object catch (_) {
      // The same guard `_analyse` keeps around the same promise.
      outcome = const MenuAnalysisFailed(
        reason: MenuAnalysisFailureReason.badResponse,
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _analysing = false;
      _result = outcome;
      _readingPage = null;
      _readingOf = null;
    });
  }

  /// Reads [path] as a PDF, renders whichever pages need it, and runs the
  /// identical analyser call the other two modes use — the plan in #408's
  /// Implementation Plan, step 3.
  Future<void> _analysePdf(String path) async {
    _lastPdfPath = path;
    setState(() {
      _analysing = true;
      _result = null;
      _readingPage = null;
      _readingOf = null;
      _pdfPageCapNotice = null;
      _pdfCharCapNotice = null;
    });

    MenuAnalysis outcome;
    try {
      outcome = await _runPdfAnalysis(path);
    } on Object catch (_) {
      // `PdfPageExtractor` and `MenuAnalyzer` both promise never to throw
      // beyond `PdfUnreadableException` (already handled inside
      // `_runPdfAnalysis`). The same guard `_analyse` and `_analysePages`
      // keep around that promise.
      outcome = const MenuAnalysisFailed(
        reason: MenuAnalysisFailureReason.badResponse,
      );
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _analysing = false;
      _result = outcome;
      _readingPage = null;
      _readingOf = null;
    });
  }

  /// The PDF pipeline itself, split out of [_analysePdf] so every exit is a
  /// plain `return` rather than a flag threaded through nested `try` blocks.
  ///
  /// In order:
  /// 1. [PdfPageExtractor.extract] the text layer. A [PdfUnreadableException]
  ///    here — not a PDF, corrupt, or password-protected — is not worth
  ///    retrying with the same file.
  /// 2. Cap the pages at [MenuVerdictRules.maxPages], noting whether that cut
  ///    anything — [_pdfPageCapNotice] is set from the result once this
  ///    method has one to give it.
  /// 3. Pages with no usable text layer are rendered to images **only when
  ///    OCR is available** — this method never checks OCR availability for a
  ///    PDF that has no such page, which is what keeps a text-layer PDF
  ///    working on a build with no engine at all.
  /// 4. With no OCR and no extracted text at all, fail with `pdfNeedsOcr`
  ///    rather than reaching the analyser with nothing to give it.
  /// 5. One [MenuAnalyzer.analyse] call carrying both the extracted text and
  ///    the rendered image paths — never two requests for one PDF.
  Future<MenuAnalysis> _runPdfAnalysis(String path) async {
    final extractor = ref.read(pdfPageExtractorProvider);

    final PdfPagesText pagesText;
    try {
      pagesText = await extractor.extract(path);
    } on PdfUnreadableException {
      return const MenuAnalysisFailed(
        reason: MenuAnalysisFailureReason.pdfUnreadable,
      );
    }

    final pageCapped = pagesText.pageCount > MenuVerdictRules.maxPages;
    final cappedPageCount = pageCapped
        ? MenuVerdictRules.maxPages
        : pagesText.pageCount;

    final cappedPages = <int, String>{
      for (final entry in pagesText.pages.entries)
        if (entry.key <= cappedPageCount) entry.key: entry.value,
    };
    final cappedMissing = pagesText.pagesWithoutTextLayer
        .where((page) => page <= cappedPageCount)
        .toList();
    final cappedText = PdfPagesText(
      pages: cappedPages,
      pageCount: cappedPageCount,
      pagesWithoutTextLayer: cappedMissing,
    ).joined;

    var renderedPaths = const <String>[];
    if (cappedMissing.isNotEmpty) {
      // Read only when there is a page that actually needs it — a
      // text-layer-only PDF (`cappedMissing` empty) never touches this
      // provider at all, which is what "not behind the OCR gate" means in
      // practice, not just in the happy-path test.
      final ocrAvailable = ref.read(textRecognitionServiceProvider).isAvailable;
      if (ocrAvailable) {
        try {
          renderedPaths = await extractor.renderPages(path, cappedMissing);
        } on PdfUnreadableException {
          return const MenuAnalysisFailed(
            reason: MenuAnalysisFailureReason.pdfUnreadable,
          );
        }
      } else if (cappedText.trim().isEmpty) {
        // No text anywhere, and no engine to read the rest as images.
        // `RemoteMenuAnalyzer` would otherwise report this as the generic
        // `ocrUnavailable`, whose advice says nothing about a PDF; failing
        // here gives the PDF-specific reason and advice instead.
        return const MenuAnalysisFailed(
          reason: MenuAnalysisFailureReason.pdfNeedsOcr,
        );
      }
      // Else: OCR is unavailable but some pages did have text — proceed
      // with that text alone, silently dropping the pages nothing can read,
      // exactly as `MenuPageReader` already does per-page for a photographed
      // menu.
    }

    if (mounted) {
      setState(() {
        _pdfPageCapNotice = pageCapped
            ? MenuCopy.pageCapNotice(MenuVerdictRules.maxPages)
            : null;
        _pdfCharCapNotice = cappedText.length > MenuVerdictRules.maxMenuChars
            ? MenuCopy.textTruncatedNotice(MenuVerdictRules.maxMenuChars)
            : null;
      });
    }

    return ref
        .read(menuAnalyzerProvider)
        .analyse(
          text: cappedText.isEmpty ? null : cappedText,
          imagePaths: renderedPaths,
          onPage: (page, of) {
            if (mounted) {
              setState(() {
                _readingPage = page;
                _readingOf = of;
              });
            }
          },
        );
  }

  /// Leaves a result and returns to input. Deliberately does not touch
  /// [_text] — the pasted text is kept, per the issue's happy path.
  void _backToInput() => setState(() => _result = null);

  void _openProfile() {
    // `maybeOf`, not `of`: this screen is pumped in widget tests under a
    // bare `MaterialApp` with no router, and `of` throws there.
    GoRouter.maybeOf(context)?.push(kProfilePath);
  }
}

/// The `הדביקו טקסט` / `צלמו עמודים` / `קובץ PDF` mode selector.
///
/// Below [labelBreakpoint] the three Hebrew labels do not fit next to their
/// icons, so the segments drop to icon-only with a tooltip instead of
/// overflowing — the issue's own instruction for the ~400px case.
class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.mode, required this.onSelect});

  final MenuInputMode mode;
  final ValueChanged<MenuInputMode> onSelect;

  static const Map<MenuInputMode, String> _labels = {
    MenuInputMode.pasteText: MenuCopy.pasteTextTab,
    MenuInputMode.photoPages: MenuCopy.photoPagesTab,
    MenuInputMode.pdfFile: MenuCopy.pdfFileTab,
  };

  static const Map<MenuInputMode, IconData> _icons = {
    MenuInputMode.pasteText: Icons.text_snippet_outlined,
    MenuInputMode.photoPages: Icons.camera_alt_outlined,
    MenuInputMode.pdfFile: Icons.picture_as_pdf_outlined,
  };

  /// Below this width, three labelled segments do not fit — icon-only with
  /// a tooltip instead. `@visibleForTesting` so the ~400px edge case can be
  /// asserted against the same constant this widget actually uses, rather
  /// than a duplicated guess at it.
  @visibleForTesting
  static const double labelBreakpoint = 440;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final showLabels = constraints.maxWidth >= labelBreakpoint;
      return SegmentedButton<MenuInputMode>(
        segments: [
          for (final value in MenuInputMode.values)
            ButtonSegment(
              value: value,
              icon: Icon(_icons[value]),
              label: showLabels ? Text(_labels[value]!) : null,
              tooltip: showLabels ? null : _labels[value],
            ),
        ],
        selected: {mode},
        onSelectionChanged: (selection) => onSelect(selection.first),
      );
    },
  );
}

/// The photo mode's OCR-progress row — `קורא עמוד N מתוך M…`, driven by the
/// analyser's `onPage` callback. Shown in place of [_AnalysingIndicator]
/// while a page is being read; once the last page has been reported,
/// [_MenuScannerScreenState._buildPhotoTab] switches to
/// [_AnalysingIndicator] for the request that follows.
class _ReadingPageIndicator extends StatelessWidget {
  const _ReadingPageIndicator({required this.page, required this.of});

  final int page;
  final int of;

  @override
  Widget build(BuildContext context) => Row(
    key: const Key('menu_reading_page'),
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(width: 12),
      Text(
        MenuCopy.readingPageLabel(page, of),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );
}

/// The analysing state — an indicator with a label, never alone, per
/// `design/m6_handoff.md`'s indeterminate-spinner lesson.
class _AnalysingIndicator extends StatelessWidget {
  const _AnalysingIndicator();

  @override
  Widget build(BuildContext context) => Row(
    key: const Key('menu_analysing'),
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(width: 12),
      Text(
        MenuCopy.analysingLabel,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );
}

/// One headline and one way out per [MenuAnalysisFailureReason]
/// (`design/m16_menu_scanner_research.md` §7). Retry is offered only where
/// `reason.isRetryable`; Profile only where the reason names a key problem.
/// Every other reason's way out is "edit the still-visible text and tap
/// `נתחו` again" — the field above this widget is never hidden or cleared.
class _FailureView extends StatelessWidget {
  const _FailureView({
    required this.failure,
    required this.onRetry,
    required this.onProfile,
  });

  final MenuAnalysisFailed failure;
  final VoidCallback onRetry;
  final VoidCallback onProfile;

  MenuAnalysisFailureReason get reason => failure.reason;

  bool get _offersProfile =>
      reason == MenuAnalysisFailureReason.notConfigured ||
      reason == MenuAnalysisFailureReason.unauthorised;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('menu_failure'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          MenuScannerScreen.headlineFor(reason),
          key: const Key('menu_failure_headline'),
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          MenuScannerScreen.adviceFor(reason),
          key: const Key('menu_failure_advice'),
          style: theme.textTheme.bodySmall,
        ),
        if (failure.statusCode case final code?) ...[
          const SizedBox(height: 4),
          Text(
            MenuCopy.failedStatusCode(code),
            key: const Key('menu_failure_status'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (reason.isRetryable) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('menu_retry_button'),
            onPressed: onRetry,
            child: const Text(AddMealCopy.retry),
          ),
        ],
        if (_offersProfile) ...[
          const SizedBox(height: 8),
          OutlinedButton(
            key: const Key('menu_profile_button'),
            onPressed: onProfile,
            child: const Text(AddMealCopy.openProfile),
          ),
        ],
      ],
    );
  }
}

/// The result state: [MenuResultView] plus a way back to input with the
/// pasted text kept.
class _ResultView extends StatelessWidget {
  const _ResultView({required this.analysis, required this.onAnalyseAnother});

  final MenuAnalysed analysis;
  final VoidCallback onAnalyseAnother;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.all(16),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton(
            key: const Key('menu_analyse_another_button'),
            onPressed: onAnalyseAnother,
            child: const Text(MenuCopy.analyseAnotherMenu),
          ),
        ),
      ),
      Expanded(child: MenuResultView(analysis: analysis)),
    ],
  );
}
