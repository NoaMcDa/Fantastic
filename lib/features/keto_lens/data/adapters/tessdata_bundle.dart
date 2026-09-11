import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

/// Unpacks the bundled Hebrew model to a directory libtesseract can read.
///
/// Tesseract loads its language model from a *directory path*, not from bytes,
/// so an asset compiled into the app binary is not directly usable — it has to
/// land on a filesystem first. This copies it once per install and hands back
/// the containing directory.
///
/// The model ships with the app rather than being read from a system
/// `tessdata` directory on purpose: the app then depends on the host only for
/// the *library*, not for the user having run `apt install tesseract-ocr-heb`.
/// It is `tessdata_fast/heb.traineddata` — 961 KB, the integer model. The
/// float model in `tessdata_best` is 3.5 MB for accuracy nobody here has
/// measured; see `design/m6_platform_research.md` Part 6.
///
/// Desktop only. On Android the plugin does its own asset copy; on iOS it
/// reads a `tessdata` folder reference copied into the `.app` by
/// `ios/Runner.xcodeproj` instead. The browser fetches
/// `web/tesseract/heb.traineddata` over same-origin HTTP.
abstract final class TessdataBundle {
  /// Where the asset lives in the bundle.
  static const String assetKey = 'assets/tessdata/heb.traineddata';

  /// The language Tesseract is initialised with.
  static const String language = 'heb';

  static Future<String>? _pending;

  /// The directory holding `heb.traineddata`, unpacking it if needed.
  ///
  /// Concurrent callers share one unpack: the future is cached rather than the
  /// result, so two scans started together cannot both write the file.
  static Future<String> directory() => _pending ??= _unpack();

  static Future<String> _unpack() async {
    // `Directory.systemTemp` rather than `path_provider`: CLAUDE.md's layer
    // rules name path_provider as something only the database firewall may
    // import, and a re-extractable copy of a read-only model has no business
    // in the documents directory anyway.
    final dir = Directory('${Directory.systemTemp.path}/fantastic_tessdata');
    final file = File('${dir.path}/$language.traineddata');

    final data = await rootBundle.load(assetKey);
    final expected = data.lengthInBytes;

    // Re-copy when the size does not match, which is what an interrupted
    // first run or a model swap in a later release looks like. A truncated
    // traineddata does not fail loudly — Tesseract returns empty text.
    if (!file.existsSync() || await file.length() != expected) {
      await dir.create(recursive: true);

      // Write to a private name, then rename. `rename` is atomic within a
      // filesystem, so a reader either sees the previous file or the complete
      // new one, never a half-written one.
      //
      // The in-process `_pending` future serialises callers inside one app,
      // but not across processes — two instances, or two parallel test
      // suites, share this directory. That is not hypothetical: it produced
      // exactly one unreproducible OCR failure during development, which is
      // the worst way for a race to announce itself.
      final staging = File(
        '${file.path}.${pid}_${DateTime.now().microsecondsSinceEpoch}',
      );
      try {
        await staging.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, expected),
          flush: true,
        );
        await staging.rename(file.path);
      } on Object {
        // Losing the race is not an error: whoever won wrote the same bytes.
        if (staging.existsSync()) {
          await staging.delete();
        }
        rethrow;
      }
    }
    return dir.path;
  }

  /// Forgets the cached unpack. Tests only.
  static void reset() => _pending = null;
}
