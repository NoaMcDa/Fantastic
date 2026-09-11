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
  for (final name in candidates) {
    try {
      DynamicLibrary.open(name);
      opened++;
      stdout.writeln('  [open] $label <- $name');
    } on Object catch (error) {
      stdout.writeln('  [miss] $label <- $name  ($error)');
    }
  }
  stdout.writeln('$label: $opened of ${candidates.length} candidates opened');
  return opened > 0;
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
