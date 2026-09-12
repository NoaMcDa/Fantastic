import 'dart:io';
import 'dart:math' as math;

import 'package:fantastic/core/constants/menu_verdict_rules.dart';
import 'package:fantastic/features/keto_lens/data/adapters/ocr_image_prep.dart';
import 'package:fantastic/features/menu/domain/models/pdf_pages_text.dart';
import 'package:fantastic/features/menu/domain/services/pdf_page_extractor.dart';
import 'package:image/image.dart' as img;
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

  @override
  Future<List<String>> renderPages(String pdfPath, List<int> pages) async {
    // Opens nothing for an empty request — the happy path never needs a
    // document at all, and a background render should not pay for one.
    if (pages.isEmpty) {
      return const [];
    }

    await pdfrxFlutterInitialize();

    final PdfDocument document;
    try {
      document = await PdfDocument.openFile(pdfPath);
    } on Object catch (error) {
      throw PdfUnreadableException(error.toString());
    }

    try {
      final pageCount = document.pages.length;

      // A fresh directory per call, under the system temp root — never the
      // app documents directory. Nothing rendered here is persisted: it
      // exists only long enough for `MenuPageReader` to OCR it, per Epic
      // #351's second invariant.
      final tempDir = await Directory.systemTemp.createTemp(
        'fantastic_pdf_pages_',
      );

      final renderedPaths = <String>[];

      // Sequential, never `Future.wait` — the same reason `extract` above
      // and `MenuPageReader.read` both give: pdfium's native calls are not
      // free to parallelise, and a page that hangs should not hide behind
      // the others.
      for (final pageNumber in pages) {
        // Out-of-range page numbers are skipped rather than thrown on. The
        // caller derives this list from `extract`'s own `pageCount`, but a
        // defensive skip costs nothing and a range error in a background
        // render is a blank screen.
        if (pageNumber < 1 || pageNumber > pageCount) {
          continue;
        }

        final path = await _renderPage(
          document.pages[pageNumber - 1],
          pageNumber,
          tempDir.path,
        );
        // A page that fails to render is omitted, not fatal — one bad page
        // must not lose the other seven.
        if (path != null) {
          renderedPaths.add(path);
        }
      }

      return renderedPaths;
    } finally {
      await document.dispose();
    }
  }

  /// Renders one page to a PNG file under [tempDirPath], or returns `null`
  /// if rendering that page failed for any reason.
  static Future<String?> _renderPage(
    PdfPage page,
    int pageNumber,
    String tempDirPath,
  ) async {
    final pageWidth = page.width;
    final pageHeight = page.height;
    // A degenerate page size (a corrupt page dictionary, not a corrupt
    // file — `extract` already opened the document successfully) cannot be
    // scaled to anything sensible. Omit it rather than divide by zero.
    if (pageWidth <= 0 || pageHeight <= 0) {
      return null;
    }

    final size = renderSizeFor(pageWidth: pageWidth, pageHeight: pageHeight);

    PdfImage? image;
    try {
      // Leaving `width`/`height` unset renders the *whole* page — only
      // `fullWidth`/`fullHeight` are given, which set the resolution the
      // page is rasterised at while preserving its own aspect ratio. There
      // is deliberately no fixed height and no letterboxing: a stretched
      // page is a page the engine reads wrong.
      image = await page.render(
        fullWidth: size.width.toDouble(),
        fullHeight: size.height.toDouble(),
      );
      if (image == null) {
        return null;
      }

      // `PdfImage.pixels` is BGRA8888; `ChannelOrder.bgra` tells `package:
      // image` to swap red and blue back on the way in rather than writing
      // out a blue-tinted PNG.
      final decoded = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: image.pixels.buffer,
        bytesOffset: image.pixels.offsetInBytes,
        numChannels: 4,
        order: img.ChannelOrder.bgra,
      );

      final path = '$tempDirPath/page_$pageNumber.png';
      // PNG, not JPEG: this file exists only to be read back by Tesseract
      // moments later, and lossy compression around glyph edges is a
      // recognition cost paid for a disk saving nobody needs — the same
      // reason `ScalingTextRecognizer` encodes PNG for its own prepared
      // copies.
      await File(path).writeAsBytes(img.encodePng(decoded));
      return path;
    } on Object {
      return null;
    } finally {
      image?.dispose();
    }
  }

  /// The pixel size a page of [pageWidth]x[pageHeight] points (pdfrx's own
  /// unit, at 72 dpi) is rendered at.
  ///
  /// [MenuVerdictRules.pdfRenderWidthPx] wide, with height following the
  /// page's own aspect ratio — never a fixed height, never letterboxed. The
  /// result is then clamped, never grown, so it never crosses
  /// `OcrImagePrep.maxEdge` or `OcrImagePrep.maxPixels`: those two are
  /// memory guards, not tuning knobs (see `OcrImagePrep`'s own doc comment),
  /// and a tall poster-format menu page is exactly the shape that could
  /// otherwise blow past them on height alone while its width stays capped.
  ///
  /// `@visibleForTesting`: pure arithmetic, checkable with no PDF and no
  /// native module at all — the same reason [legibleTextOf] is exposed.
  @visibleForTesting
  static ({int width, int height}) renderSizeFor({
    required double pageWidth,
    required double pageHeight,
  }) {
    var width = MenuVerdictRules.pdfRenderWidthPx.toDouble();
    var height = width * pageHeight / pageWidth;

    final longestEdge = math.max(width, height);
    if (longestEdge > OcrImagePrep.maxEdge) {
      final factor = OcrImagePrep.maxEdge / longestEdge;
      width *= factor;
      height *= factor;
    }

    if (width * height > OcrImagePrep.maxPixels) {
      final factor = math.sqrt(OcrImagePrep.maxPixels / (width * height));
      width *= factor;
      height *= factor;
    }

    return (width: width.round(), height: height.round());
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
