/// Where the bearer token for an [LlmChatClient] request comes from.
///
/// **Provider-neutral, on purpose.** This lives in `lib/core/`, which must
/// not know what "estimation" is or which feature is asking — that is why
/// the interface is named for what it does (hand back a token) rather than
/// for the feature that today happens to be its only caller. The concrete
/// [UserApiKeyCredentials] implementation stays in the diary feature, where
/// it can read `EstimationSettingsRepository` without pulling a feature
/// dependency into core.
///
/// The second thing that changes when the destination does, and the reason
/// it is an interface rather than a `String` parameter on
/// [LlmChatClient.complete]: today it is the user's own key out of the
/// settings store; later it is whatever a session with our own backend looks
/// like. Retrofitting that would touch every call site; declaring it now
/// costs one file.
abstract interface class LlmCredentials {
  /// The bearer token to send, or null when no credential is configured.
  ///
  /// **Never throws.** A storage failure resolves to null, which the layer
  /// above already reports as "not configured".
  Future<String?> token();
}
