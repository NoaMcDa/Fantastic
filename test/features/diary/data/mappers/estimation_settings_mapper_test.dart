import 'package:fantastic/features/diary/data/mappers/estimation_settings_mapper.dart';
import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('toRecord', () {
    test('emits a sembast-legal map', () {
      final record = EstimationSettingsMapper.toRecord(
        const EstimationSettings(apiKey: 'sk-test', consentAccepted: true),
      );

      expect(record['apiKey'], isA<String>());
      expect(record['consentAccepted'], isA<bool>());
    });

    test('a null key is written as null, not as an empty string', () {
      final record = EstimationSettingsMapper.toRecord(
        const EstimationSettings(),
      );

      expect(record['apiKey'], isNull);
    });
  });

  group('fromRecord', () {
    test('round-trips both fields', () {
      const settings = EstimationSettings(
        apiKey: 'sk-test',
        consentAccepted: true,
      );

      expect(
        EstimationSettingsMapper.fromRecord(
          EstimationSettingsMapper.toRecord(settings),
        ),
        settings,
      );
    });

    // A record written by an older build has no such key, and a missing
    // consent flag must fail CLOSED — reading it as accepted would send a
    // user's meal description to a third party on the strength of a key that
    // is absent from the record.
    test('a record with no consentAccepted key reads as false', () {
      final settings = EstimationSettingsMapper.fromRecord({
        'apiKey': 'sk-test',
      });

      expect(settings.consentAccepted, isFalse);
      expect(settings.isEnabled, isFalse);
    });

    test('a record with no apiKey key reads as no key', () {
      final settings = EstimationSettingsMapper.fromRecord({
        'consentAccepted': true,
      });

      expect(settings.apiKey, isNull);
      expect(settings.isEnabled, isFalse);
    });

    test('an empty record reads as defaults', () {
      expect(
        EstimationSettingsMapper.fromRecord(const {}),
        const EstimationSettings(),
      );
    });
  });

  test('the singleton key is fixed, so every write addresses one record', () {
    expect(EstimationSettingsMapper.singletonId, 0);
  });
}
