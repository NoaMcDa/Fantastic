import 'package:fantastic/features/keto_lens/presentation/camera/document_picker.dart';
import 'package:fantastic/features/keto_lens/presentation/camera/file_selector_document_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';

/// A raw [Error] (not an [Exception]), to prove `on Object catch` — not
/// `on Exception catch` — is what guards the platform call. A dedicated
/// class rather than a built-in like [StateError], so this test cannot be
/// mistaken for one accidentally passing on some other [Exception] subtype.
class _FakePlatformError extends Error {
  @override
  String toString() => '_FakePlatformError';
}

void main() {
  group('FileSelectorDocumentPicker.pdfTypeGroup', () {
    // Getting only `extensions` right shows an empty file list on iOS and
    // macOS — the wrong two of the three fail silently, only on a real
    // device, and never in this suite, so every field is asserted here
    // directly rather than trusted to a manual read of the source.
    test('names the PDF type by extension, MIME type and UTI', () {
      const group = FileSelectorDocumentPicker.pdfTypeGroup;

      expect(group.extensions, ['pdf']);
      expect(group.mimeTypes, ['application/pdf']);
      expect(group.uniformTypeIdentifiers, ['com.adobe.pdf']);
    });
  });

  group('FileSelectorDocumentPicker.resultOf', () {
    test('a chosen PDF returns its path', () async {
      final result = await FileSelectorDocumentPicker.resultOf(
        () async => XFile('/downloads/menu.pdf'),
      );

      expect(result, '/downloads/menu.pdf');
    });

    test('a cancelled pick returns null and throws nothing', () async {
      final result = await FileSelectorDocumentPicker.resultOf(
        () async => null,
      );

      expect(result, isNull);
    });

    test('a file with no path (the web case) throws DocumentPickerException '
        'rather than returning null indistinguishably from a cancel — '
        '#408, see design/user_bugs_handoff.md', () async {
      await expectLater(
        FileSelectorDocumentPicker.resultOf(() async => XFile('')),
        throwsA(isA<DocumentPickerException>()),
      );
    });

    test('a platform Exception becomes a DocumentPickerException with the '
        'detail intact', () async {
      await expectLater(
        FileSelectorDocumentPicker.resultOf(
          () async => throw Exception('dialog denied'),
        ),
        throwsA(
          isA<DocumentPickerException>().having(
            (e) => e.toString(),
            'toString()',
            contains('dialog denied'),
          ),
        ),
      );
    });

    test('an Error — not just an Exception — from the platform channel is '
        'caught and wrapped', () async {
      await expectLater(
        FileSelectorDocumentPicker.resultOf(
          () async => throw _FakePlatformError(),
        ),
        throwsA(isA<DocumentPickerException>()),
      );
    });
  });

  group('FileSelectorDocumentPicker.pickPdf', () {
    test('a platform failure is a DocumentPickerException', () async {
      // There is no file_selector platform implementation registered in
      // this test environment — the same reason `PhotoPicker` and
      // `DocumentPicker` are interfaces at all. The plugin call this
      // provokes therefore fails the same way a real platform failure
      // would, and this asserts it surfaces through the same
      // `on Object catch` shape `resultOf` already covers directly, message
      // intact.
      final picker = FileSelectorDocumentPicker();

      await expectLater(
        picker.pickPdf(),
        throwsA(isA<DocumentPickerException>()),
      );
    });
  });
}
