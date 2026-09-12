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
  /// Throws [DocumentPickerException] when the picker itself fails.
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
