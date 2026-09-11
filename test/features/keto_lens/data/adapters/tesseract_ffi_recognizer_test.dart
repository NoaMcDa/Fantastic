@TestOn('vm')
library;

import 'package:fantastic/features/keto_lens/data/adapters/tesseract_ffi_recognizer.dart';
import 'package:flutter_test/flutter_test.dart';

/// The desktop recogniser, running a real OCR engine against a real image.
///
/// The only test in this repository that executes an OCR engine. Everything
/// else in `keto_lens/` stubs the recogniser, which is what makes the rest of
/// the pipeline testable anywhere — but it also means that until this file
/// existed, **nothing verified that the engine reads Hebrew at all.** That gap
/// is what `design/m6_handoff.md` called the project's largest unverified
/// claim, and M6 shipped with it open because ML Kit had no Hebrew model to
/// verify.
///
/// ## Why it skips instead of failing
///
/// libtesseract is a system library, not a bundled one. CI runners do not have
/// it, and neither will most contributors. A test that failed there would
/// train people to ignore a red suite; one that skips says plainly what is not
/// being checked. `isAvailable` is exactly the right condition, because it is
/// the same probe the app itself uses to decide whether to offer a scan.
///
/// Install it to run these:
///
/// ```
/// sudo apt-get install libtesseract-dev libleptonica-dev   # Debian/Ubuntu
/// brew install tesseract leptonica                          # macOS
/// ```
///
/// The Hebrew model is **not** a prerequisite: the app bundles its own and
/// [TessdataBundle] unpacks it, so a system with libtesseract but no
/// `tesseract-ocr-heb` still passes.
void main() {
  const recognizer = TesseractFfiRecognizer();
  final available = recognizer.isAvailable;

  group('TesseractFfiRecognizer', () {
    // `rootBundle` needs a binding: the model is an asset, and reading it is
    // half of what this test covers.
    TestWidgetsFlutterBinding.ensureInitialized();

    test('reads a Hebrew nutrition label', () async {
      final text = await recognizer.recognise(
        'test/fixtures/images/tahini_label.png',
      );

      // Asserting on substrings rather than the whole string on purpose. The
      // exact output depends on the engine version, and pinning it would make
      // a Tesseract upgrade look like a regression. What must hold is that the
      // three macro keywords and their numbers are readable — everything
      // downstream is built on exactly that.
      expect(text, contains('שומנים'));
      expect(text, contains('53.8'));
      expect(text, contains('פחמימות'));
      expect(text, contains('10.5'));
      expect(text, contains('חלבונים'));
      expect(text, contains('26.5'));
    }, skip: available ? false : 'libtesseract is not installed');

    test('keeps the space between a number and its unit', () async {
      final text = await recognizer.recognise(
        'test/fixtures/images/tahini_label.png',
      );

      // A regression guard for a real defect. Setting
      // `preserve_interword_spaces=1` — which the Tesseract documentation
      // makes sound like the safe choice, and which an earlier draft of this
      // adapter did set — *removes* spaces on RTL Hebrew: "53.8 גרם" comes
      // back as "53.8גרם" and "משומשום מלא" as "משומשוםמלא". Measured on this
      // engine and on the wasm build in a browser, same result both times.
      expect(text, contains('53.8 גרם'));
      expect(text, isNot(contains('53.8גרם')));
    }, skip: available ? false : 'libtesseract is not installed');

    test(
      'reports an unreadable file as a failure, not as empty text',
      () async {
        // Empty text would reach the user as "we read the label and found
        // nothing", which is a different and wrong thing to say. The
        // orchestrator turns a throw into ScanFailed.recognitionFailed.
        await expectLater(
          recognizer.recognise('test/fixtures/images/does_not_exist.png'),
          throwsA(isA<Exception>()),
        );
      },
      skip: available ? false : 'libtesseract is not installed',
    );
  });
}
