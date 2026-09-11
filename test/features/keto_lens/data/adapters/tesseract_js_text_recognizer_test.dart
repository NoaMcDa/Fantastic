@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:fantastic/features/keto_lens/data/adapters/tesseract_js_text_recognizer.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// The browser recogniser's binding to `window.fantasticOcr`.
///
/// Runs only under `flutter test --platform chrome`:
///
/// ```
/// CHROME_EXECUTABLE=... flutter test --platform chrome \
///   test/features/keto_lens/data/adapters/tesseract_js_text_recognizer_test.dart
/// ```
///
/// ## What this covers, and why it is worth a file
///
/// Not the OCR — a stub stands in for tesseract.js here. What is being tested
/// is the **`dart:js_interop` boundary**, which is the part that fails
/// silently: an `extension type` whose member names do not match the JS
/// object, or a `JSPromise<JSString>` that should have been a `JSPromise`,
/// compiles perfectly and then throws at run time in a browser only. Neither
/// `flutter analyze` nor `flutter build web` catches it, and the VM suite
/// cannot run this code at all.
///
/// The engine itself is verified separately: by
/// `tesseract_ffi_recognizer_test.dart` on the VM, and by driving the built
/// web app in a real browser — see `design/m6_platform_research.md`.
void main() {
  /// Installs a stand-in for the object `web/tesseract/fantastic_ocr.js`
  /// creates. Same three members, same shapes.
  void installStub({
    required bool available,
    String text = '',
    bool warmUp = true,
  }) {
    final stub = JSObject();
    stub.setProperty('available'.toJS, (() => available).toJS);
    stub.setProperty(
      'recognise'.toJS,
      ((JSString src) => Future.value('$text|${src.toDart}'.toJS).toJS).toJS,
    );
    stub.setProperty(
      'warmUp'.toJS,
      (() => Future.value(warmUp.toJS).toJS).toJS,
    );
    globalContext.setProperty('fantasticOcr'.toJS, stub);
  }

  void removeStub() =>
      globalContext.setProperty('fantasticOcr'.toJS, null.jsify());

  tearDown(removeStub);

  group('TesseractJsTextRecognizer', () {
    test('reports availability from the page', () {
      installStub(available: true);
      expect(const TesseractJsTextRecognizer().isAvailable, isTrue);

      installStub(available: false);
      expect(const TesseractJsTextRecognizer().isAvailable, isFalse);
    });

    test('is unavailable when the script never loaded', () {
      removeStub();

      // The failure mode this guards: a deploy missing `web/tesseract/`. A
      // missing global must read as "unavailable", not as a NoSuchMethodError
      // painted across the lens tab.
      expect(const TesseractJsTextRecognizer().isAvailable, isFalse);
    });

    test('passes the image source through and returns the text', () async {
      installStub(available: true, text: 'שומנים 53.8 גרם');

      // The argument really does reach JS, and Hebrew really does survive the
      // round trip in both directions — the stub echoes the source back.
      final text = await const TesseractJsTextRecognizer().recognise(
        'blob:http://localhost/abc',
      );

      expect(text, 'שומנים 53.8 גרם|blob:http://localhost/abc');
    });

    test('throws rather than returning empty text when unavailable', () async {
      removeStub();

      // An empty string is indistinguishable from a blank photo and would be
      // rendered as "we read the label and found nothing". The interface
      // requires a throw here for exactly that reason.
      await expectLater(
        const TesseractJsTextRecognizer().recognise('blob:x'),
        throwsA(isA<TextRecognitionUnavailableException>()),
      );
    });

    test('warmUp reports failure instead of throwing', () async {
      removeStub();

      // Best effort by contract: a failed warm-up is not a failed scan, and
      // a screen that calls it must not have to guard it.
      expect(await const TesseractJsTextRecognizer().warmUp(), isFalse);

      installStub(available: true);
      expect(await const TesseractJsTextRecognizer().warmUp(), isTrue);
    });
  });
}
