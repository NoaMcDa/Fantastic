import 'package:fantastic/core/utils/numeric_input.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GramsText.format', () {
    test(
      'null is empty, so the validator asks rather than defaulting to 0',
      () {
        expect(GramsText.format(null), '');
      },
    );

    test('a whole figure drops the pointless .0', () {
      expect(GramsText.format(12), '12');
      expect(GramsText.format(0), '0');
    });

    test('one decimal is kept', () {
      expect(GramsText.format(12.5), '12.5');
    });

    // The reported defect: the scan sheet displayed 0.2 and the prefill wrote
    // 0.17999999999999988 into the field, so the number the user saw when they
    // pressed save was not the number that got saved (#304).
    test('floating-point noise is rounded to what the sheet displayed', () {
      expect(GramsText.format(0.17999999999999988), '0.2');
      expect(GramsText.format(0.30000000000000004), '0.3');
      expect(GramsText.format(41.199999999999996), '41.2');
    });

    test('noise that rounds to a whole number loses the decimal too', () {
      expect(GramsText.format(11.999999999999998), '12');
    });

    test('a second decimal is rounded away, not truncated', () {
      expect(GramsText.format(12.34), '12.3');
      expect(GramsText.format(12.36), '12.4');
    });

    // `'$value'` switched to exponent notation for large doubles, which is
    // what the old `< 1e9` and `< 1000` guards were working around.
    test('a large figure is plain digits, never exponent notation', () {
      final text = GramsText.format(1234567890);
      expect(text, '1234567890');
      expect(text, isNot(contains('e')));
    });

    test('a negative figure keeps its sign', () {
      expect(GramsText.format(-0.17999999999999988), '-0.2');
    });

    // The round trip the whole issue is about: whatever this formats has to be
    // something the form's own parser accepts back.
    test('what it formats, NumericInput parses back', () {
      for (final value in [
        12.0,
        12.5,
        0.17999999999999988,
        41.199999999999996,
      ]) {
        final text = GramsText.format(value);
        expect(NumericInput.positiveFinite(text), isNotNull, reason: text);
        expect(NumericInput.positiveFinite(text), double.parse(text));
      }
    });
  });
}
