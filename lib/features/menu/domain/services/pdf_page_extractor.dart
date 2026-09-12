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
}

/// Thrown when a PDF cannot be opened at all.
class PdfUnreadableException implements Exception {
  const PdfUnreadableException(this.reason);

  /// Why the PDF could not be opened, in English, for a log or bug report.
  final String reason;

  @override
  String toString() => 'PdfUnreadableException: $reason';
}
