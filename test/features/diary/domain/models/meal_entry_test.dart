import 'package:fantastic/features/diary/domain/models/macro_source.dart';
import 'package:fantastic/features/diary/domain/models/meal_entry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Fixed so every case is deterministic — never DateTime.now().
final _timestamp = DateTime(2026, 9, 9, 12);

MealEntry _entry({
  int? id,
  double fatG = 20,
  double netCarbsG = 5,
  double proteinG = 15,
  String mealName = 'Test Meal',
  List<String> ingredients = const [],
  String? imageRef,
  MacroSource source = MacroSource.manual,
}) => MealEntry(
  id: id,
  timestamp: _timestamp,
  fatG: fatG,
  netCarbsG: netCarbsG,
  proteinG: proteinG,
  mealName: mealName,
  ingredients: ingredients,
  imageRef: imageRef,
  source: source,
);

void main() {
  group('MealEntry.ketoRatio', () {
    test('returns fat / (netCarbs + protein) for standard values', () {
      // 20 / (5 + 15) == 1.0
      expect(_entry().ketoRatio, closeTo(1.0, 0.0001));
    });

    test('returns a ratio above 1 when fat dominates', () {
      expect(
        _entry(fatG: 100, netCarbsG: 5, proteinG: 20).ketoRatio,
        closeTo(4.0, 0.0001),
      );
    });

    test('returns 0 when netCarbsG + proteinG is 0', () {
      expect(_entry(netCarbsG: 0, proteinG: 0).ketoRatio, 0);
    });

    test('returns 0 when fat is 0 but the denominator is not', () {
      expect(_entry(fatG: 0).ketoRatio, 0);
    });
  });

  group('MealEntry.copyWith', () {
    test('returns a new instance, not the same reference', () {
      final original = _entry();
      final copy = original.copyWith(fatG: 50);

      expect(identical(original, copy), isFalse);
      expect(copy.fatG, 50);
    });

    test('leaves untouched fields unchanged', () {
      final copy = _entry(mealName: 'Original').copyWith(fatG: 50);

      expect(copy.mealName, 'Original');
      expect(copy.netCarbsG, 5);
      expect(copy.proteinG, 15);
      expect(copy.timestamp, _timestamp);
    });

    test('with no arguments returns an equal instance', () {
      final original = _entry(ingredients: const ['butter']);

      expect(original.copyWith(), original);
    });

    test('overrides every field', () {
      final other = DateTime(2030);
      final copy = _entry().copyWith(
        id: 7,
        timestamp: other,
        fatG: 1,
        netCarbsG: 2,
        proteinG: 3,
        mealName: 'Changed',
        ingredients: const ['ghee'],
        imageRef: 'img.png',
      );

      expect(copy.id, 7);
      expect(copy.timestamp, other);
      expect(copy.fatG, 1);
      expect(copy.netCarbsG, 2);
      expect(copy.proteinG, 3);
      expect(copy.mealName, 'Changed');
      expect(copy.ingredients, const ['ghee']);
      expect(copy.imageRef, 'img.png');
    });
  });

  group('MealEntry equality', () {
    test('two instances with identical field values are equal', () {
      expect(_entry(), _entry());
      expect(_entry().hashCode, _entry().hashCode);
    });

    test('equal-but-not-identical ingredient lists are still equal', () {
      final a = _entry(ingredients: ['olive oil', 'butter']);
      final b = _entry(ingredients: ['olive oil', 'butter']);

      expect(identical(a.ingredients, b.ingredients), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('two instances differing only in ingredients are not equal', () {
      expect(
        _entry(ingredients: const ['butter']),
        isNot(_entry(ingredients: const ['canola'])),
      );
    });

    test('ingredient order is significant', () {
      expect(
        _entry(ingredients: const ['a', 'b']),
        isNot(_entry(ingredients: const ['b', 'a'])),
      );
    });

    test('two instances differing only in id are not equal', () {
      expect(_entry(id: 1), isNot(_entry(id: 2)));
    });

    test('two instances differing only in imageRef are not equal', () {
      expect(_entry(imageRef: 'a.png'), isNot(_entry()));
    });
  });

  group('MealEntry defaults', () {
    test('id and imageRef default to null before persistence', () {
      expect(_entry().id, isNull);
      expect(_entry().imageRef, isNull);
    });

    test('ingredients defaults to an empty list, never null', () {
      expect(_entry().ingredients, isEmpty);
    });
  });

  group('MealEntry.source', () {
    test(
      'defaults to manual, so every existing call site keeps its meaning',
      () {
        expect(_entry().source, MacroSource.manual);
      },
    );

    test('copyWith replaces it', () {
      final entry = _entry();

      expect(
        entry.copyWith(source: MacroSource.estimatedFromPhoto).source,
        MacroSource.estimatedFromPhoto,
      );
    });

    test('copyWith with no argument preserves it', () {
      final entry = _entry(source: MacroSource.estimatedFromText);

      expect(entry.copyWith().source, MacroSource.estimatedFromText);
    });

    test('two entries differing only in source are not equal', () {
      final typed = _entry();
      final guessed = typed.copyWith(source: MacroSource.estimatedFromText);

      expect(typed, isNot(guessed));
      expect(typed.hashCode, isNot(guessed.hashCode));
    });
  });
}
