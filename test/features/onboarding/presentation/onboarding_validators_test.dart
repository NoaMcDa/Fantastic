import 'package:fantastic/features/onboarding/presentation/onboarding_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('positiveFinite', () {
    test('parses a plain number', () {
      expect(OnboardingValidators.positiveFinite('78.5'), 78.5);
    });

    test('tolerates surrounding whitespace', () {
      expect(OnboardingValidators.positiveFinite('  78.5 '), 78.5);
    });

    // The whole reason this helper exists. `double.tryParse` returns a value
    // for both of these, and neither is `< 0`, so a `?? fallback` never
    // fires and the poison reaches the dashboard.
    test('rejects Infinity and NaN', () {
      expect(OnboardingValidators.positiveFinite('Infinity'), isNull);
      expect(OnboardingValidators.positiveFinite('-Infinity'), isNull);
      expect(OnboardingValidators.positiveFinite('NaN'), isNull);
    });

    test('rejects zero, negatives, empty and nonsense', () {
      expect(OnboardingValidators.positiveFinite('0'), isNull);
      expect(OnboardingValidators.positiveFinite('-5'), isNull);
      expect(OnboardingValidators.positiveFinite(''), isNull);
      expect(OnboardingValidators.positiveFinite(null), isNull);
      expect(OnboardingValidators.positiveFinite('abc'), isNull);
    });
  });

  group('age', () {
    test('accepts a value inside the range', () {
      expect(OnboardingValidators.age('34'), isNull);
    });

    test('accepts both bounds', () {
      expect(
        OnboardingValidators.age('${OnboardingValidators.minAge}'),
        isNull,
      );
      expect(
        OnboardingValidators.age('${OnboardingValidators.maxAge}'),
        isNull,
      );
    });

    test('rejects an empty field', () {
      expect(OnboardingValidators.age(''), isNotNull);
      expect(OnboardingValidators.age(null), isNotNull);
    });

    test('rejects a value below the minimum', () {
      expect(OnboardingValidators.age('5'), isNotNull);
    });

    test('rejects a value above the maximum', () {
      expect(OnboardingValidators.age('121'), isNotNull);
    });

    test('rejects a decimal and a negative', () {
      expect(OnboardingValidators.age('34.5'), isNotNull);
      expect(OnboardingValidators.age('-34'), isNotNull);
    });
  });

  group('weightKg', () {
    test('accepts a realistic weight', () {
      expect(OnboardingValidators.weightKg('78.5'), isNull);
    });

    test('rejects zero, negatives and an empty field', () {
      expect(OnboardingValidators.weightKg('0'), isNotNull);
      expect(OnboardingValidators.weightKg('-5'), isNotNull);
      expect(OnboardingValidators.weightKg(''), isNotNull);
    });

    test('rejects Infinity', () {
      expect(OnboardingValidators.weightKg('Infinity'), isNotNull);
    });

    // A misplaced decimal point, or kilograms that are really pounds.
    test('rejects an implausible weight at either end', () {
      expect(OnboardingValidators.weightKg('3'), isNotNull);
      expect(OnboardingValidators.weightKg('785'), isNotNull);
    });
  });

  group('heightCm', () {
    test('accepts a realistic height', () {
      expect(OnboardingValidators.heightCm('176'), isNull);
    });

    // 1.76 metres typed as metres, not centimetres — the most likely slip.
    test('rejects a height entered in metres', () {
      expect(OnboardingValidators.heightCm('1.76'), isNotNull);
    });

    test('rejects an implausible height and an empty field', () {
      expect(OnboardingValidators.heightCm('300'), isNotNull);
      expect(OnboardingValidators.heightCm(''), isNotNull);
    });
  });

  group('macroTargetG', () {
    test('accepts any positive finite number, with no upper bound', () {
      expect(OnboardingValidators.macroTargetG('150'), isNull);
      expect(OnboardingValidators.macroTargetG('9999'), isNull);
    });

    test('rejects zero, negatives, Infinity, NaN and an empty field', () {
      expect(OnboardingValidators.macroTargetG('0'), isNotNull);
      expect(OnboardingValidators.macroTargetG('-1'), isNotNull);
      expect(OnboardingValidators.macroTargetG('Infinity'), isNotNull);
      expect(OnboardingValidators.macroTargetG('NaN'), isNotNull);
      expect(OnboardingValidators.macroTargetG(''), isNotNull);
    });
  });
}
