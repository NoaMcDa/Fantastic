import 'package:fantastic/features/menu/domain/models/dish_verdict.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fixtures/fixtures.dart';

void main() {
  group('AnalysedDish', () {
    test('carries the name exactly as printed, separate from the verdict', () {
      final dish = AnalysedDishFixture.orderAsIs();

      expect(dish.name, 'סטייק אנטריקוט');
      expect(dish.verdict, DishVerdict.orderAsIs);
    });

    test('a modifiable dish carries a modification', () {
      final dish = AnalysedDishFixture.modifiable();

      expect(dish.verdict, DishVerdict.modifiable);
      expect(dish.modification, isNotNull);
      expect(dish.modification, isNotEmpty);
    });

    test('a non-modifiable dish need not carry a modification', () {
      expect(AnalysedDishFixture.orderAsIs().modification, isNull);
      expect(AnalysedDishFixture.nonKeto().modification, isNull);
    });

    test('description is optional', () {
      final dish = AnalysedDishFixture.orderAsIs(description: null);

      expect(dish.description, isNull);
    });
  });

  group('AnalysedDish.copyWith', () {
    test('replaces each field', () {
      final dish = AnalysedDishFixture.orderAsIs();

      final changed = dish.copyWith(
        name: 'שם אחר',
        verdict: DishVerdict.nonKeto,
        why: 'סיבה אחרת',
        description: 'תיאור אחר',
        modification: 'הנחיה אחרת',
      );

      expect(changed.name, 'שם אחר');
      expect(changed.verdict, DishVerdict.nonKeto);
      expect(changed.why, 'סיבה אחרת');
      expect(changed.description, 'תיאור אחר');
      expect(changed.modification, 'הנחיה אחרת');
    });

    test('with no argument preserves every field', () {
      final dish = AnalysedDishFixture.modifiable();

      expect(dish.copyWith(), dish);
    });

    test('clearDescription clears a description; a null argument does not', () {
      final dish = AnalysedDishFixture.orderAsIs();

      expect(dish.copyWith().description, dish.description);
      expect(dish.copyWith(clearDescription: true).description, isNull);
    });

    test(
      'clearModification clears a modification; a null argument does not',
      () {
        final dish = AnalysedDishFixture.modifiable();

        expect(dish.copyWith().modification, dish.modification);
        expect(dish.copyWith(clearModification: true).modification, isNull);
      },
    );
  });

  group('equality', () {
    test('is compared by value, not by identity', () {
      expect(AnalysedDishFixture.orderAsIs(), AnalysedDishFixture.orderAsIs());
      expect(
        AnalysedDishFixture.orderAsIs().hashCode,
        AnalysedDishFixture.orderAsIs().hashCode,
      );
    });

    test('differs when any single field differs', () {
      final base = AnalysedDishFixture.modifiable();

      expect(base, isNot(base.copyWith(name: 'אחר')));
      expect(base, isNot(base.copyWith(verdict: DishVerdict.nonKeto)));
      expect(base, isNot(base.copyWith(why: 'סיבה אחרת')));
      expect(base, isNot(base.copyWith(description: 'תיאור אחר')));
      // The rule the whole engine depends on: two dishes differing only in
      // the modification instruction must not read as the same dish.
      expect(base, isNot(base.copyWith(modification: 'הנחיה אחרת')));
    });
  });
}
