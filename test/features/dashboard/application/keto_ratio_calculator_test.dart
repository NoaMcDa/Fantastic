import 'package:fantastic/features/dashboard/application/keto_ratio_calculator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = KetoRatioCalculator();

  group('calculate', () {
    test('divides fat by net carbs plus protein', () {
      expect(
        calculator.calculate(fat: 100, netCarbs: 5, protein: 20),
        closeTo(4, 0.01),
      );
    });

    test('returns 0 when fat is 0', () {
      expect(calculator.calculate(fat: 0, netCarbs: 10, protein: 20), 0);
    });

    // Division by zero would give infinity or NaN, either of which would reach
    // a progress bar and render as an overflow or a blank.
    test('returns 0 when the denominator is 0', () {
      expect(calculator.calculate(fat: 50, netCarbs: 0, protein: 0), 0);
    });

    test('returns 0 when everything is 0', () {
      expect(calculator.calculate(fat: 0, netCarbs: 0, protein: 0), 0);
    });

    test('never returns infinity for a nonzero fat and empty denominator', () {
      final ratio = calculator.calculate(fat: 200, netCarbs: 0, protein: 0);

      expect(ratio.isFinite, isTrue);
      expect(ratio.isNaN, isFalse);
    });

    test('counts net carbs and protein equally in the denominator', () {
      expect(
        calculator.calculate(fat: 60, netCarbs: 20, protein: 10),
        calculator.calculate(fat: 60, netCarbs: 10, protein: 20),
      );
    });

    test('matches MealEntry.ketoRatio for the same macros', () {
      // The two must agree — the dashboard totals and a single meal card would
      // otherwise compute the headline metric differently.
      expect(
        calculator.calculate(fat: 20, netCarbs: 5, protein: 15),
        closeTo(1, 0.0001),
      );
    });
  });

  group('calculate rejects negative input', () {
    test('throws on negative fat', () {
      expect(
        () => calculator.calculate(fat: -1, netCarbs: 5, protein: 10),
        throwsArgumentError,
      );
    });

    test('throws on negative net carbs', () {
      expect(
        () => calculator.calculate(fat: 10, netCarbs: -1, protein: 5),
        throwsArgumentError,
      );
    });

    test('throws on negative protein', () {
      expect(
        () => calculator.calculate(fat: 10, netCarbs: 5, protein: -1),
        throwsArgumentError,
      );
    });

    test('the message names the offending values', () {
      expect(
        () => calculator.calculate(fat: -1, netCarbs: 5, protein: 10),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString(),
            'message',
            contains('fat: -1'),
          ),
        ),
      );
    });

    // A negative denominator that happens to sum positive must still be
    // rejected: -5 + 25 is 20, so a sum-only check would let it through.
    test('throws even when the negative value is masked by the sum', () {
      expect(
        () => calculator.calculate(fat: 10, netCarbs: -5, protein: 25),
        throwsArgumentError,
      );
    });
  });

  group('ketoRatioCalculatorProvider', () {
    test('resolves to a KetoRatioCalculator', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(ketoRatioCalculatorProvider),
        isA<KetoRatioCalculator>(),
      );
    });

    test('is a const singleton — two reads give the same instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(ketoRatioCalculatorProvider),
        same(container.read(ketoRatioCalculatorProvider)),
      );
    });
  });
}
