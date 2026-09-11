import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'package:fantastic/features/keto_lens/data/adapters/ocr_image_prep.dart';
import 'package:fantastic/features/keto_lens/data/adapters/tessdata_bundle.dart';
import 'package:fantastic/features/keto_lens/data/adapters/tesseract_library_candidates.dart';
import 'package:fantastic/features/keto_lens/domain/services/text_recognition_service.dart';

/// The desktop half of the OCR firewall — Hebrew OCR through libtesseract.
///
/// Linux, macOS and Windows share this one implementation because they share
/// one C API. It is the only recogniser in the project verified against a real
/// rendered Hebrew label in this repository; see
/// `design/m6_platform_research.md`.
///
/// ## Why FFI and not the CLI
///
/// `Process.run('tesseract', ...)` would be shorter, but it needs the binary on
/// `PATH`, pays a process spawn per scan, and moves the page-segmentation mode
/// into argv where a typo is a runtime surprise. The C API is three calls and
/// lets the recognised text come back without a round trip through stdout
/// decoding — which matters for Hebrew, where a mis-set console codepage on
/// Windows would corrupt it silently.
///
/// ## Why the work happens in an isolate
///
/// `TessBaseAPIGetUTF8Text` is a synchronous, CPU-bound call that takes on the
/// order of a second. Run on the platform thread it would freeze the frame
/// pump for that whole time. `Isolate.run` moves it off, and because every
/// handle is opened *inside* the isolate, no pointer ever crosses an isolate
/// boundary — only the four strings below go in and the recognised text comes
/// back.
class TesseractFfiRecognizer implements TextRecognitionService {
  const TesseractFfiRecognizer();

  /// Why OCR is unavailable when [isAvailable] is false.
  ///
  /// Names the fix, because on desktop it is a thing the user can actually do.
  /// Every other implementation's unavailable state is not user-fixable.
  static const String reason =
      'Tesseract is not installed on this computer. The scanner needs the '
      'Tesseract OCR library; install it and restart the app.';

  static bool? _probed;

  /// Whether libtesseract and leptonica can be opened on this machine.
  ///
  /// **This one is not a compile-time fact**, unlike the other
  /// implementations — the build supports OCR, the installed system may not.
  /// It is still stable for the life of the process, which is what the
  /// interface's contract needs: the UI asks once, before it offers a camera
  /// button, and gets an answer that will not change underneath it.
  ///
  /// Probing here rather than failing inside [recognise] is what lets the lens
  /// tab say "install Tesseract" instead of "scan failed, try again" — the
  /// second is advice the user cannot act on.
  @override
  bool get isAvailable => _probed ??= _canOpen();

  static bool _canOpen() {
    final tess = _tryOpenAny(TesseractLibraryCandidates.tesseract);
    if (tess == null) return false;
    return _tryOpenAny(TesseractLibraryCandidates.leptonica) != null;
  }

  static DynamicLibrary? _tryOpenAny(List<String> names) {
    for (final name in names) {
      try {
        return DynamicLibrary.open(name);
      } on Object {
        // Wrong name for this distro, or the library genuinely is not here.
        // Both are "try the next candidate", and only the last one is news.
        continue;
      }
    }
    return null;
  }

  @override
  Future<String> recognise(String imagePath) async {
    if (!isAvailable) {
      throw const TextRecognitionUnavailableException(reason);
    }
    final tessdata = await TessdataBundle.directory();
    return Isolate.run(
      () => _recogniseSync(
        imagePath: imagePath,
        tessdata: tessdata,
        language: TessdataBundle.language,
      ),
    );
  }
}

