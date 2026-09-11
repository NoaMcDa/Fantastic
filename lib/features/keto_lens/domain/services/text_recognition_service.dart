/// On-device OCR for a captured label photo.
///
/// ## Why the boundary type is a `String`, not an `InputImage`
///
/// `InputImage` is an ML Kit type. Putting it in this signature — as #83's
/// `ScanOrchestrator` did — would drag a native-only plugin into `domain/`
/// and `application/`, which `CLAUDE.md`'s layer rules forbid outright, and
/// would make both untestable without the plugin. A file path costs nothing
/// and keeps the whole pipeline above `data/` in plain Dart.
///
/// ## Why [isAvailable] exists
///
/// There is no on-device Hebrew OCR for Flutter web. ML Kit is a native-only
/// plugin, and the browser-shaped alternative is a network call — which
/// `CLAUDE.md`'s OCR section and Epic #10's first architectural invariant
/// both rule out. So the web build gets an implementation that answers
/// `false` here and throws [TextRecognitionUnavailableException] if called
/// anyway, and the UI asks *before* it offers a camera button rather than
/// after it has failed.
///
/// See `design/m6_preflight.md` Part 0 for how that was established, and for
/// why the platform split is a conditional export rather than a `kIsWeb`
/// branch: a runtime check still links the plugin into every target.
abstract interface class TextRecognitionService {
  /// Whether OCR can run on this platform at all.
  ///
  /// A compile-time fact, not a permission or a device capability — it is
  /// the same answer for every launch of a given build.
  bool get isAvailable;

  /// Recognises the text in the image at [imagePath].
  ///
  /// Returns the full recognised text, or an empty string when the image
  /// holds none. Throws [TextRecognitionUnavailableException] when
  /// [isAvailable] is false, and lets any platform failure propagate —
  /// `ScanOrchestrator` is the layer that decides what a failed scan looks
  /// like, and it cannot do that if the failure has already been swallowed.
  Future<String> recognise(String imagePath);
}

/// Thrown when OCR is asked for on a platform that cannot run it.
///
/// Distinct from a scan that ran and found nothing: this one is not worth
/// retrying, and the UI should not offer to.
class TextRecognitionUnavailableException implements Exception {
  const TextRecognitionUnavailableException(this.reason);

  /// Why OCR is unavailable, in English, for a log or a bug report.
  final String reason;

  @override
  String toString() => 'TextRecognitionUnavailableException: $reason';
}
