import 'dart:io';

/// The dynamic-library names `TesseractFfiRecognizer` tries, in order.
///
/// These live apart from the recogniser for one reason: **a list only the app
/// can see is a list nothing can check.** The macOS and Windows entries were
/// written without a host to try them on, so the names were a guess until
/// something opened them. `tool/tesseract_dylib_probe.dart` does exactly that,
/// and it can only import this file — the recogniser drags in
/// `package:flutter/services.dart` through `TessdataBundle`, which a plain
/// `dart run` cannot compile.
///
/// Keeping one source of truth is the whole point. A probe with its own copy
/// of the list proves the copy, not the app.
abstract final class TesseractLibraryCandidates {
  /// libtesseract, most specific first.
  ///
  /// Versioned sonames come first so a system with both 5 and a stale 4
  /// resolves to 5. The unversioned name is the fallback a dev install or a
  /// Homebrew prefix usually provides.
  ///
  /// **The absolute paths are not redundant on macOS.** dyld resolves a bare
  /// leaf name against `DYLD_FALLBACK_LIBRARY_PATH`, which is
  /// `~/lib:/usr/local/lib:/usr/lib` — so an Intel Homebrew prefix is found by
  /// name and an Apple-silicon one, at `/opt/homebrew`, never is.
  static List<String> get tesseract {
    if (Platform.isWindows) {
      return const [
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
  static List<String> get leptonica {
    if (Platform.isWindows) {
      return const ['liblept-5.dll', 'leptonica-1.84.1.dll', 'liblept.dll'];
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
}
