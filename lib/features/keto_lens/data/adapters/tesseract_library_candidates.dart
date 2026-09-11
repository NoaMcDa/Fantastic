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
  /// **The absolute paths are not redundant on macOS, they are the only ones
  /// that work.** Measured on an Apple-silicon runner with Homebrew tesseract
  /// 5.5.3 installed: of the four original candidates exactly one opened,
  /// `/opt/homebrew/lib/libtesseract.dylib`. dyld resolves a bare leaf name
  /// against `DYLD_FALLBACK_LIBRARY_PATH` — `~/lib:/usr/local/lib:/usr/lib` —
  /// which does not contain `/opt/homebrew`, so every unqualified name misses.
  ///
  /// The versioned absolute paths were added afterwards for the same reason the
  /// versioned sonames exist on Linux: the one entry that worked is an
  /// unversioned symlink, and a list with a single point of failure is a list
  /// one `brew` layout change away from reporting "Tesseract is not installed"
  /// on a machine where it is. `libtesseract.5.dylib` is the real file behind
  /// that symlink.
  static List<String> get tesseract {
    if (Platform.isWindows) {
      return const [
        // Measured on a windows-latest runner with the chocolatey `tesseract`
        // package (5.5.3, an MSYS2 build): this is the name it installs into
        // C:\Program Files\Tesseract-OCR, which the installer puts on PATH,
        // and a bare name is what LoadLibrary resolves there. The name is
        // right — the file is found and loaded.
        //
        // It still does not open *on that runner*: `error code: 127`,
        // ERROR_PROC_NOT_FOUND, meaning one of its own imports resolved to a
        // different copy of an MSYS2 runtime DLL earlier on a PATH carrying
        // several MinGW-ish toolchains. An absolute path fails identically,
        // and that is expected — Dart calls plain `LoadLibraryW`, so a
        // library's own directory gets no priority when its dependencies are
        // resolved. Leptonica, next door and built the same way, opens fine.
        // So Windows OCR is unproven on a machine where Tesseract is the only
        // MinGW runtime, and no such machine exists in this project.
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
        '/opt/homebrew/lib/libtesseract.5.dylib',
        '/usr/local/lib/libtesseract.dylib',
        '/usr/local/lib/libtesseract.5.dylib',
      ];
    }
    return const ['libtesseract.so.5', 'libtesseract.so.4', 'libtesseract.so'];
  }

  /// Leptonica, which owns image decoding. Tesseract's own `SetImage2` takes a
  /// `Pix*`, so reading a PNG or JPEG means calling `pixRead` here first.
  ///
  /// Same measurement, same answer: only
  /// `/opt/homebrew/lib/libleptonica.dylib` opened. Note that the versioned
  /// file Homebrew 1.87.0 installs is `libleptonica.6.dylib` and **not**
  /// `liblept.5.dylib` — that spelling is a Linux-era name kept only because an
  /// older formula used it, and a miss costs one failed `dlopen`.
  static List<String> get leptonica {
    if (Platform.isWindows) {
      return const [
        // The same measurement, and the same answer it gave on macOS: the
        // Linux-era `liblept-5` spelling is wrong here too. The chocolatey
        // package ships `libleptonica-6.dll`, matching the `.so.6` soname the
        // Linux branch below already knew about — and not one of the three
        // names originally guessed for Windows existed at all.
        //
        // Nothing would have crashed. `isAvailable` returns false when either
        // library fails to open, so the lens tab would have told a Windows
        // user with Tesseract correctly installed to go and install
        // Tesseract — the one piece of advice the probe exists to avoid.
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
        '/opt/homebrew/lib/libleptonica.6.dylib',
        '/usr/local/lib/libleptonica.dylib',
        '/usr/local/lib/libleptonica.6.dylib',
      ];
    }
    return const ['liblept.so.5', 'libleptonica.so.6', 'liblept.so'];
  }
}
