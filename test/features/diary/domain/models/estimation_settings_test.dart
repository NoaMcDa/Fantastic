import 'package:fantastic/features/diary/domain/models/estimation_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EstimationSettings.isEnabled', () {
    test('is true only with a key and accepted consent', () {
      const settings = EstimationSettings(
        apiKey: 'sk-test',
        consentAccepted: true,
      );

      expect(settings.isEnabled, isTrue);
    });

    // A user who has not been told what leaves their device.
    test('is false with a key but no consent', () {
      const settings = EstimationSettings(apiKey: 'sk-test');

      expect(settings.isEnabled, isFalse);
    });

    // Consent without a key cannot make a call.
    test('is false with consent but no key', () {
      const settings = EstimationSettings(consentAccepted: true);

      expect(settings.isEnabled, isFalse);
    });

    test('is false for an empty key, which is not a key', () {
      const settings = EstimationSettings(apiKey: '', consentAccepted: true);

      expect(settings.isEnabled, isFalse);
    });

    test('defaults are off', () {
      expect(const EstimationSettings().isEnabled, isFalse);
    });
  });

  group('EstimationSettings.copyWith', () {
    test('replaces what it is given', () {
      const settings = EstimationSettings(apiKey: 'first');

      final updated = settings.copyWith(
        apiKey: 'second',
        consentAccepted: true,
      );

      expect(updated.apiKey, 'second');
      expect(updated.consentAccepted, isTrue);
    });

    test('with no argument changes nothing', () {
      const settings = EstimationSettings(
        apiKey: 'sk-test',
        consentAccepted: true,
      );

      expect(settings.copyWith(), settings);
    });

    // The convention every model here follows, and the one
    // `design/m3_handoff.md` records the cost of breaking.
    test('null means unchanged, so it cannot clear the key', () {
      const settings = EstimationSettings(apiKey: 'sk-test');

      expect(settings.copyWith().apiKey, 'sk-test');
    });
  });

  group('EstimationSettings.withoutApiKey', () {
    test('clears the key', () {
      const settings = EstimationSettings(
        apiKey: 'sk-test',
        consentAccepted: true,
      );

      expect(settings.withoutApiKey().apiKey, isNull);
    });

    test('leaves consent untouched — it is a separate fact', () {
      const settings = EstimationSettings(
        apiKey: 'sk-test',
        consentAccepted: true,
      );

      expect(settings.withoutApiKey().consentAccepted, isTrue);
    });

    test('disables estimation, because a key is required', () {
      const settings = EstimationSettings(
        apiKey: 'sk-test',
        consentAccepted: true,
      );

      expect(settings.withoutApiKey().isEnabled, isFalse);
    });
  });

  group('EstimationSettings equality', () {
    test('is by value', () {
      expect(
        const EstimationSettings(apiKey: 'a', consentAccepted: true),
        const EstimationSettings(apiKey: 'a', consentAccepted: true),
      );
      expect(
        const EstimationSettings(apiKey: 'a').hashCode,
        const EstimationSettings(apiKey: 'a').hashCode,
      );
    });

    test('differs on either field', () {
      const base = EstimationSettings(apiKey: 'a');

      expect(base, isNot(const EstimationSettings(apiKey: 'b')));
      expect(
        base,
        isNot(const EstimationSettings(apiKey: 'a', consentAccepted: true)),
      );
    });
  });

  // Epic #312's invariant: no API key is logged, printed, or included in any
  // exception or failure value — and `toString` is how a key reaches a log
  // without anyone deciding to put it there.
  test('toString reports whether a key is set, never the key', () {
    const settings = EstimationSettings(
      apiKey: 'sk-super-secret',
      consentAccepted: true,
    );

    expect(settings.toString(), isNot(contains('sk-super-secret')));
    expect(settings.toString(), contains('set'));
    expect(const EstimationSettings().toString(), contains('none'));
  });
}
