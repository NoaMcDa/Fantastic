import 'package:fantastic/features/keto_lens/presentation/camera/document_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'file_selector_document_picker.g.dart';

/// [DocumentPicker] over `package:file_selector`.
///
/// **The only file in `lib/` that imports `file_selector`** — the same
/// one-adapter-one-plugin shape as `image_picker_photo_picker.dart` and
/// `tesseract_plugin_recognizer.dart`.
class FileSelectorDocumentPicker implements DocumentPicker {
  FileSelectorDocumentPicker();

  /// Names the PDF type on every platform that needs naming: extension for
  /// Windows and Linux, MIME type for Android and the browser, and the
  /// uniform type identifier for iOS and macOS. Naming only [XTypeGroup.
  /// extensions] shows an empty file list on Darwin — a silent, confusing
  /// "I have no PDFs" rather than a loud failure — so all three, plus the
  /// web wildcard, are set together.
  @visibleForTesting
  static const XTypeGroup pdfTypeGroup = XTypeGroup(
    label: 'PDF',
    extensions: ['pdf'],
    mimeTypes: ['application/pdf'],
    uniformTypeIdentifiers: ['com.adobe.pdf'],
    webWildCards: ['.pdf'],
  );

  @override
  Future<String?> pickPdf() =>
      resultOf(() => openFile(acceptedTypeGroups: const [pdfTypeGroup]));

  /// Runs [open] and turns its outcome into the contract [pickPdf] promises.
  ///
  /// Split out so it can be driven directly with a fake in tests: the real
  /// `file_selector` call cannot be substituted (there is no `file_selector`
  /// platform implementation registered in a widget-test environment, and no
  /// platform at all to open a real dialog on), so this is where the actual
  /// decision logic — null-on-cancel, empty-path-on-web, catch-and-wrap —
  /// lives and gets exercised.
  @visibleForTesting
  static Future<String?> resultOf(Future<XFile?> Function() open) async {
    try {
      final file = await open();
      // Null means the user backed out of the picker. Not an error, and not
      // something to tell them about.
      if (file == null) return null;
      // On the web a picked file carries bytes but no filesystem path, which
      // XFile represents as an empty string rather than null. Returning that
      // empty string as-is would read to a caller as "chose a file at no
      // path" rather than "the platform cannot give one" — so it is mapped
      // to null explicitly instead of passed through.
      return file.path.isEmpty ? null : file.path;
    } on Object catch (error) {
      // A platform channel can throw an Error, not only an Exception — the
      // same reason `guardPersistence` and `ImagePickerPhotoPicker` catch
      // Object rather than Exception.
      throw DocumentPickerException('$error');
    }
  }
}

/// How the menu scanner imports a PDF.
///
/// Overridden in widget tests with a fake.
@Riverpod(keepAlive: true)
DocumentPicker documentPicker(Ref ref) => FileSelectorDocumentPicker();
