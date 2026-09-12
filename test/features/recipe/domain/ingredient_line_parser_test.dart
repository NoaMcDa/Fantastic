import 'package:fantastic/features/recipe/domain/ingredient_line_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IngredientLineParser.parse', () {
    test('2 כוסות קמח yields 2, כוסות, קמח', () {
      final result = IngredientLineParser.parse('2 כוסות קמח');
      expect(result.quantity, 2.0);
      expect(result.unit, 'כוסות');
      expect(result.name, 'קמח');
      expect(result.raw, '2 כוסות קמח');
    });

    test('קמח - 2 כוסות yields the same', () {
      final result = IngredientLineParser.parse('קמח - 2 כוסות');
      expect(result.quantity, 2.0);
      expect(result.unit, 'כוסות');
      expect(result.name, 'קמח');
    });

    test('קמח: 2 כוסות yields the same, with a colon separator', () {
      final result = IngredientLineParser.parse('קמח: 2 כוסות');
      expect(result.quantity, 2.0);
      expect(result.unit, 'כוסות');
      expect(result.name, 'קמח');
    });

    test('1/2, ½, 1½ and חצי all yield 0.5 or 1.5', () {
      expect(IngredientLineParser.parse('1/2').quantity, 0.5);
      expect(IngredientLineParser.parse('½').quantity, 0.5);
      expect(IngredientLineParser.parse('1½').quantity, 1.5);
      expect(IngredientLineParser.parse('חצי').quantity, 0.5);
    });

    test('a space-separated mixed number: 1 1/2 יין yields 1.5', () {
      final result = IngredientLineParser.parse('1 1/2 כוס יין');
      expect(result.quantity, 1.5);
      expect(result.unit, 'כוס');
      expect(result.name, 'יין');
    });

    test('כוס וחצי yields 1.5 כוס', () {
      final result = IngredientLineParser.parse('כוס וחצי קמח');
      expect(result.quantity, 1.5);
      expect(result.unit, 'כוס');
      expect(result.name, 'קמח');
    });

    test(
      '2 וחצי continues a numeric quantity with a trailing fraction word',
      () {
        final result = IngredientLineParser.parse('2 וחצי כוסות קמח');
        expect(result.quantity, 2.5);
        expect(result.unit, 'כוסות');
        expect(result.name, 'קמח');
      },
    );

    test('שלושת רבעי כוס סוכר parses the two-word three-quarters fraction', () {
      final result = IngredientLineParser.parse('שלושת רבעי כוס סוכר');
      expect(result.quantity, 0.75);
      expect(result.unit, 'כוס');
      expect(result.name, 'סוכר');
    });

    test('a bracketed note is dropped from the name', () {
      final result = IngredientLineParser.parse('קמח (מנופה)');
      expect(result.name, 'קמח');
      expect(result.quantity, isNull);
      expect(result.raw, 'קמח (מנופה)');
    });

    test('a line with no quantity', () {
      final result = IngredientLineParser.parse('מלח');
      expect(result.name, 'מלח');
      expect(result.quantity, isNull);
      expect(result.unit, isNull);
    });

    test('an unparseable line is the whole string, no throw', () {
      expect(() => IngredientLineParser.parse('!!!'), returnsNormally);
      final result = IngredientLineParser.parse('!!!');
      expect(result.name, '!!!');
      expect(result.quantity, isNull);
    });

    test('empty and whitespace-only do not throw', () {
      expect(() => IngredientLineParser.parse(''), returnsNormally);
      expect(IngredientLineParser.parse('').name, '');
      expect(() => IngredientLineParser.parse('   '), returnsNormally);
      expect(IngredientLineParser.parse('   ').name, '');
      expect(IngredientLineParser.parse('   ').quantity, isNull);
    });

    test('a separator with no valid trailing quantity falls back to the whole line', () {
      final result = IngredientLineParser.parse('שום - כתוש');
      expect(result.name, 'שום - כתוש');
      expect(result.quantity, isNull);
    });

    test('an English unit and quantity parse the same way', () {
      final result = IngredientLineParser.parse('2 cups flour');
      expect(result.quantity, 2.0);
      expect(result.unit, 'cups');
      expect(result.name, 'flour');
    });

    test('a decimal quantity parses', () {
      final result = IngredientLineParser.parse('12.5 גרם מלח');
      expect(result.quantity, 12.5);
      expect(result.unit, 'גרם');
      expect(result.name, 'מלח');
    });
  });
}
