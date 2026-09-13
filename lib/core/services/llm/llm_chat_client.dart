import 'package:meta/meta.dart';

/// One chat-completion round trip to whatever model provider is configured.
///
/// **An interface, not a class, because the destination is already known to be
/// temporary.** M15 ships each user calling a hosted provider with their own
/// key; the plan is to call our own backend later. That swap must be a *new
/// implementation of this interface and nothing else* — no change to the
/// estimator, the prompt, the parser or any widget. Epic #312's OCP
/// invariant.
///
/// The boundary where bytes leave the device gets a class of its own rather
/// than a `post` buried inside an estimator: it is the app's first outbound
/// network call, and the one place worth being able to point at.
abstract interface class LlmChatClient {
  /// Sends one prompt and returns the assistant's message content.
  ///
  /// **Never throws.** Every transport and provider failure comes back as a
  /// value, so no caller needs a `try`/`catch` to stay correct. That is a
  /// contract the implementation is tested against, not a hope.
  ///
  /// **Takes no auth argument, deliberately.** A caller does not pass a key
  /// because a caller must not know there is one — that is what makes the
  /// backend swap invisible above this line. The implementation asks its own
  /// [LlmCredentials].
  Future<ChatResult> complete({
    required String systemPrompt,
    required String userPrompt,
    String? imageBase64,
    String? imageMediaType,

    /// Upper bound on the reply. Null lets the provider choose — right for a
    /// short meal estimate, wrong for a 60-dish menu.
    int? maxOutputTokens,

    /// A JSON Schema the reply should conform to. Sent as a structured-output
    /// request where the provider supports it; where the provider refuses
    /// that request **the implementation falls back to a plain JSON-object
    /// request on its own** rather than reporting a failure, so a caller
    /// never learns whether the schema was enforced and must parse
    /// defensively regardless.
    Map<String, Object?>? responseSchema,
  });
}

/// What one round trip produced.
///
/// Sealed for the same reason `ScanResult` is: a failure must not be
/// expressible as a degenerate success. A scan that could not be read is not
/// Clean Keto, and a request that was refused is not an empty answer.
@immutable
sealed class ChatResult {
  const ChatResult();
}

/// The model answered.
@immutable
final class ChatSucceeded extends ChatResult {
  const ChatSucceeded(this.content);

  /// The assistant message's text, guaranteed non-empty.
  final String content;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatSucceeded && other.content == content;

  @override
  int get hashCode => content.hashCode;

  @override
  String toString() => 'ChatSucceeded(${content.length} chars)';
}

/// The round trip did not produce an answer.
@immutable
final class ChatFailed extends ChatResult {
  const ChatFailed(this.reason, {this.statusCode});

  final ChatFailureReason reason;

  /// The HTTP status the provider answered with, when it answered at all.
  ///
  /// Null for a failure that never got a status: no credential, no route,
  /// a timeout. **A status code is the one piece of detail safe to carry**:
  /// it cannot echo a header or a body, and it is what tells a 404 (a
  /// retired model id) from a 400 (a request shape refused) from a 200
  /// whose content was unusable — three failures that all read
  /// [ChatFailureReason.badResponse] and each need a different fix.
  /// `design/m16_structured_output_fix.md` records a whole round trip with
  /// the user that this field would have made unnecessary.
  final int? statusCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatFailed &&
          other.reason == reason &&
          other.statusCode == statusCode;

  @override
  int get hashCode => Object.hash(reason, statusCode);

  /// **Carries no body and no header, and that is the point.** An upstream
  /// error body can echo a request header, and this value is the one thing
  /// that crosses into a layer that might log it. The status code is a
  /// number the provider chose, never text it or we wrote.
  @override
  String toString() => statusCode == null
      ? 'ChatFailed(${reason.name})'
      : 'ChatFailed(${reason.name}, http $statusCode)';
}

/// Why a round trip produced no answer.
///
/// **Provider-agnostic on purpose.** Every one of these is a state any hosted
/// model provider can put us in, our own backend included — which is what
/// lets the layer above tell a user what happened without ever learning who
/// was called.
enum ChatFailureReason {
  /// No route to the host: no connection, DNS failure, a dropped socket.
  offline,

  /// The request was abandoned before an answer arrived.
  ///
  /// A hung call is worse than a failed one — the sheet above would spin, and
  /// `design/m6_handoff.md` records what an indeterminate spinner costs.
  timeout,

  /// No usable credential, or the provider rejected the one sent.
  unauthorised,

  /// A quota was exhausted.
  ///
  /// Distinct from [unauthorised] because the words in front of the user are
  /// different: one is "check your key", the other is "try again tomorrow".
  rateLimited,

  /// The provider answered, and the answer was not one we can use.
  badResponse,
}
