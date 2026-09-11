/// Why an estimate did not produce macros.
///
/// Seven values rather than one `failed`, because each wants different Hebrew
/// copy and a different button: "turn it on in settings" and "you are offline"
/// are not the same problem. `ScanFailureReason` established that the copy is
/// chosen per reason rather than written generically.
enum EstimateFailureReason {
  /// The user submitted nothing to estimate from.
  emptyInput,

  /// Estimation is off, or no API key has been entered.
  notConfigured,

  /// The request could not reach the provider.
  offline,

  /// The provider refused on quota — the free tier is 50 requests/day.
  rateLimited,

  /// The provider rejected the key.
  unauthorised,

  /// A response arrived but was not usable: unparseable, or carrying numbers
  /// that failed validation.
  badResponse,

  /// A well-formed response that named no food at all.
  nothingIdentified,
}
