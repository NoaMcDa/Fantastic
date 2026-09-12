import 'package:fantastic/core/error/repository_exception.dart';
import 'package:fantastic/features/diary/data/estimation/user_api_key_credentials.dart';
import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';
import 'package:fantastic/features/diary/domain/repositories/estimation_settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements EstimationSettingsRepository {}

void main() {
  late _MockRepository repository;
  late UserApiKeyCredentials credentials;

  setUp(() {
    repository = _MockRepository();
    credentials = UserApiKeyCredentials(repository);
  });

  void stub(EstimationSettings settings) =>
      when(repository.load).thenAnswer((_) async => settings);

  test('returns the stored key when it is enabled', () async {
    stub(const EstimationSettings(apiKey: 'sk-abc', consentAccepted: true));

    expect(await credentials.token(), 'sk-abc');
  });

  // A key without accepted consent is a user who has not been told what
  // leaves their device. Asked here, so no caller can forget it.
  test(
    'returns null when consent is not accepted, even with a key stored',
    () async {
      stub(const EstimationSettings(apiKey: 'sk-abc'));

      expect(await credentials.token(), isNull);
    },
  );

  test('returns null when consent is accepted but no key is stored', () async {
    stub(const EstimationSettings(consentAccepted: true));

    expect(await credentials.token(), isNull);
  });

  test('an empty key is no key', () async {
    stub(const EstimationSettings(apiKey: '', consentAccepted: true));

    expect(await credentials.token(), isNull);
  });

  test('returns null on fresh defaults', () async {
    stub(const EstimationSettings());

    expect(await credentials.token(), isNull);
  });

  // The one place in this stack that swallows a storage failure, and it is
  // right: "the settings could not be read" and "there are no settings" are
  // the same thing to a caller about to report `notConfigured`. A network
  // layer that threw because a local store was broken would be a worse lie.
  test('a PersistenceException resolves to null, not a throw', () async {
    when(repository.load)
        .thenThrow(const PersistenceException('load failed', 'store closed'));

    expect(await credentials.token(), isNull);
  });
}
