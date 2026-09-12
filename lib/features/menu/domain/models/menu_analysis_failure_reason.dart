/// Why a menu analysis did not reach a verdict.
///
/// Nine values rather than one `failed`: each wants different Hebrew copy and
/// a different way out — "paste the text instead" and "you are offline" are
/// not the same problem. `ScanFailureReason` and `EstimateFailureReason`
/// established the same convention for their own engines.
enum MenuAnalysisFailureReason {
  /// Neither text nor a photo was submitted; the button should have been
  /// disabled.
  emptyInput,

  /// This build cannot run OCR at all — the browser has no viable engine.
  /// Not worth retrying; paste text instead.
  ocrUnavailable,

  /// OCR ran on every page and read nothing from any of them.
  noTextFound,

  /// Menu analysis is off, or no API key has been entered.
  notConfigured,

  /// The request could not reach the provider.
  offline,

  /// The provider refused on quota.
  rateLimited,

  /// The provider rejected the key.
  unauthorised,

  /// A response arrived but was not usable: unparseable, or it failed every
  /// parser rule.
  badResponse,

  /// A well-formed response that named no dish at all.
  noDishesFound;

  /// Whether a retry with the same input can succeed.
  bool get isRetryable => this == offline || this == badResponse;
}
