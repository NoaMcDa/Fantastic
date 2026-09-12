import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:fantastic/features/menu/domain/models/menu_pages_text.dart';

/// OCRs each menu page on the device, in order, and reports the pages it
/// could not read. Never throws.
///
/// The sibling of `ScanOrchestrator` with the parser removed: composed from
/// one domain interface, and never sees a plugin type. That is what keeps
/// `RemoteMenuAnalyzer`'s own tests free of OCR — this class is where the
/// engine is exercised, in isolation, against a mocked
/// [TextRecognitionService].
///
/// Nothing here ever leaves the device — this class is the reason Epic
/// #351's first architectural invariant ("the photograph never leaves the
/// device — only recognised text is sent") is true.
class MenuPageReader {
  const MenuPageReader({required this.recognizer});

  // Public rather than private, for the reason `ScanOrchestrator` records:
  // Dart forbids a named parameter starting with an underscore, so a
  // `_recognizer` field cannot use an initializing formal. It is an
  // interface; nothing leaks.
  final TextRecognitionService recognizer;

  /// The line placed between pages. The prompt names it.
  static String pageMarker(int page) => '--- עמוד $page ---';

  /// Reads every page in [imagePaths], in order, and joins what OCR found.
  ///
  /// [onPage] is invoked before each page with its 1-based index and the
  /// total, so a screen can render `קורא עמוד 2 מתוך 5…`.
  ///
  /// Pages are read **sequentially, never with `Future.wait`** — the VM
  /// recogniser already isolates each call, the web worker is one worker,
  /// and the per-page progress line is the UX the research document asks
  /// for; running them in parallel would make that line meaningless.
  ///
  /// Any path beyond [MenuVerdictRules.maxPages] is not read at all, and is
  /// **not** added to [MenuPagesText.unreadPages] — the input screen enforces
  /// the cap before this is ever called, so a longer list here means the
  /// caller already truncated wrong; this method truncates again rather than
  /// trust it, and stays silent about the pages it never touched.
  Future<MenuPagesText> read(
    List<String> imagePaths, {
    void Function(int page, int of)? onPage,
  }) async {
    if (imagePaths.isEmpty) {
      return const MenuPagesText(text: '', pageCount: 0);
    }

    final pageCount = imagePaths.length;

    // Asked before the first page, not after a failure: on a build with no
    // engine this is a compile-time fact, and the screen should never have
    // offered a camera.
    if (!recognizer.isAvailable) {
      return MenuPagesText(
        text: '',
        pageCount: pageCount,
        unreadPages: List.generate(pageCount, (i) => i + 1),
        ocrUnavailable: true,
      );
    }

    final pathsToRead = imagePaths.take(MenuVerdictRules.maxPages).toList();
    final buffer = StringBuffer();
    final unreadPages = <int>[];

    for (var i = 0; i < pathsToRead.length; i++) {
      final page = i + 1;
      onPage?.call(page, pageCount);

      String pageText;
      try {
        pageText = await recognizer.recognise(pathsToRead[i]);
      } on Object {
        // `Object`, not `Exception`: a platform channel can deliver an
        // `Error`, and a menu that crashes the screen is worse than a page
        // that failed. The reason `ScanOrchestrator` gives.
        unreadPages.add(page);
        continue;
      }

      if (pageText.trim().isEmpty) {
        unreadPages.add(page);
        continue;
      }

      buffer
        ..writeln(pageMarker(page))
        ..writeln(pageText)
        ..writeln();
    }

    return MenuPagesText(
      text: buffer.toString().trim(),
      pageCount: pageCount,
      unreadPages: unreadPages,
    );
  }
}
