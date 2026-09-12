import 'package:fantastic/core/constants/add_meal_copy.dart';
import 'package:fantastic/core/constants/menu_copy.dart';
import 'package:fantastic/core/router/app_router.dart';
import 'package:fantastic/features/menu/data/providers.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis.dart';
import 'package:fantastic/features/menu/domain/models/menu_analysis_failure_reason.dart';
import 'package:fantastic/features/menu/presentation/widgets/menu_pages_tab.dart';
import 'package:fantastic/features/menu/presentation/widgets/menu_result_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The lens tab's `תפריט` chip lands here: paste a menu's text and get a
/// verdict per dish, or photograph its pages and get the same.
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
///    `נתחו` at one page — feeding the identical analyser call.
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
  };

  @override
  ConsumerState<MenuScannerScreen> createState() => _MenuScannerScreenState();
}

class _MenuScannerScreenState extends ConsumerState<MenuScannerScreen> {
  final TextEditingController _text = TextEditingController();

  /// Which input tab is selected. `false` (text) is the default.
  bool _photoTab = false;
  bool _analysing = false;
  MenuAnalysis? _result;

  /// The paths [MenuPagesTab] last submitted, held only so a retry on a
  /// retryable photo-mode failure can resend the identical pages without
  /// [MenuPagesTab] itself having to expose its internal list.
  List<String> _lastPages = const [];

  /// The page [MenuPageReader] is reading and the total, from the
  /// analyser's `onPage` callback — null before the first page and once
  /// analysis finishes. Drives the `קורא עמוד N מתוך M…` row; a text-only
  /// analysis never calls `onPage`, so this stays null throughout it.
  int? _readingPage;
  int? _readingOf;

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
    if (result is MenuAnalysed) {
      return _ResultView(analysis: result, onAnalyseAnother: _backToInput);
    }

    final failure = result is MenuAnalysisFailed ? result.reason : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ModeTabs(
            photoSelected: _photoTab,
            onSelect: (photo) => setState(() => _photoTab = photo),
          ),
          const SizedBox(height: 16),
          if (_photoTab)
            ..._buildPhotoTab(failure)
          else
            ..._buildTextTab(failure),
        ],
      ),
    );
  }

  List<Widget> _buildPhotoTab(MenuAnalysisFailureReason? failure) => [
    // Mounted for the whole time the photo tab is selected — including
    // while `_analysing` is true and while a failure is shown below it — so
    // its own collected pages are never rebuilt away. That is what makes
    // "every failure returns to the pages tab with the thumbnails intact"
    // true without lifting the page list up into this screen.
    MenuPagesTab(
      onAnalyse: _analysePages,
      onSwitchToTextMode: () => setState(() => _photoTab = false),
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
        reason: failure,
        onRetry: () => _analysePages(_lastPages),
        onProfile: _openProfile,
      ),
    ],
  ];

  List<Widget> _buildTextTab(MenuAnalysisFailureReason? failure) => [
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
      _FailureView(reason: failure, onRetry: _analyse, onProfile: _openProfile),
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

  /// Leaves a result and returns to input. Deliberately does not touch
  /// [_text] — the pasted text is kept, per the issue's happy path.
  void _backToInput() => setState(() => _result = null);

  void _openProfile() {
    // `maybeOf`, not `of`: this screen is pumped in widget tests under a
    // bare `MaterialApp` with no router, and `of` throws there.
    GoRouter.maybeOf(context)?.push(kProfilePath);
  }
}

/// The `הדביקו טקסט` / `צלמו עמודים` mode selector.
class _ModeTabs extends StatelessWidget {
  const _ModeTabs({required this.photoSelected, required this.onSelect});

  final bool photoSelected;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) => SegmentedButton<bool>(
    segments: const [
      ButtonSegment(
        value: false,
        label: Text(MenuCopy.pasteTextTab),
        icon: Icon(Icons.text_snippet_outlined),
      ),
      ButtonSegment(
        value: true,
        label: Text(MenuCopy.photoPagesTab),
        icon: Icon(Icons.camera_alt_outlined),
      ),
    ],
    selected: {photoSelected},
    onSelectionChanged: (selection) => onSelect(selection.first),
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
    required this.reason,
    required this.onRetry,
    required this.onProfile,
  });

  final MenuAnalysisFailureReason reason;
  final VoidCallback onRetry;
  final VoidCallback onProfile;

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
