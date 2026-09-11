@TestOn('vm')
library;

import 'dart:io';

import 'package:fantastic/features/keto_lens/data/adapters/ocr_image_prep.dart';
import 'package:fantastic/features/keto_lens/data/adapters/scaling_text_recognizer.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// What the engine is actually handed, asserted without an engine.
///
/// **This file exists because of a specific near-miss.** The first version of
/// the preparation step resized the image but left it in colour, and every
/// number on the label vanished while every Hebrew row survived — the quietest
/// possible failure, in the one place this app must not be quiet. Nothing in
/// the suite caught it, because the only test that runs a real engine skips
/// wherever libtesseract is absent, which includes CI.
///
/// So these assertions deliberately describe the *buffer*, not the reading:
/// its size, and above all its channel count. They need no OCR, they run
/// everywhere, and they would have failed on that regression immediately.
void main() {
  const label = 'test/fixtures/images/whole_wheat_rye_bread_label.png';

  img.Image sourceImage() => img.decodeImage(File(label).readAsBytesSync())!;

  group('prepare', () {
    test(
      'the committed label is still the small colour image this assumes',
      () {
        // Guards the premise of every other test here. If someone re-exports
        // this fixture as a large or greyscale PNG, the tests below would keep
        // passing while testing nothing.
        final source = sourceImage();

        expect(source.width, 580);
        expect(source.height, 498);
        expect(source.numChannels, greaterThan(1));
      },
    );

    test('hands the engine a single-channel buffer', () {
      // **The regression guard.** Measured against real libtesseract on this
      // exact label, varying only the channel count:
      //
      //   4 channels (RGBA, as decoded) -> not one number read
      //   3 channels (alpha flattened)  -> not one number read
      //   1 channel  (grayscale)        -> every number read
      //
      // Note what that rules out: dropping the alpha channel is *not* the
      // fix — three-channel colour fails just as completely — so an
      // "optimisation" that flattens to RGB instead would reintroduce the bug
      // whole. Only 1 is correct.
      final prepared = ScalingTextRecognizer.prepare(sourceImage());

      expect(prepared, isNotNull);
      expect(
        prepared!.numChannels,
        1,
        reason: 'colour input makes Tesseract drop every digit on the label',
      );
    });

    test('scales the label to the target width', () {
      final prepared = ScalingTextRecognizer.prepare(sourceImage())!;

      expect(prepared.width, OcrImagePrep.targetWidth);
      // Aspect ratio preserved, so the table does not shear.
      expect(prepared.height / prepared.width, closeTo(498 / 580, 0.005));
    });

    test('returns null for an image that is already big enough', () {
      // Null is the signal to skip the re-encode and pass the original path
      // through — the common case for a camera photo.
      final big = img.Image(width: 3024, height: 4032);

      expect(ScalingTextRecognizer.prepare(big), isNull);
    });

    test('never returns a buffer past the caps', () {
      // The memory guard, asserted on a real allocation rather than on
      // arithmetic. Kept modest in pixel terms so the test stays cheap.
      final wide = img.Image(width: 200, height: 9000);
      final prepared = ScalingTextRecognizer.prepare(wide);

      if (prepared != null) {
        expect(prepared.width, lessThanOrEqualTo(OcrImagePrep.maxEdge));
        expect(prepared.height, lessThanOrEqualTo(OcrImagePrep.maxEdge));
        expect(
          prepared.width * prepared.height,
          lessThanOrEqualTo(OcrImagePrep.maxPixels),
        );
      }
    });
  });

  group('the decorator itself', () {
    test('delegates availability rather than answering for the binding', () {
      // The lens tab asks this before offering a camera button. A wrapper
      // that answered `true` over an unavailable engine would offer a scan
      // that cannot work.
      expect(const ScalingTextRecognizer(_Unavailable()).isAvailable, isFalse);
      expect(const ScalingTextRecognizer(_Available()).isAvailable, isTrue);
    });

    test('passes a path through to the binding and returns its text', () async {
      const inner = _Available();
      final text = await const ScalingTextRecognizer(inner).recognise(label);

      expect(text, 'recognised');
    });

    test('a binding failure is not swallowed by the wrapper', () async {
      // The orchestrator turns a throw into ScanFailed.recognitionFailed.
      // Swallowing it here and returning empty text would reach the user as
      // "we read the label and found nothing", which is a different and
      // wrong thing to say.
      await expectLater(
        const ScalingTextRecognizer(_Throwing()).recognise(label),
        throwsA(isA<Exception>()),
      );
    });
  });
}

class _Available implements TextRecognitionService {
  const _Available();

  @override
  bool get isAvailable => true;

  @override
  Future<String> recognise(String imagePath) async => 'recognised';
}

class _Unavailable implements TextRecognitionService {
  const _Unavailable();

  @override
  bool get isAvailable => false;

  @override
  Future<String> recognise(String imagePath) async => '';
}

class _Throwing implements TextRecognitionService {
  const _Throwing();

  @override
  bool get isAvailable => true;

  @override
  Future<String> recognise(String imagePath) async =>
      throw const FormatException('the engine failed');
}
