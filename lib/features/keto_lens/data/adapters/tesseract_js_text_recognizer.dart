import 'dart:js_interop';

import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';

/// The browser half of the OCR firewall — Hebrew OCR via tesseract.js.
///
/// Selected by `text_recognizer_factory.dart` on every target that is not a
/// VM. It replaced `UnavailableTextRecognizer` here when the engine changed:
/// M6 shipped with the lens inert in a browser because ML Kit is native-only
/// and "the browser alternative is a network call". Tesseract compiled to
/// WebAssembly is neither — it runs in a Web Worker, on the user's machine,
/// from assets served by this deploy — so the invariant survives and the tab
/// scans. See `design/m6_platform_research.md` Part 4.
///
/// **Imports nothing but `dart:js_interop`.** No plugin, no `dart:io`, and
/// nothing that would fail to compile for dart2js or wasm. `package:web` is
/// not needed either: the whole surface is three calls on one global object,
/// declared below.
///
/// The engine itself lives in `web/tesseract/`, behind
/// `web/tesseract/fantastic_ocr.js`, which is what keeps the tesseract.js API
/// out of Dart entirely. Everything it loads is same-origin; see that file
/// for why that is load-bearing rather than tidy.
class TesseractJsTextRecognizer implements TextRecognitionService {
  const TesseractJsTextRecognizer();

  /// Why OCR is unavailable when [isAvailable] is false.
  ///
  /// Reachable only when `tesseract/tesseract.min.js` did not load — a
  /// stripped deploy, or a proxy that ate the script tag. A browser that
  /// loaded the page normally never sees this.
  static const String reason =
      'The scanner did not load. Reload the page; if it keeps happening the '
      'app was deployed without its OCR assets.';

  /// Whether the tesseract.js bundle reached the page.
  ///
  /// Unlike the other implementations this is *not* a compile-time fact — it
  /// asks the page. It is still the same answer for every scan in a given
  /// session, which is what the interface's contract actually needs: the UI
  /// checks it once before offering a camera button.
  @override
  bool get isAvailable => _ocr?.available() ?? false;

  /// Recognises Hebrew text in the image at [imagePath].
  ///
  /// On web [imagePath] is a `blob:` URL rather than a filesystem path —
  /// `image_picker_for_web` and `camera_web` have no filesystem to hand back
  /// a path from. Keeping it a `String` either way is what lets the pipeline's
  /// boundary type stay identical on all six targets (M6 convention 2), and
  /// tesseract.js accepts a blob URL as an image source directly.
  ///
  /// The first call pays the model load — roughly a second — because the
  /// worker starts lazily. `warmUp` exists so a screen can pay it earlier.
  @override
  Future<String> recognise(String imagePath) async {
    final ocr = _ocr;
    if (ocr == null || !ocr.available()) {
      throw const TextRecognitionUnavailableException(reason);
    }
    return (await ocr.recognise(imagePath.toJS).toDart).toDart;
  }

  /// Loads the engine and the Hebrew model ahead of the first scan.
  ///
  /// Best effort: returns false rather than throwing, because a failed
  /// warm-up is not a failed scan — [recognise] starts the worker itself if
  /// this never ran or did not finish.
  Future<bool> warmUp() async {
    final ocr = _ocr;
    if (ocr == null || !ocr.available()) return false;
    return (await ocr.warmUp().toDart).toDart;
  }
}

/// The `window.fantasticOcr` object installed by `web/tesseract/fantastic_ocr.js`.
///
/// Null when the script did not load, which [TesseractJsTextRecognizer]
/// reports as unavailable rather than letting a `NoSuchMethodError` escape as
/// a red screen.
@JS('fantasticOcr')
external _FantasticOcr? get _ocr;

/// The glue object's three-call surface. Deliberately tiny: everything about
/// tesseract.js — worker lifecycle, core selection, page-segmentation mode —
/// is decided in JS, so changing the engine never touches Dart.
extension type _FantasticOcr._(JSObject _) implements JSObject {
  external bool available();
  external JSPromise<JSString> recognise(JSString src);
  external JSPromise<JSBoolean> warmUp();
}

/// Builds the recogniser for the browser.
///
/// The default half of `text_recognizer_factory.dart`.
TextRecognitionService createTextRecognitionService() =>
    const TesseractJsTextRecognizer();
