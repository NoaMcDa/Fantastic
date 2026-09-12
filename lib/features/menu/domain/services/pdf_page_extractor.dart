import 'package:fantastic/features/menu/domain/models/pdf_pages_text.dart';

/// The text layer of a PDF, page by page.
///
/// The boundary type is a `String` path and plain Dart values, for the
/// reason `TextRecognitionService` gives: a `pdfrx` type in this signature
/// would drag a native dependency into `domain/`, which `CLAUDE.md`'s layer
/// rules forbid, and would make everything above `data/` untestable.
abstract interface class PdfPageExtractor {
  /// Whether this build can read a PDF at all.
  bool get isAvailable;

  /// Reads the text layer of the PDF at [pdfPath].
  ///
  /// Throws [PdfUnreadableException] when the file is not a PDF, is
  /// corrupt, or is encrypted. Never throws for a PDF that simply has no
  /// text layer — that is a normal result, reported per page.
  Future<PdfPagesText> extract(String pdfPath);

  /// Renders [pages] (1-based) of the PDF at [pdfPath] to image files and
  /// returns their paths, in page order.
  ///
  /// For a page whose text layer is missing or illegible — the pages
  /// `PdfPagesText.pagesWithoutTextLayer` names — this is the only way to
  /// read it: the result goes to `MenuPageReader`, exactly as a
  /// photographed page would.
  ///
  /// Throws [PdfUnreadableException] on the same terms as [extract].
  /// A page that cannot be rendered is **omitted** from the result rather
  /// than failing the batch — one bad page must not lose the other seven.
  Future<List<String>> renderPages(String pdfPath, List<int> pages);
}

/// Thrown when a PDF cannot be opened at all.
class PdfUnreadableException implements Exception {
  const PdfUnreadableException(this.reason);

  /// Why the PDF could not be opened, in English, for a log or bug report.
  final String reason;

  @override
  String toString() => 'PdfUnreadableException: $reason';
}
