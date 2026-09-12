import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/core/services/llm/llm_credentials.dart';
import 'package:fantastic/features/diary/domain/repositories/estimation_settings_repository.dart';

/// BYOK: the key the user entered, if they have also accepted the disclosure.
///
/// The concrete piece of [LlmCredentials] that knows what "estimation
/// settings" are — which is exactly why it stays in the diary feature rather
/// than moving to `lib/core/` with the interface it implements: `core` must
/// not import a feature's domain repository.
class UserApiKeyCredentials implements LlmCredentials {
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
