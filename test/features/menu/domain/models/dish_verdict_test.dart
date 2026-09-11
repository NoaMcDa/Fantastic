import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DishVerdict', () {
    test('has exactly three values', () {
      expect(DishVerdict.values, hasLength(3));
    });

    test('displayOrder holds every value exactly once', () {
      // So adding a fourth value cannot be forgotten here.
      expect(DishVerdict.displayOrder.toSet(), DishVerdict.values.toSet());
      expect(DishVerdict.displayOrder, hasLength(DishVerdict.values.length));
    });

    test('displayOrder groups green, then yellow, then red', () {
      expect(DishVerdict.displayOrder, [
        DishVerdict.orderAsIs,
        DishVerdict.modifiable,
        DishVerdict.nonKeto,
      ]);
    });
  });
}
