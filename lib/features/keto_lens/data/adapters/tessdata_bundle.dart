import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;

/// Unpacks the bundled Hebrew model to a directory libtesseract can read.
///
/// Tesseract loads its language model from a *directory path*, not from bytes,
/// so an asset compiled into the app binary is not directly usable — it has to
/// land on a filesystem first. This copies it once per install and hands back
/// the containing directory.
///
/// The models ship with the app rather than being read from a system
/// `tessdata` directory on purpose: the app then depends on the host only for
/// the *library*, not for the user having run `apt install tesseract-ocr-heb`.
/// Both are `tessdata_fast` — the integer models — at 961 KB for Hebrew and
/// 4.0 MB for English.
///
/// ## Why English is loaded alongside Hebrew
///
/// The Hebrew model cannot reliably read a column of bare Latin digits. On a
/// real Israeli nutrition panel whose numbers sit in their own table column
/// with no Hebrew beside them, `heb` alone returned 218 / 9 / 2 / 43 / 9 / 308
/// where the label printed 238 / 10.9 / 41.2 / 7 / 3.3 / 368 — and it was no
/// better at 4x or 6x the resolution, so this is not a sharpness problem.
/// `tessdata_best/heb` (3.7 MB) was measured too and is also wrong, and it
/// additionally drops the geresh in `גר'`, which would break serving-basis
/// detection. Loading `eng` beside `heb` returns every figure exactly.
///
/// **It is a trade, not a free win, and the cost is recorded rather than
/// hidden.** On *pointed* (niqqud) Hebrew the English model sometimes wins a
/// word it should not: the project's `pointedWafer` fixture loses its
/// carbohydrate row. That degradation is to `null` — "not found" — which
/// `ParsedLabel` documents and which makes the sheet ask the user rather than
/// state a figure. The alternative, a second `heb`-only pass to fill the gap,
/// was considered and rejected: it would fill a safe null from a pass measured
/// to be unreliable on digits, turning "the app asks" into "the app guesses",
/// which is the exact direction #257 exists to prevent.
///
/// See `design/m6_platform_research.md` Part 6.
///
/// Desktop only. On Android the plugin does its own asset copy; on iOS it
/// reads a `tessdata` folder reference copied into the `.app` by
/// `ios/Runner.xcodeproj` instead. The browser fetches
/// `web/tesseract/heb.traineddata` over same-origin HTTP.
abstract final class TessdataBundle {
  /// Where the Hebrew asset lives in the bundle.
  static const String assetKey = 'assets/tessdata/heb.traineddata';

  /// Every model that has to be on disk before Tesseract is initialised.
  ///
  /// Keyed by the language code, because that is also the file's stem — the
  /// engine looks for `<code>.traineddata` in its datapath, so the two cannot
  /// drift apart.
  static const Map<String, String> assetKeys = {
    'heb': assetKey,
    'eng': 'assets/tessdata/eng.traineddata',
  };

  /// The language string Tesseract is initialised with.
  ///
  /// `heb+eng`, and the order matters: the first is the primary script. See
  /// the class doc for why English is here and what it costs.
  static const String language = 'heb+eng';

  static Future<String>? _pending;

  /// The directory holding the models, unpacking them if needed.
  ///
  /// Concurrent callers share one unpack: the future is cached rather than the
  /// result, so two scans started together cannot both write the files.
  static Future<String> directory() => _pending ??= _unpack();

  static Future<String> _unpack() async {
    // `Directory.systemTemp` rather than `path_provider`: CLAUDE.md's layer
    // rules name path_provider as something only the database firewall may
    // import, and a re-extractable copy of a read-only model has no business
    // in the documents directory anyway.
    final dir = Directory('${Directory.systemTemp.path}/fantastic_tessdata');

    // Every model into the same directory: Tesseract takes one datapath and
    // resolves each language in `heb+eng` against it, so a model that lands
    // anywhere else is a model it cannot find.
    for (final entry in assetKeys.entries) {
      await _unpackOne(dir, entry.key, entry.value);
    }
    return dir.path;
  }

  static Future<String> _unpackOne(
    Directory dir,
    String language,
    String assetKey,
  ) async {
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
    return file.path;
  }

  /// Forgets the cached unpack. Tests only.
  static void reset() => _pending = null;
}
