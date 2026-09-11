import 'dart:math' as math;

/// How an image is normalised before Tesseract sees it.
///
/// Pure Dart — no `dart:io`, no `package:image`, no plugin type — so both
/// halves of the OCR firewall can agree on one rule and a unit test can check
/// it without decoding anything. The browser half re-states these same numbers
/// in `web/tesseract/fantastic_ocr.js`, because JavaScript cannot import a
/// Dart constant; [assumedDpi], [minWidth] and [targetWidth] are the three
/// values that must stay in step, and a comment there says so.
///
/// ## Why this exists at all
///
/// The bug that produced it: a user scanned a 580x498 crop of a real Israeli
/// nutrition panel and the app reported `ScanFailed(notALabel)`. Tesseract had
/// returned six of the nine rows as punctuation rubble. Measured on
/// `tesseract 5.3.4` against the model this app bundles, two separate
/// properties of that image were responsible, and neither is a parser problem:
///
/// * **It is small.** A nutrition row was about 20 px tall; the LSTM wants
///   roughly 30-35 px of x-height. Scaled toward [targetWidth] the same image
///   reads perfectly.
/// * **Tesseract guessed its resolution, and guessed extravagantly wrong.**
///   With no DPI in the file it logged `Estimating resolution as 631` and
///   then *downscaled* internally on the strength of that estimate, which is
///   what destroyed the rows. Declaring [assumedDpi] stops the guess.
///
/// Both are needed. The same 580 px image at [targetWidth] with no declared
/// DPI still fails; at its original size with a declared DPI it *mostly*
/// works and drops a value. Together every macro on the label comes back
/// exactly right.
///
/// ## Why small images are grown but adequate ones are left alone
///
/// [minWidth] is a gate, not a target. Resampling costs detail, and measuring
/// it showed the cost is real: the project's pointed-niqqud fixture reads
/// correctly at its native 1240 px and loses a *second* macro when scaled up
/// to 1600 px for no reason. So an image that is already wide enough to read
/// is passed through untouched, and only something clearly too small is
/// resampled — up to [targetWidth], never past [maxUpscale], because a
/// 120 px thumbnail enlarged sixteen-fold is a large blurry thumbnail.
///
/// Width is the proxy for glyph size rather than height or the long edge: a
/// nutrition row is a roughly fixed number of characters, so how wide the
/// panel is tracks how big its text is. That holds for a cropped panel and
/// overestimates for a panel photographed small inside a large frame, which is
/// the known limit of doing this without layout analysis.
///
/// ## The caps are a memory guard, not a tuning knob
///
/// [maxEdge] and [maxPixels] exist so no input can provoke an unbounded
/// allocation — a scale factor applied blindly to a 3024x4032 phone photo is
/// hundreds of megabytes of pixel buffer, on mobile, and that is a hang rather
/// than a bad read. They are deliberately set *above* what a phone camera
/// produces: a 12 MP photo passes through with no resize at all. Nothing here
/// has been tuned on a real camera photo, because there is no camera in this
/// repository, so the caps do not try to improve one — they only refuse to
/// explode on one.
abstract final class OcrImagePrep {
  const OcrImagePrep._();

  /// Below this width an image is treated as too small to read reliably.
  static const int minWidth = 1100;

  /// What a too-small image is grown toward.
  static const int targetWidth = 1600;

  /// The largest enlargement allowed, whatever [targetWidth] would ask for.
  static const double maxUpscale = 4;

  /// Neither output edge may exceed this. Memory guard only.
  static const int maxEdge = 4500;

  /// Nor may the output exceed this many pixels. Memory guard only.
  static const int maxPixels = 20000000;

  /// The resolution Tesseract is told to assume, via `user_defined_dpi`.
  ///
  /// Any sane value beats letting it estimate, and 300 is the conventional
  /// scanned-document figure. It is *declared*, not measured: the app has no
  /// idea what the real optical resolution was, and neither does Tesseract —
  /// the difference is that a declared value is stable and an estimated one
  /// swung to 631 on the image that produced this bug.
  static const int assumedDpi = 300;

  /// The factor to multiply [width] and [height] by before recognition.
  ///
  /// Returns exactly `1` when the image should be handed to the engine
  /// untouched, which callers use to skip decoding and re-encoding entirely.
  /// Never returns zero, a negative, or a non-finite value, including for the
  /// degenerate sizes a corrupt header can report.
  static double scaleFactor({required int width, required int height}) {
    if (width <= 0 || height <= 0) {
      return 1;
    }

    // Grow only what is under the gate. Anything already legible keeps every
    // pixel it was given.
    var factor = width >= minWidth
        ? 1.0
        : math.min(targetWidth / width, maxUpscale);

    // From here down the clamps only ever shrink, and they apply to images
    // that were never enlarged too — an 8000 px scan is capped on its own
    // merits.
    final longestEdge = math.max(width, height);
    if (longestEdge * factor > maxEdge) {
      factor = maxEdge / longestEdge;
    }

    if (width * factor * (height * factor) > maxPixels) {
      factor = math.sqrt(maxPixels / (width * height));
    }

    // A clamp can only have lowered the factor, so an image that started
    // above the caps lands on them rather than being enlarged into them.
    return factor <= 0 || !factor.isFinite ? 1 : factor;
  }

  /// Whether [scaleFactor] would change anything for an image this size.
  static bool needsResize({required int width, required int height}) =>
      scaleFactor(width: width, height: height) != 1;
}
