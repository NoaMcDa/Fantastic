import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/features/menu/domain/models/pdf_pages_text.dart';
import 'package:fantastic/features/menu/domain/services/pdf_page_extractor.dart';
import 'package:meta/meta.dart';
import 'package:pdfrx/pdfrx.dart';

/// [PdfPageExtractor] over `pdfrx`.
///
/// The only file in `lib/` that imports `package:pdfrx` — pinned by
/// `pdf_page_extractor_impl_test.dart` — for the same reason
/// `TesseractPluginRecognizer` and its siblings are the only importers of
/// their own plugins: everything above `data/` sees the interface only.
///
/// `pdfrx` declares all six platforms (including web, via wasm), so unlike
/// the Keto Lens OCR engines this needs no conditional-export firewall — see
/// `text_recognizer_factory.dart` for the shape a firewall would take if one
/// ever proves necessary here.
class PdfrxPageExtractor implements PdfPageExtractor {
  const PdfrxPageExtractor();

  // `pdfrx` declares every one of the six targets, so there is no platform
  // this build cannot read a PDF on — unlike `TextRecognitionService`, whose
  // browser half has no on-device engine at all.
  @override
  bool get isAvailable => true;

  @override
  Future<PdfPagesText> extract(String pdfPath) async {
    // Required before touching the document API directly (as opposed to
    // building a `PdfViewer` widget first, which performs this itself) —
    // `pdfrx`'s own README calls this out. Idempotent: a second call is a
    // no-op, so this pays no cost across repeated `extract` calls.
    await pdfrxFlutterInitialize();

    final PdfDocument document;
    try {
      document = await PdfDocument.openFile(pdfPath);
    } on Object catch (error) {
      // Not a PDF, corrupt, or encrypted with no password supplied — pdfrx
      // reports all three as a thrown object (a `PdfPasswordException` for
      // the last, a `PdfException` otherwise). Neither is swallowed: the
      // caller needs to tell an encrypted file from a readable one with no
      // text layer, and `reason` carries pdfrx's own message so it does.
      throw PdfUnreadableException(error.toString());
    }

    try {
      final pageCount = document.pages.length;
      final pages = <int, String>{};
      final pagesWithoutTextLayer = <int>[];

      // Sequential, never `Future.wait` — `MenuPageReader.read`'s documented
      // reason applies here too: a page reader that fans out hides which
      // page is slow, and pdfium's native calls are not free to parallelise.
      for (final page in document.pages) {
        final pageNumber = page.pageNumber;
        String rawText;
        try {
          final pageText = await page.loadText();
          rawText = pageText?.fullText ?? '';
        } on Object {
          // A single page failing to extract is not the whole PDF failing to
          // open — treat it the same as a page with no text layer rather
          // than losing every other page to one bad one.
          rawText = '';
        }

        final legibleText = legibleTextOf(rawText);
        if (legibleText == null) {
          pagesWithoutTextLayer.add(pageNumber);
        } else {
          pages[pageNumber] = legibleText;
        }
      }

      return PdfPagesText(
        pages: pages,
        pageCount: pageCount,
        pagesWithoutTextLayer: pagesWithoutTextLayer,
      );
    } finally {
      await document.dispose();
    }
  }

  /// The legibility guard, in the order the issue specifies:
  ///
  /// 1. Trim; empty means no text layer.
  /// 2. Fewer than [MenuVerdictRules.minExtractedLetters] letters means the
  ///    Hebrew ratio below would not be meaningful — treated as no text
  ///    layer.
  /// 3. Of those letters, the Hebrew share must clear
  ///    [MenuVerdictRules.minHebrewLetterRatio], or this is the subset-font
  ///    mojibake case and the page is treated as having no text layer.
  /// 4. Otherwise the (trimmed) text is kept.
  ///
  /// Returns `null` for a page failing any step — never a partial or
  /// "best effort" string. Half-decoded text is exactly the input the
  /// `MenuResponseParser` provenance rule cannot protect against, because an
  /// invented dish would match invented source.
  ///
  /// `@visibleForTesting`, following `IngredientClassifierImpl`'s precedent:
  /// this is the whole reason the issue exists, and it is pure string logic
  /// that deserves direct unit tests rather than only the three committed
  /// fixture PDFs.
  @visibleForTesting
  static String? legibleTextOf(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final letterCount = _letterPattern.allMatches(trimmed).length;
    if (letterCount < MenuVerdictRules.minExtractedLetters) {
      return null;
    }

    final hebrewCount = _hebrewLetterPattern.allMatches(trimmed).length;
    final hebrewRatio = hebrewCount / letterCount;
    if (hebrewRatio < MenuVerdictRules.minHebrewLetterRatio) {
      return null;
    }

    return trimmed;
  }

  /// Any Unicode letter, in any script — the denominator of the Hebrew
  /// ratio. `unicode: true` enables the `\p{...}` Unicode property escape.
  static final RegExp _letterPattern = RegExp(r'\p{L}', unicode: true);

  /// The Hebrew alphabet block, `א`–`ת` — this covers the five final forms
  /// (`ך ם ן ף ץ`) too, since they sit inside the same contiguous range.
  static final RegExp _hebrewLetterPattern = RegExp('[א-ת]');
}
