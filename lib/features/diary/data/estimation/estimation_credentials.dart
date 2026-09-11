import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/domain/repositories/estimation_settings_repository.dart';

/// Where the token for an estimation request comes from.
///
/// The second thing that changes when the destination does, and the reason it
/// is an interface rather than a `String` parameter on
/// [LlmChatClient.complete]: today it is the user's own key out of the
/// settings store; later it is whatever a session with our own backend looks
/// like. Retrofitting that would touch every call site; declaring it now
/// costs one file.
abstract interface class EstimationCredentials {
  /// The bearer token to send, or null when estimation is not configured.
  ///
  /// **Never throws.** A storage failure resolves to null, which the layer
  /// above already reports as "not configured".
  Future<String?> token();
}

/// BYOK: the key the user entered, if they have also accepted the disclosure.
class UserApiKeyCredentials implements EstimationCredentials {
  const UserApiKeyCredentials(this.repository);

  final EstimationSettingsRepository repository;

  @override
  Future<String?> token() async {
    try {
      final settings = await repository.load();
      // `isEnabled` is the one place the key-plus-consent rule is asked, and
      // asking it here means no caller can forget it: a key without accepted
      // consent is a user who has not been told what leaves their device, and
      // is not a usable credential.
      return settings.isEnabled ? settings.apiKey : null;
    } on PersistenceException catch (_) {
      // **The one place in this stack that swallows a storage failure, and it
      // is right here.** "The settings could not be read" and "there are no
      // settings" are the same thing to a caller that is about to report
      // `notConfigured` — and the alternative, a network layer that throws
      // because a local store is broken, is a worse lie.
      return null;
    }
  }
}
