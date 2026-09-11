import 'package:meta/meta.dart';

/// Whether macro estimation is configured, and with whose key.
///
/// Two pieces of state that only mean something together: a key without
/// accepted consent is a user who has not been told what leaves their device,
/// and consent without a key cannot make a call.
///
/// **Deliberately not fields on `UserProfile`.** `design/m4_handoff.md` records
/// that the *existence* of the profile record is the app's first-launch
/// sentinel — `main` reads it synchronously to decide whether the onboarding
/// gate opens. Writing an API key into it would fabricate a profile, skip
/// onboarding, and leave the user with default macro targets they never chose.
@immutable
class EstimationSettings {
  const EstimationSettings({this.apiKey, this.consentAccepted = false});

  /// The user's own provider key, or null when none has been entered.
  ///
  /// Null rather than an empty string, so "not set" has one representation.
  final String? apiKey;

  /// Whether the user has accepted the disclosure describing what is sent and
  /// to whom. Estimation stays off until they have.
  final bool consentAccepted;

  /// Whether an estimate may be attempted at all.
  ///
  /// The one place that question is asked. Both halves are required, and an
  /// empty key counts as no key.
  bool get isEnabled => (apiKey?.isNotEmpty ?? false) && consentAccepted;

  EstimationSettings copyWith({String? apiKey, bool? consentAccepted}) =>
      EstimationSettings(
        apiKey: apiKey ?? this.apiKey,
        consentAccepted: consentAccepted ?? this.consentAccepted,
      );

  /// Clears the key, leaving consent as it was.
  ///
  /// `copyWith` cannot express this: `null` there means "unchanged", which is
  /// the convention every model in this repo follows and which
  /// `design/m3_handoff.md` records the cost of breaking. A second method is
  /// the deliberate answer rather than a special case inside the first.
  EstimationSettings withoutApiKey() =>
      EstimationSettings(consentAccepted: consentAccepted);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstimationSettings &&
          other.apiKey == apiKey &&
          other.consentAccepted == consentAccepted;

  @override
  int get hashCode => Object.hash(apiKey, consentAccepted);

  /// Deliberately does not include [apiKey].
  ///
  /// Epic #312's invariant: no API key is logged, printed, or included in any
  /// exception or failure value — and a `toString` is how a key reaches a log
  /// without anyone deciding to put it there.
  @override
  String toString() =>
      'EstimationSettings(apiKey: ${apiKey == null ? 'none' : 'set'}, '
      'consentAccepted: $consentAccepted)';
}
