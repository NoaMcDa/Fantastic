import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// How a meal photograph is normalised before it leaves the device.
///
/// Pure and synchronous, so every branch is unit-testable from a generated
/// bitmap with no file system, no camera and no network — which matters more
/// here than almost anywhere else in the app, because nobody working on this
/// repository has a camera and branch coverage is the only assurance
/// available.
///
/// ## This is the opposite of `OcrImagePrep`, deliberately
///
/// `OcrImagePrep` scales an image **up**: Tesseract's LSTM wants roughly
/// 30-35 px of x-height and a small crop of a nutrition panel does not have
/// it. Here the job is the reverse. A model does not need a 12 MP plate to
/// name the food on it, so the only question is how far down it can come
/// before it stops being recognisable — and the answer chosen is
/// [maxEdge]. **Never upscale**: enlarging a thumbnail adds no information a
/// model can use and multiplies the bytes that get billed.
///
/// Confusing the two would be easy and expensive, which is why both say so.
///
/// ## Why a budget exists at all
///
/// A free OpenRouter key is 50 requests a day. A raw phone photo is several
/// megabytes, base64 inflates it by a third, and an oversized request spends
/// one of those 50 on bytes nobody reads — or fails outright after paying the
/// upload. [maxEncodedBytes] is the hard refusal: past it the estimate fails
/// locally rather than sending, because a bounded request is a testable one.
abstract final class MealPhotoPrep {
  const MealPhotoPrep._();

  /// Longest edge, in pixels, of the image actually sent.
  ///
  /// A model does not need a 12 MP plate to name the food on it, and a
  /// request that is megabytes large spends one of a free key's 50 daily
  /// calls on bytes nobody reads.
  static const int maxEdge = 1024;

  /// JPEG quality for the re-encode.
  ///
  /// A plate photo is a photograph: JPEG, not PNG, which would be several
  /// times larger for detail no estimate depends on.
  static const int jpegQuality = 80;

  /// Hard ceiling on the encoded payload.
  ///
  /// Above this the estimate fails rather than sending. [maxEdge] and
  /// [jpegQuality] together put a real photograph an order of magnitude under
  /// this, so reaching it means something pathological — a synthetic image of
  /// pure noise, say — and refusing is the right answer for those.
  static const int maxEncodedBytes = 3 * 1024 * 1024;

  /// The media type [prepare] always produces.
  ///
  /// A constant rather than a literal at the call site: the re-encode and the
  /// declared type are one decision, and they must not be able to drift.
  static const String mediaType = 'image/jpeg';

  /// Decodes, downscales to fit [maxEdge], re-encodes as JPEG and returns
  /// base64.
  ///
  /// Returns null when [bytes] are not a decodable image, or when the encoded
  /// result exceeds [maxEncodedBytes]. A null is a refusal to send, never an
  /// empty image: the caller reports it as a failure the user can act on by
  /// choosing another photo.
  static String? prepare(Uint8List bytes) {
    // `decodeImage` sniffs the format, so a JPEG from a camera, a PNG from a
    // screenshot and a HEIC already transcoded by the picker all arrive here
    // the same way.
    //
    // **It does not merely return null on rubbish.** Measured against
    // `image` 4.3: handed four bytes, its PSD sniffer reads a 16-bit field
    // past the end and throws `RangeError`; handed zero bytes the PNG sniffer
    // does the same. So the null contract this method advertises has to be
    // built here rather than assumed from the package.
    //
    // `Object`, not `Exception`: `RangeError` is an `Error`, and an
    // `on Exception` clause would let a truncated file take the sheet down —
    // the same trap `guardPersistence` documents for the data layer.
    final img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } on Object catch (_) {
      return null;
    }
    if (decoded == null) {
      return null;
    }

    final longest = decoded.width > decoded.height
        ? decoded.width
        : decoded.height;
    // **Only if it is too big.** An image already inside the budget is passed
    // through untouched; resampling it would cost detail and buy nothing.
    final resized = longest > maxEdge
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? maxEdge : null,
            height: decoded.height > decoded.width ? maxEdge : null,
            maintainAspect: true,
          )
        : decoded;

    final encoded = img.encodeJpg(resized, quality: jpegQuality);
    final base64 = base64Encode(encoded);
    // Measured on the base64, not on the JPEG: base64 is what crosses the
    // wire, and it is a third larger than what it wraps.
    return base64.length > maxEncodedBytes ? null : base64;
  }
}
