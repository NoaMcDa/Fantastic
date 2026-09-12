/// Picks a document — today, a PDF menu — from the device.
///
/// A sibling of [DocumentPicker]'s neighbour `PhotoPicker` rather than a
/// method on it: that class is documented as the only importer of
/// `image_picker`, and this one is the only importer of `file_selector`. One
/// adapter per plugin is the rule the OCR adapters follow too.
abstract interface class DocumentPicker {
  /// Returns the chosen PDF's path, or null if the user backed out.
  ///
  /// Backing out is not an error and must not be reported as one — it is
  /// the single most common way this call ends.
  ///
  /// Throws [DocumentPickerException] when the picker itself fails, **and
  /// also** when the platform handed back a file with no filesystem path —
  /// genuinely possible on the web, where a picked file carries bytes
  /// rather than a path. That case is reported as a failure rather than
  /// folded into the null-on-cancel result: a caller that cannot tell "the
  /// user backed out" from "this platform cannot give me a path" renders
  /// nothing either way, which on the web is a silent no-op on a pick that
  /// genuinely happened (`design/user_bugs_handoff.md` records this exact
  /// shape of bug).
  Future<String?> pickPdf();
}

/// Thrown when the picker itself fails — not when the user cancels.
class DocumentPickerException implements Exception {
  const DocumentPickerException(this.detail);

  /// The platform's own message, for a log or a bug report.
  final String detail;

  @override
  String toString() => 'DocumentPickerException: $detail';
}
