import 'package:fantastic/features/onboarding/domain/mifflin_st_jeor.dart';
import 'package:fantastic/features/onboarding/domain/models/biological_sex.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('bmr', () {
    // 10*80 + 6.25*180 - 5*40 = 1725, then +5 for male.
    test('male gets the +5 constant', () {
      expect(
        MifflinStJeor.bmr(
          sex: BiologicalSex.male,
          age: 40,
          weightKg: 80,
          heightCm: 180,
        ),
        1730,
      );
    });

    test('female gets the -161 constant, not the +5 one', () {
      expect(
        MifflinStJeor.bmr(
          sex: BiologicalSex.female,
          age: 40,
          weightKg: 80,
          heightCm: 180,
        ),
        1564,
      );
    });

    test('the two sexes differ by exactly 166', () {
      double at(BiologicalSex sex) =>
          MifflinStJeor.bmr(sex: sex, age: 34, weightKg: 78.5, heightCm: 176);

      expect(at(BiologicalSex.male) - at(BiologicalSex.female), 166);
    });

    test('rises with weight and height, falls with age', () {
      double at({int age = 40, double weightKg = 80, double heightCm = 180}) =>
          MifflinStJeor.bmr(
            sex: BiologicalSex.male,
            age: age,
            weightKg: weightKg,
            heightCm: heightCm,
          );

      expect(at(weightKg: 90), greaterThan(at()));
      expect(at(heightCm: 190), greaterThan(at()));
      expect(at(age: 50), lessThan(at()));
    });

    test('is pure — the same inputs give the same answer', () {
      double call() => MifflinStJeor.bmr(
        sex: BiologicalSex.female,
        age: 29,
        weightKg: 61.4,
        heightCm: 165,
      );

      expect(call(), call());
    });
  });
}
