import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  group('EstimatedItem', () {
    test('carries the weight separately from the macros', () {
      final item = MealEstimateFixture.item();

      // The review surface shows both, because a user who disagrees with an
      // estimate almost always disagrees with the weight.
      expect(item.grams, 50);
      expect(item.fatG, 5);
    });

    test('copyWith replaces only what it is given', () {
      final item = MealEstimateFixture.item();

      final heavier = item.copyWith(grams: 120);

      expect(heavier.grams, 120);
      expect(heavier.name, item.name);
      expect(heavier.fatG, item.fatG);
      expect(heavier.netCarbsG, item.netCarbsG);
      expect(heavier.proteinG, item.proteinG);
    });

    test('copyWith with no argument changes nothing', () {
      final item = MealEstimateFixture.item();

      expect(item.copyWith(), item);
    });

    test('is compared by value, not by identity', () {
      expect(MealEstimateFixture.item(), MealEstimateFixture.item());
      expect(
        MealEstimateFixture.item().hashCode,
        MealEstimateFixture.item().hashCode,
      );
    });

    test('differs when any single field differs', () {
      final base = MealEstimateFixture.item();

      expect(base, isNot(base.copyWith(name: 'אחר')));
      expect(base, isNot(base.copyWith(grams: 51)));
      expect(base, isNot(base.copyWith(fatG: 6)));
      expect(base, isNot(base.copyWith(netCarbsG: 2)));
      expect(base, isNot(base.copyWith(proteinG: 7)));
    });
  });
}
