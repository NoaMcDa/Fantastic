// Opens every candidate in `TesseractLibraryCandidates` and says which ones
// resolved, then checks that `Directory.systemTemp` is writable.
//
// It exists because the macOS and Windows entries in that list were written
// blind — no host existed to try them on — and a name that never resolves is
// indistinguishable, from inside the app, from Tesseract not being installed.
// `.github/workflows/build-macos.yml` runs this after `brew install tesseract
// leptonica`, which turns the list from a guess into a fact.
//
// It imports `TesseractLibraryCandidates` and nothing else from the app on
// purpose: that keeps it free of `package:flutter`, so it runs under a plain
// `dart run`/`dart compile exe` and can be codesigned with the App Sandbox
// entitlement to answer the second question — whether a *sandboxed* macOS
// build can reach a Homebrew dylib at all.
//
// Exit code 0 means at least one candidate opened for each library and the
// temp directory is writable. Anything else is 1.
import 'dart:ffi';
import 'dart:io';

import 'package:fantastic/features/keto_lens/data/adapters/tesseract_library_candidates.dart';

void main(List<String> args) {
  stdout.writeln('platform: ${Platform.operatingSystem} ${Platform.version}');

  final tesseract = _probe(
    'libtesseract',
    TesseractLibraryCandidates.tesseract,
  );
  final leptonica = _probe('leptonica', TesseractLibraryCandidates.leptonica);
  final temp = _probeSystemTemp();

  final ok = tesseract && leptonica && temp;
  stdout.writeln(ok ? 'PROBE: ok' : 'PROBE: failed');
  if (!ok) exitCode = 1;
}

/// Tries every [candidates] entry and reports each one individually.
///
/// Reporting per-candidate rather than just "it worked" is the point: the app
/// stops at the first one that opens, so without this a list where only the
/// last entry is correct looks exactly like a list where all four are.
bool _probe(String label, List<String> candidates) {
  var opened = 0;
  var present = 0;
  for (final name in candidates) {
    try {
      DynamicLibrary.open(name);
      opened++;
      present++;
      stdout.writeln('  [open] $label <- $name');
    } on Object catch (error) {
      // Windows distinguishes two failures that every other platform, and the
      // app itself, collapse into one "it did not open".
      //
      //   126, ERROR_MOD_NOT_FOUND  - no such file. THE NAME IS WRONG, which
      //                               is the bug this probe exists to catch.
      //   127, ERROR_PROC_NOT_FOUND - the file was found and loaded, and one
      //                               of *its own* imports resolved to some
      //                               other DLL earlier on PATH. The name is
      //                               right; the machine's DLL environment is
      //                               not, and no list of names can fix that.
      //
      // Measured on a windows-latest runner with chocolatey tesseract 5.5.3:
      // run from PowerShell both libraries open, and run from Git Bash
      // `libtesseract-5.dll` returns 127 — Git for Windows puts its own MSYS2
      // `bin` directories ahead on PATH and libtesseract's imports bind
      // there. Same machine, same names, different answer, so failing the
      // probe for 127 would be reporting the caller's shell as a defect in
      // the list.
      if ('$error'.contains('error code: 127')) {
        present++;
        stdout.writeln('  [deps] $label <- $name  (name resolves; $error)');
      } else {
        stdout.writeln('  [miss] $label <- $name  ($error)');
      }
    }
  }
  stdout.writeln(
    '$label: $opened of ${candidates.length} candidates opened, '
    '$present named a file that exists',
  );
  return present > 0;
}

/// `TessdataBundle` unpacks the Hebrew model under [Directory.systemTemp].
///
/// Under the macOS App Sandbox that path is redirected into the app's own
/// container rather than being denied, so this should hold there too — but
/// "should" is what this file exists to replace.
bool _probeSystemTemp() {
  final dir = Directory('${Directory.systemTemp.path}/fantastic_probe');
  try {
    dir.createSync(recursive: true);
    final file = File('${dir.path}/probe.bin')..writeAsBytesSync(const [1, 2]);
    final size = file.lengthSync();
    file.deleteSync();
    dir.deleteSync();
    stdout.writeln(
      'systemTemp: writable at ${Directory.systemTemp.path} '
      '(wrote $size bytes)',
    );
    return true;
  } on Object catch (error) {
    stdout.writeln(
      'systemTemp: NOT writable at ${Directory.systemTemp.path} '
      '($error)',
    );
    return false;
  }
}
