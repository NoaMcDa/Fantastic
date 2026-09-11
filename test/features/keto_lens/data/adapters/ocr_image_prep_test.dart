import 'package:fantastic/features/keto_lens/data/adapters/ocr_image_prep.dart';
import 'package:flutter_test/flutter_test.dart';

/// The image-normalisation rule both halves of the OCR firewall obey.
///
/// Pure arithmetic, so this needs no engine, no image and no platform. What it
/// is really guarding is the pair of properties that make the rule safe rather
/// than merely helpful: **a small image is grown, and no image — however
/// large — can produce an unbounded allocation.**
void main() {
  group('scaleFactor', () {
    test('grows the crop that produced the bug toward the target width', () {
      // The user's label: 580x498. Left alone, Tesseract read six of its nine
      // rows as punctuation.
      final factor = OcrImagePrep.scaleFactor(width: 580, height: 498);

      expect(factor, closeTo(OcrImagePrep.targetWidth / 580, 0.0001));
      expect((580 * factor).round(), OcrImagePrep.targetWidth);
    });

    test('leaves an image that is already wide enough completely alone', () {
      // 1240 px is the width of the rendered fixtures. Measuring showed
      // resampling these *costs* accuracy — the pointed label loses a second
      // macro — so the gate must not fire for them.
      expect(OcrImagePrep.scaleFactor(width: 1240, height: 660), 1);
      expect(OcrImagePrep.needsResize(width: 1240, height: 660), isFalse);
    });

    test('the gate is exclusive at minWidth', () {
      expect(
        OcrImagePrep.scaleFactor(width: OcrImagePrep.minWidth, height: 800),
        1,
      );
      expect(
        OcrImagePrep.scaleFactor(width: OcrImagePrep.minWidth - 1, height: 800),
        greaterThan(1),
      );
    });

    test('never enlarges a thumbnail beyond maxUpscale', () {
      // targetWidth / 80 is 20x. A 20x thumbnail is a large blurry thumbnail,
      // and 20x the pixels of an allocation nobody budgeted for.
      final factor = OcrImagePrep.scaleFactor(width: 80, height: 60);

      expect(factor, OcrImagePrep.maxUpscale);
    });
  });

  group('the caps are a memory guard', () {
    test('a 12 MP phone photo passes through untouched', () {
      // The coordinator's case, and the one that matters most: a constant
      // multiplier applied here would be 12000x16000 — roughly 700 MB of RGBA,
      // allocated on a phone. The rule must not resize this at all.
      expect(OcrImagePrep.scaleFactor(width: 3024, height: 4032), 1);
      expect(OcrImagePrep.needsResize(width: 3024, height: 4032), isFalse);

      // And in portrait or landscape alike.
      expect(OcrImagePrep.scaleFactor(width: 4032, height: 3024), 1);
    });

    test('an oversized scan is brought back under maxEdge', () {
      final factor = OcrImagePrep.scaleFactor(width: 9000, height: 12000);

      expect(factor, lessThan(1));
      expect((12000 * factor).round(), lessThanOrEqualTo(OcrImagePrep.maxEdge));
    });

    test('no input can exceed either cap', () {
      // Sweep the shapes a picker can hand over — tiny, huge, and extreme
      // aspect ratios in both orientations — and assert the invariant the
      // caps exist for, rather than one example of it.
      const sizes = <List<int>>[
        [1, 1],
        [80, 60],
        [580, 498],
        [1024, 768],
        [1240, 660],
        [3024, 4032],
        [4032, 3024],
        [9000, 12000],
        [30000, 100],
        [100, 30000],
        [16384, 16384],
      ];

      for (final size in sizes) {
        final w = size[0];
        final h = size[1];
        final factor = OcrImagePrep.scaleFactor(width: w, height: h);

        expect(factor, greaterThan(0), reason: '$size produced $factor');
        expect(factor.isFinite, isTrue, reason: '$size produced $factor');

        final outW = w * factor;
        final outH = h * factor;
        expect(
          outW > outH ? outW : outH,
          lessThanOrEqualTo(OcrImagePrep.maxEdge + 1),
          reason: '$size exceeded maxEdge',
        );
        expect(
          outW * outH,
          lessThanOrEqualTo(OcrImagePrep.maxPixels + 1),
          reason: '$size exceeded maxPixels',
        );
      }
    });

    test('a degenerate size from a corrupt header is a no-op, not a crash', () {
      expect(OcrImagePrep.scaleFactor(width: 0, height: 0), 1);
      expect(OcrImagePrep.scaleFactor(width: -5, height: 100), 1);
      expect(OcrImagePrep.scaleFactor(width: 100, height: 0), 1);
    });
  });

  test('the declared DPI is a real value, not a sentinel', () {
    // Tesseract estimated 631 dpi on the image that produced this bug and
    // downscaled internally on the strength of it. Any sane declared value
    // beats that; 0 or a negative would be read as "no value" and bring the
    // estimate back.
    expect(OcrImagePrep.assumedDpi, greaterThan(0));
  });
}
