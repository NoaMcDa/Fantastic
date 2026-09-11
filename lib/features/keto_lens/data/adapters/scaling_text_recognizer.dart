import 'dart:io';
import 'dart:isolate';

import 'package:image/image.dart' as img;

import 'package:fantastic/features/keto_lens/data/adapters/ocr_image_prep.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';

/// Normalises an image's size, then hands it to the real recogniser.
///
/// A decorator rather than a step inside either native adapter, because both
/// native adapters need it and they have nothing else in common: the mobile
/// half talks to a plugin over a method channel and the desktop half calls
/// libtesseract over FFI. Wrapping them once in
/// `createTextRecognitionService()` is what makes Android, iOS, Linux, macOS
/// and Windows share one rule — and leaves each adapter as the thin binding it
/// is supposed to be.
///
/// The browser is *not* wrapped by this. `package:image` would work there, but
/// the web half never has a file path to decode — `image_picker_for_web` hands
/// Dart a `blob:` URL — so the browser does the same normalisation with a
/// canvas, in `web/tesseract/fantastic_ocr.js`. [OcrImagePrep] holds the
/// numbers both sides use.
///
/// ## Why the work is in an isolate
///
/// Decoding a 12 MP JPEG and resampling it is hundreds of milliseconds of
/// pure CPU. On the platform thread that is dropped frames at best, and on a
/// mid-range Android device holding a camera preview it is visible as a
/// freeze. `Isolate.run` moves the whole decode-resize-encode off it. Only
/// two strings cross the boundary, so nothing here needs to be sendable
/// beyond a path.
///
/// ## Failure is never fatal
///
/// If anything in preparation goes wrong — an unsupported codec, a corrupt
/// header, a read-only temp directory — the original path is used unchanged.
/// A scan that might have read better is strictly better than a scan that
/// did not happen, and the engine gets its own chance to fail honestly into
/// `ScanFailed`.
class ScalingTextRecognizer implements TextRecognitionService {
  const ScalingTextRecognizer(this.inner);

  /// The binding that does the actual recognition.
  ///
  /// Public for the reason `ScanOrchestrator` records: Dart forbids a named
  /// parameter starting with an underscore, so a private field cannot use an
  /// initializing formal. It is an interface; nothing leaks.
  final TextRecognitionService inner;

  @override
  bool get isAvailable => inner.isAvailable;

  @override
  Future<String> recognise(String imagePath) async {
    final prepared = await _prepare(imagePath);
    try {
      return await inner.recognise(prepared ?? imagePath);
    } finally {
      if (prepared != null) {
        // Best effort: a leftover file in the temp directory is not worth
        // failing a scan the user already has the answer to.
        try {
          await File(prepared).delete();
        } on Object {
          // Ignored deliberately.
        }
      }
    }
  }

  /// The image Tesseract should actually see, or null to use the original.
  ///
  /// Pure — no file, no isolate, no engine — so the properties that make it
  /// correct can be asserted on a machine with no libtesseract. That matters
  /// more here than it looks: the first version of this method returned a
  /// *colour* image, every number on the label vanished, and nothing in the
  /// suite could tell, because the only test that runs an engine skips on CI.
  ///
  /// ## Grayscale is not a nicety, it is the whole fix
  ///
  /// Measured against real libtesseract on the label that produced this bug,
  /// scaled to the same size with the same interpolation, varying only the
  /// channels:
  ///
  /// | channels | numbers read |
  /// |---|---|
  /// | 4 (RGBA, as decoded) | **none of them** |
  /// | 3 (alpha flattened)  | **none of them** |
  /// | 1 (grayscale)        | all of them |
  ///
  /// Every Hebrew *row* survived in all three; only the digits disappeared,
  /// which is the failure mode this feature least tolerates and the hardest
  /// to notice. Note that dropping the alpha channel is **not** what fixes
  /// it — three-channel colour fails just as completely. Tesseract converts
  /// internally either way, so this is about handing it the buffer it is
  /// going to use rather than about it being unable to cope.
  ///
  /// Converting first and resizing second, rather than the reverse, is also
  /// deliberate: it is a quarter of the pixel buffer to resample, on a step
  /// that exists partly to bound memory.
  static img.Image? prepare(img.Image source) {
    final factor = OcrImagePrep.scaleFactor(
      width: source.width,
      height: source.height,
    );
    if (factor == 1) {
      return null;
    }

    return img.copyResize(
      // `numChannels: 1` rather than `img.grayscale`, which keeps four
      // channels and merely equalises three of them.
      source.convert(numChannels: 1),
      width: (source.width * factor).round(),
      height: (source.height * factor).round(),
      // Not the default nearest-neighbour, which stair-steps stroke edges -
      // precisely the detail the LSTM reads. Which of the smooth kernels,
      // though, was measured rather than reasoned, and the measurement is
      // not comfortable reading. Sweeping interpolation against target width
      // on the label that produced this bug, scoring by what
      // `HebrewLabelParser` extracts:
      //
      //            1200  1400  1600  1800  2000  2400
      //   cubic     ok    -p    -p    -p    xx    fat=0.5
      //   linear    -p    ok    ok    xx    xx    fat=53.0
      //   average   ok    -f-p  ok    -c-p  xx    fat=9.0
      //
      // `linear` is chosen because it is the only kernel correct at two
      // *adjacent* widths, which is the nearest thing to a stable plateau on
      // offer. Read the right-hand columns as the warning they are: at other
      // settings the engine returns a *plausible wrong* fat figure - 0.5 is
      // the saturated-fat sub-row, 53.0 is nothing on the label at all -
      // rather than failing visibly.
      //
      // This is a 580x498 image at the edge of what the engine can do, and
      // these numbers say the margin is thin. They are not evidence that
      // linear/1600 is right in general; they are evidence that it is right
      // here. A real camera photo has several times the detail and none of
      // this brittleness is expected to apply to it - which is itself
      // unverified, because there is no camera in this repository.
      interpolation: img.Interpolation.linear,
    );
  }

  /// The path of a prepared copy, or null to use the original.
  ///
  /// Null covers both "no work was needed" and "it was attempted and did not
  /// work", because the caller does the same thing in both cases.
  static Future<String?> _prepare(String imagePath) async {
    try {
      final target =
          '${Directory.systemTemp.path}/fantastic_ocr_'
          '${pid}_${DateTime.now().microsecondsSinceEpoch}.png';
      return await Isolate.run(() => _resizeSync(imagePath, target));
    } on Object {
      return null;
    }
  }
}

/// Decodes [source], prepares it if [OcrImagePrep] says so, writes [target].
///
/// Top-level so `Isolate.run` closes over two strings rather than an instance.
/// Returns null when the image is already a workable size, which is the
/// common case for a photograph and skips the re-encode entirely.
String? _resizeSync(String source, String target) {
  final bytes = File(source).readAsBytesSync();

  // `decodeImage` sniffs the format, so a JPEG from a camera, a PNG from a
  // screenshot and a HEIC-transcoded pick all arrive the same way.
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return null;
  }

  final prepared = ScalingTextRecognizer.prepare(decoded);
  if (prepared == null) {
    return null;
  }

  // PNG, not JPEG: this file exists only to be read back by Tesseract
  // moments later, and JPEG ringing around high-contrast glyph edges is a
  // recognition cost paid for a disk saving nobody needs.
  File(target).writeAsBytesSync(img.encodePng(prepared));
  return target;
}
