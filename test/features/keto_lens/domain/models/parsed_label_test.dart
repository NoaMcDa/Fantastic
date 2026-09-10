import 'package:fantastic/features/keto_lens/domain/models/parsed_label.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParsedLabel.hasMacros', () {
    test('is false when no macro was extracted', () {
      expect(const ParsedLabel().hasMacros, isFalse);
    });

    test('is true when fat alone is present', () {
      expect(const ParsedLabel(fatG: 10).hasMacros, isTrue);
    });

    test('is true when net carbs alone is present', () {
      expect(const ParsedLabel(netCarbsG: 3).hasMacros, isTrue);
    });

    test('is true when protein alone is present', () {
      expect(const ParsedLabel(proteinG: 8).hasMacros, isTrue);
    });

    test('is true when every macro is present', () {
      expect(
        const ParsedLabel(fatG: 10, netCarbsG: 3, proteinG: 8).hasMacros,
        isTrue,
      );
    });

    test('is true for a macro of zero — zero is found, not missing', () {
      expect(const ParsedLabel(fatG: 0).hasMacros, isTrue);
    });
  });

  group('ParsedLabel defaults', () {
    test('macros default to null, meaning not found', () {
      const label = ParsedLabel();

      expect(label.fatG, isNull);
      expect(label.netCarbsG, isNull);
      expect(label.proteinG, isNull);
    });

    test('ingredients defaults to an empty list and rawText to empty', () {
      expect(const ParsedLabel().ingredients, isEmpty);
      expect(const ParsedLabel().rawText, isEmpty);
    });
  });

  group('ParsedLabel equality', () {
    test('two instances with identical field values are equal', () {
      expect(const ParsedLabel(fatG: 10), const ParsedLabel(fatG: 10));
      expect(
        const ParsedLabel(fatG: 10).hashCode,
        const ParsedLabel(fatG: 10).hashCode,
      );
    });

    test('equal-but-not-identical ingredient lists are still equal', () {
      // Built as runtime locals rather than const literals: const would
      // canonicalise the two lists into one object and defeat the test.
      final first = <String>['olive oil', 'salt'];
      final second = <String>['olive oil', 'salt'];
      final a = ParsedLabel(ingredients: first);
      final b = ParsedLabel(ingredients: second);

      expect(identical(a.ingredients, b.ingredients), isFalse);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('two instances differing only in ingredients are not equal', () {
      expect(
        const ParsedLabel(ingredients: ['butter']),
        isNot(const ParsedLabel(ingredients: ['canola'])),
      );
    });

    test('two instances differing only in rawText are not equal', () {
      expect(
        const ParsedLabel(rawText: 'a'),
        isNot(const ParsedLabel(rawText: 'b')),
      );
    });
  });
}
