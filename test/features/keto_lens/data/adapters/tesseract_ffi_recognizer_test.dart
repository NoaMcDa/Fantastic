@TestOn('vm')
library;

import 'package:fantastic/features/keto_lens/data/adapters/scaling_text_recognizer.dart';
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

  // A skip is silent by design, and silence is the wrong default *here*.
  //
  // This is the only test in the repository that runs an OCR engine, so it is
  // the only one that can observe what the engine actually reads. Everything
  // else stubs the recogniser. When it skips — which it does on CI, and on
  // any machine without libtesseract — a fully green suite says nothing
  // whatever about whether desktop or mobile OCR works.
  //
  // That is not hypothetical. A change that left the prepared image in colour
  // made Tesseract drop every digit on a label while keeping every Hebrew
  // row, and the suite stayed green because these tests skipped. The
  // pure-Dart guards in `scaling_text_recognizer_test.dart` now cover that
  // specific shape, but they assert the *buffer*, not the reading, and no
  // amount of them substitutes for running an engine.
  //
  // So say so, loudly, in the output of every run that does not run one.
  if (!available) {
    // ignore: avoid_print
    print(
      '\n'
      '  ==========================================================\n'
      '  NATIVE OCR NOT EXERCISED — libtesseract is not installed.\n'
      '\n'
      '  Every test in tesseract_ffi_recognizer_test.dart is being\n'
      '  SKIPPED. A green run therefore proves NOTHING about\n'
      '  desktop or mobile text recognition: not the page-seg mode,\n'
      '  not the language pair, not user_defined_dpi, and not the\n'
      '  image preparation step.\n'
      '\n'
      '  To actually check them:\n'
      '    sudo apt-get install libtesseract-dev libleptonica-dev\n'
      '    brew install tesseract leptonica\n'
      '  ==========================================================\n',
    );
  }

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

  group('ScalingTextRecognizer over a real engine', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    // The whole native stack as the app assembles it: the scaling decorator
    // wrapping the FFI binding, over a real libtesseract, on the real label a
    // user could not scan. This is the only test that exercises the
    // preprocessing step, the two-model unpack, `psm 4` and
    // `user_defined_dpi` together — every other test stubs one of them.
    const wrapped = ScalingTextRecognizer(TesseractFfiRecognizer());

    test('reads the bordered two-column label that used to fail', () async {
      final text = await wrapped.recognise(
        'test/fixtures/images/whole_wheat_rye_bread_label.png',
      );

      // Substrings, not the whole string, for the reason the tahini test
      // gives: pinning exact output turns a Tesseract upgrade into a
      // regression. What must hold is that each row arrives with its own
      // number — which is exactly what `psm 6` destroyed.
      expect(text, contains('חלבונים'));
      expect(text, contains('10.9'));
      expect(text, contains('פחמימות'));
      expect(text, contains('41.2'));
      expect(text, contains('שומנים'));
      expect(text, contains('3.3'));
      expect(text, contains('נתרן'));
      expect(text, contains('368'));
    }, skip: available ? false : 'libtesseract is not installed');

    test('the serving-basis header survives with its geresh', () async {
      final text = await wrapped.recognise(
        'test/fixtures/images/whole_wheat_rye_bread_label.png',
      );

      // `ערך תזונתי ל-100 גר' מוצר`. Two ways this has been seen to break:
      // the old settings read `100` as `106`, and `tessdata_best/heb` drops
      // the geresh and returns a bare `גר`. Either one leaves
      // `HebrewLabelParser._basisPer100g` unmatched, the basis `unknown`, and
      // the per-100 g figures unscaled — which is what #257 was.
      expect(text, contains('100'));
      expect(RegExp("100\\s*גר").hasMatch(text), isTrue);
    }, skip: available ? false : 'libtesseract is not installed');

    test('delegates availability rather than deciding for itself', () {
      expect(wrapped.isAvailable, recognizer.isAvailable);
    });
  });
}