/// The whole FFI transaction, start to finish, inside one isolate.
///
/// Top-level rather than a method so `Isolate.run` can close over it without
/// capturing an instance. Every pointer is allocated, used and freed here.
String _recogniseSync({
  required String imagePath,
  required String tessdata,
  required String language,
}) {
  final tess = TesseractFfiRecognizer._tryOpenAny(
    TesseractLibraryCandidates.tesseract,
  );
  final lept = TesseractFfiRecognizer._tryOpenAny(
    TesseractLibraryCandidates.leptonica,
  );
  if (tess == null || lept == null) {
    throw const TextRecognitionUnavailableException(
      TesseractFfiRecognizer.reason,
    );
  }

  final create = tess
      .lookupFunction<Pointer<Void> Function(), Pointer<Void> Function()>(
        'TessBaseAPICreate',
      );
  // `Init2`, not `Init3`, for one reason: it takes the OCR engine mode.
  //
  // `Init3` uses `OEM_DEFAULT`, while the browser half pins `oem 1`
  // (LSTM_ONLY) in its `createWorker` call. Both bundled models are
  // LSTM-only — `combine_tessdata -d` lists components 17-23 and no legacy
  // ones — so `OEM_DEFAULT` resolves to the same engine today and this is not
  // the cause of any bug. It is a divergence waiting to become one: the day
  // someone swaps in a model that *does* carry legacy data, desktop silently
  // starts running a different engine from the browser. Pinning it on both
  // sides costs one argument.
  final init2 = tess
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Int32),
        int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, int)
      >('TessBaseAPIInit2');
  final setPageSegMode = tess
      .lookupFunction<
        Void Function(Pointer<Void>, Int32),
        void Function(Pointer<Void>, int)
      >('TessBaseAPISetPageSegMode');
  final setVariable = tess
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>),
        int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>)
      >('TessBaseAPISetVariable');
  final setImage2 = tess
      .lookupFunction<
        Void Function(Pointer<Void>, Pointer<Void>),
        void Function(Pointer<Void>, Pointer<Void>)
      >('TessBaseAPISetImage2');
  final getUtf8Text = tess
      .lookupFunction<
        Pointer<Utf8> Function(Pointer<Void>),
        Pointer<Utf8> Function(Pointer<Void>)
      >('TessBaseAPIGetUTF8Text');
  final apiDelete = tess
      .lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)
      >('TessBaseAPIDelete');
  final deleteText = tess
      .lookupFunction<
        Void Function(Pointer<Utf8>),
        void Function(Pointer<Utf8>)
      >('TessDeleteText');
  final pixRead = lept
      .lookupFunction<
        Pointer<Void> Function(Pointer<Utf8>),
        Pointer<Void> Function(Pointer<Utf8>)
      >('pixRead');

  final handle = create();
  if (handle == nullptr) {
    throw const TextRecognitionUnavailableException(
      TesseractFfiRecognizer.reason,
    );
  }

  final dataPathPtr = tessdata.toNativeUtf8();
  final languagePtr = language.toNativeUtf8();
  final imagePathPtr = imagePath.toNativeUtf8();
  Pointer<Utf8> textPtr = nullptr;
  // `psm 4` - a single column of text of variable sizes.
  //
  // This was `6` ("a single uniform block") until a user scanned a real
  // Israeli nutrition panel and the app read six of its nine rows as
  // punctuation rubble. A bordered table with its numbers in one column and
  // its Hebrew labels in another is precisely what mode 6 flattens - it
  // returned `%- |` and `|` where `פחמימות (גרם) 41.2` was printed - and mode
  // 4 keeps every row with its own number. Measured on tesseract 5.3.4
  // against the model this app bundles, and re-measured against all three
  // captured fixtures to confirm it changes none of them.
  //
  // `preserve_interword_spaces` is deliberately NOT set. It reads like the
  // safer choice and is, for Latin - but on RTL Hebrew it *removes* spaces
  // instead of preserving them: "53.8 גרם" comes back as "53.8גרם". Measured
  // here and in the browser, same result both times.

  try {
    // 1 = OEM_LSTM_ONLY. Matches `Tesseract.createWorker(LANG, 1, ...)` in
    // web/tesseract/fantastic_ocr.js and the `--oem 1` the fixture capture
    // script runs.
    if (init2(handle, dataPathPtr, languagePtr, 1) != 0) {
      // Non-zero means the model was not loadable - a truncated asset, or a
      // datapath Tesseract could not read.
      throw const TextRecognitionUnavailableException(
        'The Hebrew language model could not be loaded.',
      );
    }
    setPageSegMode(handle, 4);

    // Tesseract estimates the image's resolution when the file does not
    // declare one, and the estimate is not always sane: on the 580x498 crop
    // that produced this bug it logged "Estimating resolution as 631" and
    // then downscaled internally on the strength of that number, which is
    // what destroyed the rows. Declaring a value stops the guess. Failure is
    // ignored on purpose - an unknown variable name on some build of
    // libtesseract is not worth failing a scan over, and the engine simply
    // goes back to estimating.
    final dpiName = 'user_defined_dpi'.toNativeUtf8();
    final dpiValue = '${OcrImagePrep.assumedDpi}'.toNativeUtf8();
    try {
      setVariable(handle, dpiName, dpiValue);
    } finally {
      calloc
        ..free(dpiName)
        ..free(dpiValue);
    }

    final pix = pixRead(imagePathPtr);
    if (pix == nullptr) {
      // Leptonica could not decode the file. A real failure worth reporting as
      // one: ScanOrchestrator turns it into ScanFailed.recognitionFailed.
      throw const FormatException('The image could not be read.');
    }
    setImage2(handle, pix);
    textPtr = getUtf8Text(handle);
    return textPtr == nullptr ? '' : textPtr.toDartString();
  } finally {
    if (textPtr != nullptr) deleteText(textPtr);
    apiDelete(handle);
    calloc
      ..free(dataPathPtr)
      ..free(languagePtr)
      ..free(imagePathPtr);
  }
}
