import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'package:fantastic/features/keto_lens/data/adapters/tessdata_bundle.dart';
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

  /// Candidate library names, most specific first.
  ///
  /// Versioned sonames come first so a system with both 5 and a stale 4
  /// resolves to 5. The unversioned name is the fallback a dev install or a
  /// Homebrew prefix usually provides.
  static List<String> get _candidates {
    if (Platform.isWindows) {
      return const [
        // Verified on a windows-latest runner against the chocolatey
        // `tesseract` package (5.5.3, an MSYS2 build): this is the name it
        // installs into C:\Program Files\Tesseract-OCR, which the installer
        // puts on PATH — and a bare name is what LoadLibrary resolves there.
        'libtesseract-5.dll',
        'tesseract55.dll',
        'libtesseract.dll',
      ];
    }
    if (Platform.isMacOS) {
      return const [
        'libtesseract.5.dylib',
        'libtesseract.dylib',
        '/opt/homebrew/lib/libtesseract.dylib',
        '/usr/local/lib/libtesseract.dylib',
      ];
    }
    return const ['libtesseract.so.5', 'libtesseract.so.4', 'libtesseract.so'];
  }

  /// Leptonica, which owns image decoding. Tesseract's own `SetImage2` takes a
  /// `Pix*`, so reading a PNG or JPEG means calling `pixRead` here first.
  static List<String> get _leptCandidates {
    if (Platform.isWindows) {
      return const [
        // Verified on a windows-latest runner, and the reason this list is not
        // a guess any more. The tesseract name above happened to be right;
        // every Leptonica name here was wrong — the chocolatey package ships
        // `libleptonica-6.dll`, matching the `.so.6` soname the Linux branch
        // below already knew about, not the `liblept-5` shape this list had.
        // Nothing in the app would have crashed: the probe simply returns
        // false and the lens tab says "install Tesseract" on a machine where
        // it *is* installed.
        'libleptonica-6.dll',
        'liblept-5.dll',
        'libleptonica.dll',
        'liblept.dll',
      ];
    }
    if (Platform.isMacOS) {
      return const [
        'liblept.5.dylib',
        'libleptonica.dylib',
        '/opt/homebrew/lib/libleptonica.dylib',
        '/usr/local/lib/libleptonica.dylib',
      ];
    }
    return const ['liblept.so.5', 'libleptonica.so.6', 'liblept.so'];
  }

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
    final tess = _tryOpenAny(_candidates);
    if (tess == null) return false;
    return _tryOpenAny(_leptCandidates) != null;
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
    TesseractFfiRecognizer._candidates,
  );
  final lept = TesseractFfiRecognizer._tryOpenAny(
    TesseractFfiRecognizer._leptCandidates,
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
  final init3 = tess
      .lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>),
        int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>)
      >('TessBaseAPIInit3');
  final setPageSegMode = tess
      .lookupFunction<
        Void Function(Pointer<Void>, Int32),
        void Function(Pointer<Void>, int)
      >('TessBaseAPISetPageSegMode');
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
  // `psm 6` - assume a single uniform block of text. A nutrition panel is one
  // block; the default (3, fully automatic) hunts for page columns that are
  // not there and interleaves the rows.
  //
  // `preserve_interword_spaces` is deliberately NOT set. It reads like the
  // safer choice and is, for Latin - but on RTL Hebrew it *removes* spaces
  // instead of preserving them: "53.8 גרם" comes back as "53.8גרם". Measured
  // here and in the browser, same result both times.

  try {
    if (init3(handle, dataPathPtr, languagePtr) != 0) {
      // Non-zero means the model was not loadable - a truncated asset, or a
      // datapath Tesseract could not read.
      throw const TextRecognitionUnavailableException(
        'The Hebrew language model could not be loaded.',
      );
    }
    setPageSegMode(handle, 6);

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
